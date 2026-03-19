import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
}

interface ChatRequest {
  message: string
  conversationHistory?: { role: string; content: string }[]
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get("Authorization")
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "缺少授權標頭" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")
    if (!supabaseUrl || !supabaseAnonKey) {
      return new Response(
        JSON.stringify({ error: "伺服器設定錯誤" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    })

    const { data: { user }, error: authError } = await supabase.auth.getUser()
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "未授權" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    const body = await req.json() as ChatRequest
    if (!body.message || typeof body.message !== "string") {
      return new Response(
        JSON.stringify({ error: "缺少 message 欄位" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    const message = body.message.trim().slice(0, 500) // 限制輸入長度

    // 取得使用者最近交易（使用正確的欄位名 transaction_type）
    const { data: recentTransactions, error: txError } = await supabase
      .from("transactions")
      .select("amount, transaction_type, category, description, created_at")
      .eq("user_id", user.id)
      .order("created_at", { ascending: false })
      .limit(20)

    if (txError) {
      console.error("取得交易資料失敗:", txError.message)
    }

    // 計算本月摘要
    const now = new Date()
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1).toISOString()
    const { data: monthlyData, error: monthError } = await supabase
      .from("transactions")
      .select("amount, transaction_type")
      .eq("user_id", user.id)
      .gte("created_at", monthStart)

    if (monthError) {
      console.error("取得月度資料失敗:", monthError.message)
    }

    let monthIncome = 0
    let monthExpense = 0
    if (monthlyData) {
      for (const t of monthlyData) {
        if (t.transaction_type === "income") monthIncome += t.amount
        else monthExpense += t.amount
      }
    }

    const response = generateSmartReply(message, {
      recentTransactions: recentTransactions || [],
      monthIncome,
      monthExpense,
      balance: monthIncome - monthExpense,
    })

    return new Response(
      JSON.stringify({
        success: true,
        data: {
          reply: response,
          context: {
            monthIncome,
            monthExpense,
            balance: monthIncome - monthExpense,
            transactionCount: recentTransactions?.length ?? 0,
          },
        },
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "未知錯誤"
    console.error("ai-chat 錯誤:", message)
    return new Response(
      JSON.stringify({ error: message }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  }
})

interface FinancialContext {
  recentTransactions: Record<string, unknown>[]
  monthIncome: number
  monthExpense: number
  balance: number
}

function generateSmartReply(message: string, ctx: FinancialContext): string {
  const lower = message.toLowerCase()

  // 本月摘要
  if (lower.includes("本月") || lower.includes("這個月") || lower.includes("摘要")) {
    const balanceNote =
      ctx.balance >= 0 ? "收支平衡不錯！繼續保持 💪" : "支出超過收入，建議檢視非必要開支喔。"
    return `📊 本月財務摘要：\n• 收入：NT$${ctx.monthIncome.toLocaleString()}\n• 支出：NT$${ctx.monthExpense.toLocaleString()}\n• 淨額：NT$${ctx.balance.toLocaleString()}\n\n${balanceNote}`
  }

  // 省錢建議
  if (lower.includes("建議") || lower.includes("怎麼省") || lower.includes("省錢")) {
    const topCat = getTopCategory(ctx.recentTransactions)
    if (topCat) {
      return `💡 根據近期消費分析，「${topCat}」類別支出最高。\n\n建議：\n1. 設定每日預算目標\n2. 記錄每筆花費，提升意識\n3. 考慮替代方案或減少頻率\n\n要看更詳細的分析嗎？`
    }
    return "目前資料不足，建議持續記帳至少一週再回來看分析喔！"
  }

  // 最近花費
  if (lower.includes("最近") || lower.includes("花了什麼")) {
    const recent = ctx.recentTransactions.slice(0, 5)
    if (recent.length === 0) return "還沒有記錄呢，試著說一筆帳給我聽聽！🎙️"

    const lines = recent.map(
      (t: Record<string, unknown>) =>
        `• ${t.description || "未命名"} — NT$${(t.amount as number).toLocaleString()}`
    )
    return `📝 最近的交易：\n${lines.join("\n")}`
  }

  return `你好！我是你的 AI 財務秘書 🤖\n\n你可以問我：\n• 「本月摘要」— 查看收支\n• 「省錢建議」— 消費分析\n• 「最近花了什麼」— 近期交易\n\n或直接語音記帳也可以喔！`
}

function getTopCategory(transactions: Record<string, unknown>[]): string | null {
  const map: Record<string, number> = {}
  for (const t of transactions) {
    if (t.transaction_type === "expense" || t.type === "expense") {
      const cat = (t.category as string) || "other"
      map[cat] = (map[cat] || 0) + (t.amount as number)
    }
  }
  const sorted = Object.entries(map).sort((a, b) => b[1] - a[1])
  return sorted[0]?.[0] || null
}
