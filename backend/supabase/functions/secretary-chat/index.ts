import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
}

/**
 * Secretary Chat Edge Function
 *
 * 提供情境式 AI 財務秘書對話，
 * 結合使用者的財務資料、情緒狀態和上下文，
 * 給出個人化的溫暖回覆。
 *
 * 與 ai-chat 的差異：
 * - secretary-chat 更注重「陪伴感」和情感互動
 * - 支援多輪對話 history
 * - 可以處理非財務問題（鼓勵、提醒等）
 */

interface SecretaryChatRequest {
  message: string
  conversationHistory?: { role: "user" | "assistant"; content: string }[]
  mood?: string // 使用者設定的心情
  context?: string // 額外上下文 (e.g., "morning_greeting", "budget_alert")
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get("Authorization")
    if (!authHeader) {
      return jsonResponse({ error: "缺少授權標頭" }, 401)
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")
    if (!supabaseUrl || !serviceRoleKey) {
      return jsonResponse({ error: "伺服器設定錯誤" }, 500)
    }

    // 驗證使用者
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!
    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    })
    const {
      data: { user },
      error: authError,
    } = await userClient.auth.getUser()
    if (authError || !user) {
      return jsonResponse({ error: "未授權" }, 401)
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey)
    const body = (await req.json()) as SecretaryChatRequest

    if (!body.message || typeof body.message !== "string") {
      return jsonResponse({ error: "缺少 message 欄位" }, 400)
    }

    const message = body.message.trim().slice(0, 1000)
    const context = body.context || "general"
    const history = (body.conversationHistory || []).slice(-10) // 只保留最近 10 輪

    // 取得使用者財務上下文
    const financialContext = await getFinancialContext(supabase, user.id)

    // 偵測意圖
    const intent = detectIntent(message)

    // 生成回覆
    const reply = await generateReply(
      message,
      intent,
      context,
      financialContext,
      history
    )

    // 儲存對話記錄（可選）
    await saveChatLog(supabase, user.id, message, reply.text).catch((e) =>
      console.error("儲存對話失敗:", e)
    )

    return jsonResponse({
      success: true,
      data: {
        reply: reply.text,
        intent: reply.intent,
        suggestions: reply.suggestions,
        emotion: reply.emotion,
      },
    })
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "未知錯誤"
    console.error("secretary-chat 錯誤:", message)
    return jsonResponse({ error: message }, 500)
  }
})

// ─── 財務上下文 ────────────────────────────────────

interface FinancialContext {
  todayExpense: number
  todayIncome: number
  todayCount: number
  monthExpense: number
  monthIncome: number
  streak: number // 連續記帳天數（簡化計算）
  topCategory: string | null
  recentItems: string[]
}

async function getFinancialContext(
  supabase: ReturnType<typeof createClient>,
  userId: string
): Promise<FinancialContext> {
  const now = new Date()
  const todayStart = new Date(
    now.getFullYear(),
    now.getMonth(),
    now.getDate()
  ).toISOString()
  const monthStart = new Date(
    now.getFullYear(),
    now.getMonth(),
    1
  ).toISOString()

  // 今日交易
  const { data: todayTx } = await supabase
    .from("transactions")
    .select("amount, transaction_type, category, description")
    .eq("user_id", userId)
    .gte("created_at", todayStart)

  // 本月交易
  const { data: monthTx } = await supabase
    .from("transactions")
    .select("amount, transaction_type, category")
    .eq("user_id", userId)
    .gte("created_at", monthStart)

  let todayExpense = 0,
    todayIncome = 0
  const recentItems: string[] = []
  if (todayTx) {
    for (const tx of todayTx) {
      if (tx.transaction_type === "income") todayIncome += tx.amount
      else todayExpense += tx.amount
      if (tx.description) recentItems.push(tx.description)
    }
  }

  let monthExpense = 0,
    monthIncome = 0
  const catMap: Record<string, number> = {}
  if (monthTx) {
    for (const tx of monthTx) {
      if (tx.transaction_type === "income") monthIncome += tx.amount
      else {
        monthExpense += tx.amount
        const c = tx.category || "other"
        catMap[c] = (catMap[c] || 0) + tx.amount
      }
    }
  }

  const topCategory =
    Object.entries(catMap).sort((a, b) => b[1] - a[1])[0]?.[0] || null

  return {
    todayExpense,
    todayIncome,
    todayCount: todayTx?.length || 0,
    monthExpense,
    monthIncome,
    streak: 0, // TODO: 從 pet 表或另外計算
    topCategory,
    recentItems: recentItems.slice(0, 5),
  }
}

// ─── 意圖偵測 ────────────────────────────────────

type Intent =
  | "greeting"
  | "budget_query"
  | "encouragement"
  | "spending_query"
  | "saving_tips"
  | "diary_request"
  | "general"

function detectIntent(message: string): Intent {
  const m = message.toLowerCase()

  if (
    m.includes("早安") ||
    m.includes("你好") ||
    m.includes("嗨") ||
    m.includes("晚安")
  )
    return "greeting"
  if (m.includes("預算") || m.includes("還能花") || m.includes("額度"))
    return "budget_query"
  if (
    m.includes("壓力") ||
    m.includes("焦慮") ||
    m.includes("難過") ||
    m.includes("加油")
  )
    return "encouragement"
  if (
    m.includes("花了") ||
    m.includes("支出") ||
    m.includes("消費") ||
    m.includes("本月")
  )
    return "spending_query"
  if (m.includes("省錢") || m.includes("存錢") || m.includes("建議"))
    return "saving_tips"
  if (m.includes("日記") || m.includes("今天過得"))
    return "diary_request"

  return "general"
}

// ─── 回覆生成 ────────────────────────────────────

interface ReplyResult {
  text: string
  intent: Intent
  suggestions: string[]
  emotion: string
}

async function generateReply(
  message: string,
  intent: Intent,
  _context: string,
  fin: FinancialContext,
  _history: { role: string; content: string }[]
): Promise<ReplyResult> {
  const hour = new Date().getHours()
  const timeGreeting =
    hour < 12 ? "早安" : hour < 18 ? "午安" : "晚安"

  switch (intent) {
    case "greeting":
      return {
        text:
          `${timeGreeting}！🌟 我是你的財務小秘書。` +
          (fin.todayCount > 0
            ? `\n今天已記了 ${fin.todayCount} 筆，支出 NT$${fin.todayExpense.toLocaleString()}，很棒喔！`
            : `\n今天還沒有記帳呢，隨時說一筆給我聽！`) +
          `\n\n有什麼我能幫你的嗎？`,
        intent,
        suggestions: ["本月摘要", "省錢建議", "幫我記帳"],
        emotion: "warm",
      }

    case "budget_query":
      return {
        text: `本月支出目前是 NT$${fin.monthExpense.toLocaleString()}，收入 NT$${fin.monthIncome.toLocaleString()}。\n\n${fin.monthIncome > fin.monthExpense ? "目前收支健康，繼續保持！💪" : "支出稍微多了些，接下來幾天可以省著點喔～"}`,
        intent,
        suggestions: ["哪個類別花最多", "最近花了什麼", "省錢建議"],
        emotion: fin.monthIncome > fin.monthExpense ? "positive" : "concerned",
      }

    case "encouragement":
      return {
        text: `每個人都有壓力大的時候，你願意好好面對自己的財務，已經很了不起了 ✨\n\n記帳不是為了限制自己，而是為了更清楚地掌握生活。一步一步來，你做得很好！`,
        intent,
        suggestions: ["本月摘要", "幫我放鬆一下", "省錢建議"],
        emotion: "empathetic",
      }

    case "spending_query": {
      const topCatName = getCategoryName(fin.topCategory)
      return {
        text:
          `📊 財務快報：\n` +
          `• 本月支出：NT$${fin.monthExpense.toLocaleString()}\n` +
          `• 本月收入：NT$${fin.monthIncome.toLocaleString()}\n` +
          (topCatName
            ? `• 最大類別：${topCatName}\n`
            : "") +
          (fin.recentItems.length > 0
            ? `\n最近消費：${fin.recentItems.join("、")}`
            : ""),
        intent,
        suggestions: ["省錢建議", "看日記", "詳細分析"],
        emotion: "informative",
      }
    }

    case "saving_tips":
      return {
        text:
          `💡 個人化省錢建議：\n\n` +
          (fin.topCategory
            ? `1. 你在「${getCategoryName(fin.topCategory)}」花最多，可以想想有沒有替代方案\n`
            : "1. 持續記帳，找出最大支出類別\n") +
          `2. 每天設定一個小目標金額\n` +
          `3. 買東西前等 24 小時，避免衝動消費\n` +
          `4. 固定支出（訂閱）定期檢視是否還需要\n` +
          `\n堅持記帳就是最好的開始！加油！🌱`,
        intent,
        suggestions: ["本月摘要", "幫我記帳", "看日記"],
        emotion: "encouraging",
      }

    case "diary_request":
      return {
        text:
          fin.todayCount > 0
            ? `今天記了 ${fin.todayCount} 筆帳，支出 NT$${fin.todayExpense.toLocaleString()}。\n\n你覺得今天過得怎麼樣呢？如果想生成完整日記，可以到「日記」頁面看看喔！📔`
            : `今天還沒有記錄呢。先記幾筆帳，我再幫你寫日記吧！🖊️`,
        intent,
        suggestions: ["幫我記帳", "本月摘要", "早安"],
        emotion: "gentle",
      }

    default:
      return {
        text: `我聽到了！✨\n\n身為你的財務小秘書，我可以幫你：\n• 查看本月收支\n• 給省錢建議\n• 記錄消費\n• 寫生活日記\n\n你想做哪個呢？`,
        intent,
        suggestions: ["本月摘要", "省錢建議", "幫我記帳"],
        emotion: "helpful",
      }
  }
}

// ─── 工具函式 ────────────────────────────────────

function getCategoryName(category: string | null): string | null {
  if (!category) return null
  const names: Record<string, string> = {
    food: "餐飲",
    transport: "交通",
    entertainment: "娛樂",
    shopping: "購物",
    utilities: "日用",
    health: "健康",
    education: "教育",
    investment: "投資",
    salary: "薪資",
    other: "其他",
  }
  return names[category] || category
}

async function saveChatLog(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  userMessage: string,
  assistantReply: string
) {
  await supabase.from("chat_logs").insert({
    user_id: userId,
    user_message: userMessage.slice(0, 1000),
    assistant_reply: assistantReply.slice(0, 2000),
    source: "secretary-chat",
  })
}

function jsonResponse(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  })
}
