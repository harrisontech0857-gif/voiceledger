import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
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
    const authHeader = req.headers.get("Authorization")!
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } }
    )

    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      return new Response(
        JSON.stringify({ error: "未授權" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    const { message } = await req.json() as ChatRequest

    // 取得使用者最近交易
    const { data: recentTransactions } = await supabase
      .from("transactions")
      .select("amount, type, category, description, transaction_date")
      .eq("user_id", user.id)
      .order("transaction_date", { ascending: false })
      .limit(20)

    // 計算本月摘要
    const now = new Date()
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1).toISOString()
    const { data: monthlyData } = await supabase
      .from("transactions")
      .select("amount, type")
      .eq("user_id", user.id)
      .gte("transaction_date", monthStart)

    let monthIncome = 0
    let monthExpense = 0
    if (monthlyData) {
      for (const t of monthlyData) {
        if (t.type === "income") monthIncome += t.amount
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
      JSON.stringify({ success: true, data: { reply: response } }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  }
})

interface FinancialContext {
  recentTransactions: any[]
  monthIncome: number
  monthExpense: number
  balance: number
}

function generateSmartReply(message: string, ctx: FinancialContext): string {
  const lower = message.toLowerCase()

  if (lower.includes("本月") || lower.includes("這個月") || lower.includes("摘要")) {
    return `本月收入 NT$${ctx.monthIncome.toLocaleString()}，支出 NT$${ctx.monthExpense.toLocaleString()}，淨額 NT$${ctx.balance.toLocaleString()}。${ctx.balance >= 0 ? "收支平衡不錯！" : "支出超過收入，要注意控制開支喔。"}`
  }

  if (lower.includes("建議") || lower.includes("怎麼省")) {
    const topCat = getTopCategory(ctx.recentTransactions)
    return `根據你最近的消費，${topCat}類別的支出最高。建議可以設定每日預算，追蹤每筆花費。`
  }

  return `收到！我是你的 AI 財務秘書。你可以問我「本月摘要」、「省錢建議」，或直接說金額讓我幫你記帳。`
}

function getTopCategory(transactions: any[]): string {
  const map: Record<string, number> = {}
  for (const t of transactions) {
    if (t.type === "expense") {
      map[t.category] = (map[t.category] || 0) + t.amount
    }
  }
  const sorted = Object.entries(map).sort((a, b) => b[1] - a[1])
  return sorted[0]?.[0] || "其他"
}
