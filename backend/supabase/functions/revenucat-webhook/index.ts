import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
}

/**
 * RevenueCat Webhook Edge Function
 *
 * 處理 RevenueCat 訂閱事件：
 * - INITIAL_PURCHASE: 首次訂閱
 * - RENEWAL: 自動續訂
 * - CANCELLATION: 取消訂閱
 * - EXPIRATION: 訂閱到期
 * - BILLING_ISSUE: 付款問題
 * - PRODUCT_CHANGE: 方案變更
 *
 * 更新使用者的 premium 狀態到 user_profiles 表。
 */

interface RevenueCatEvent {
  api_version: string
  event: {
    type: string
    id: string
    app_user_id: string
    product_id: string
    entitlement_ids: string[]
    period_type: string // NORMAL, TRIAL, INTRO
    purchased_at_ms: number
    expiration_at_ms: number | null
    environment: string // PRODUCTION, SANDBOX
    store: string // APP_STORE, PLAY_STORE
    is_trial_conversion?: boolean
    cancel_reason?: string
    price_in_purchased_currency?: number
    currency?: string
  }
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "僅支援 POST" }, 405)
  }

  try {
    // 驗證 webhook 簽名
    const webhookSecret = Deno.env.get("REVENUECAT_WEBHOOK_SECRET")
    if (webhookSecret) {
      const signature = req.headers.get("X-RevenueCat-Signature")
      if (!signature) {
        console.warn("缺少 RevenueCat 簽名標頭")
        return jsonResponse({ error: "缺少簽名" }, 401)
      }
      // 注意：完整的 HMAC 驗證需要讀取 raw body
      // 這裡先做基本存在性檢查，生產環境應實作完整 HMAC-SHA256
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")
    if (!supabaseUrl || !serviceRoleKey) {
      return jsonResponse({ error: "伺服器設定錯誤" }, 500)
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey)
    const payload = (await req.json()) as RevenueCatEvent

    const event = payload.event
    if (!event || !event.type || !event.app_user_id) {
      return jsonResponse({ error: "無效的 webhook payload" }, 400)
    }

    console.log(
      `[RevenueCat] 事件: ${event.type} | 使用者: ${event.app_user_id} | 產品: ${event.product_id} | 環境: ${event.environment}`
    )

    // 記錄事件
    await logSubscriptionEvent(supabase, event)

    // 根據事件類型更新使用者狀態
    switch (event.type) {
      case "INITIAL_PURCHASE":
      case "RENEWAL":
      case "UNCANCELLATION":
        await activateSubscription(supabase, event)
        break

      case "CANCELLATION":
        await handleCancellation(supabase, event)
        break

      case "EXPIRATION":
        await deactivateSubscription(supabase, event)
        break

      case "BILLING_ISSUE":
        await handleBillingIssue(supabase, event)
        break

      case "PRODUCT_CHANGE":
        await handleProductChange(supabase, event)
        break

      case "SUBSCRIBER_ALIAS":
        // 使用者帳號合併，通常不需特別處理
        console.log(`[RevenueCat] Alias 事件: ${event.app_user_id}`)
        break

      default:
        console.log(`[RevenueCat] 未處理的事件類型: ${event.type}`)
    }

    return jsonResponse({ success: true, event_type: event.type })
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "未知錯誤"
    console.error("revenucat-webhook 錯誤:", message)
    return jsonResponse({ error: message }, 500)
  }
})

// ─── 訂閱操作 ────────────────────────────────────

async function activateSubscription(
  supabase: ReturnType<typeof createClient>,
  event: RevenueCatEvent["event"]
) {
  const expiresAt = event.expiration_at_ms
    ? new Date(event.expiration_at_ms).toISOString()
    : null

  const planType = mapProductToPlan(event.product_id)
  const isTrial = event.period_type === "TRIAL"

  const { error } = await supabase
    .from("user_profiles")
    .update({
      is_premium: true,
      subscription_plan: planType,
      subscription_status: isTrial ? "trialing" : "active",
      subscription_expires_at: expiresAt,
      subscription_store: event.store,
      updated_at: new Date().toISOString(),
    })
    .eq("id", event.app_user_id)

  if (error) {
    console.error(`啟用訂閱失敗 (${event.app_user_id}):`, error.message)
    // 嘗試用 auth.uid 查找
    await fallbackUpdateByAuthId(supabase, event.app_user_id, {
      is_premium: true,
      subscription_plan: planType,
      subscription_status: isTrial ? "trialing" : "active",
      subscription_expires_at: expiresAt,
    })
  }

  console.log(
    `[RevenueCat] ✅ 訂閱啟用: ${event.app_user_id} → ${planType}${isTrial ? " (試用)" : ""}`
  )
}

async function handleCancellation(
  supabase: ReturnType<typeof createClient>,
  event: RevenueCatEvent["event"]
) {
  // 取消不代表立即失效，到期前仍可使用
  const { error } = await supabase
    .from("user_profiles")
    .update({
      subscription_status: "cancelled",
      cancel_reason: event.cancel_reason || null,
      updated_at: new Date().toISOString(),
    })
    .eq("id", event.app_user_id)

  if (error) {
    console.error(`處理取消失敗 (${event.app_user_id}):`, error.message)
  }

  console.log(
    `[RevenueCat] ⚠️ 訂閱取消: ${event.app_user_id} | 原因: ${event.cancel_reason || "未知"}`
  )
}

async function deactivateSubscription(
  supabase: ReturnType<typeof createClient>,
  event: RevenueCatEvent["event"]
) {
  const { error } = await supabase
    .from("user_profiles")
    .update({
      is_premium: false,
      subscription_status: "expired",
      updated_at: new Date().toISOString(),
    })
    .eq("id", event.app_user_id)

  if (error) {
    console.error(`停用訂閱失敗 (${event.app_user_id}):`, error.message)
  }

  console.log(`[RevenueCat] ❌ 訂閱到期: ${event.app_user_id}`)
}

async function handleBillingIssue(
  supabase: ReturnType<typeof createClient>,
  event: RevenueCatEvent["event"]
) {
  const { error } = await supabase
    .from("user_profiles")
    .update({
      subscription_status: "billing_issue",
      updated_at: new Date().toISOString(),
    })
    .eq("id", event.app_user_id)

  if (error) {
    console.error(`處理帳單問題失敗 (${event.app_user_id}):`, error.message)
  }

  console.log(`[RevenueCat] 💳 帳單問題: ${event.app_user_id}`)

  // TODO: 發送推播通知提醒使用者更新付款方式
}

async function handleProductChange(
  supabase: ReturnType<typeof createClient>,
  event: RevenueCatEvent["event"]
) {
  const newPlan = mapProductToPlan(event.product_id)

  const { error } = await supabase
    .from("user_profiles")
    .update({
      subscription_plan: newPlan,
      subscription_status: "active",
      updated_at: new Date().toISOString(),
    })
    .eq("id", event.app_user_id)

  if (error) {
    console.error(`方案變更失敗 (${event.app_user_id}):`, error.message)
  }

  console.log(
    `[RevenueCat] 🔄 方案變更: ${event.app_user_id} → ${newPlan}`
  )
}

// ─── 工具函式 ────────────────────────────────────

function mapProductToPlan(productId: string): string {
  // 對應 RevenueCat 產品 ID 到方案名稱
  const planMap: Record<string, string> = {
    voiceledger_monthly: "monthly",
    voiceledger_yearly: "yearly",
    voiceledger_pro_monthly: "pro_monthly",
    voiceledger_pro_yearly: "pro_yearly",
    // iOS App Store
    "com.voiceledger.monthly": "monthly",
    "com.voiceledger.yearly": "yearly",
    // Google Play
    "voiceledger.monthly": "monthly",
    "voiceledger.yearly": "yearly",
  }
  return planMap[productId] || "unknown"
}

async function logSubscriptionEvent(
  supabase: ReturnType<typeof createClient>,
  event: RevenueCatEvent["event"]
) {
  const { error } = await supabase.from("subscription_events").insert({
    user_id: event.app_user_id,
    event_type: event.type,
    event_id: event.id,
    product_id: event.product_id,
    store: event.store,
    environment: event.environment,
    period_type: event.period_type,
    price: event.price_in_purchased_currency,
    currency: event.currency,
    purchased_at: event.purchased_at_ms
      ? new Date(event.purchased_at_ms).toISOString()
      : null,
    expires_at: event.expiration_at_ms
      ? new Date(event.expiration_at_ms).toISOString()
      : null,
    cancel_reason: event.cancel_reason || null,
  })

  if (error) {
    // 如果 subscription_events 表不存在也不要影響主流程
    console.warn("記錄訂閱事件失敗:", error.message)
  }
}

async function fallbackUpdateByAuthId(
  supabase: ReturnType<typeof createClient>,
  appUserId: string,
  updates: Record<string, unknown>
) {
  // RevenueCat 的 app_user_id 可能是 Supabase Auth UID
  const { error } = await supabase
    .from("user_profiles")
    .update({ ...updates, updated_at: new Date().toISOString() })
    .eq("auth_id", appUserId)

  if (error) {
    console.error(`Fallback 更新也失敗 (${appUserId}):`, error.message)
  }
}

function jsonResponse(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  })
}
