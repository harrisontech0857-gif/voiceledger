import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

interface ParseRequest {
  text: string
  locale?: string
}

interface ParsedTransaction {
  amount: number
  type: "expense" | "income"
  category: string
  description: string
  currency: string
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  try {
    // 驗證使用者
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

    const { text, locale = "zh_TW" } = await req.json() as ParseRequest

    if (!text || text.trim().length === 0) {
      return new Response(
        JSON.stringify({ error: "請提供文字內容" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    // AI 解析邏輯
    const parsed = parseTransaction(text, locale)

    return new Response(
      JSON.stringify({ success: true, data: parsed }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  }
})

/**
 * 解析語音/文字輸入為結構化交易資料
 * 支援中文和英文
 */
function parseTransaction(text: string, locale: string): ParsedTransaction {
  const lower = text.toLowerCase()

  // 解析金額
  const amountMatch = text.match(/(\d+(?:\.\d+)?)\s*(?:元|塊|TWD|NTD|NT\$|\$|块)?/i)
  const amount = amountMatch ? parseFloat(amountMatch[1]) : 0

  // 判斷收入或支出
  const incomeKeywords = ["收入", "薪水", "獎金", "退款", "收到", "入帳", "income", "salary", "bonus", "refund"]
  const isIncome = incomeKeywords.some(k => lower.includes(k))

  // 分類偵測
  const category = detectCategory(lower)

  // 描述：去掉金額部分
  const description = text.replace(/(\d+(?:\.\d+)?)\s*(?:元|塊|TWD|NTD|NT\$|\$|块)?/gi, "").trim() || text

  return {
    amount,
    type: isIncome ? "income" : "expense",
    category,
    description,
    currency: "TWD",
  }
}

function detectCategory(text: string): string {
  const categoryMap: Record<string, string[]> = {
    food: ["吃", "飯", "餐", "食", "咖啡", "奶茶", "便當", "早餐", "午餐", "晚餐", "宵夜", "小吃", "餐廳", "外賣", "drink", "eat", "lunch", "dinner", "breakfast", "coffee"],
    transport: ["車", "捷運", "公車", "計程車", "油", "停車", "高鐵", "台鐵", "uber", "taxi", "bus", "mrt", "gas"],
    shopping: ["買", "購", "網購", "衣服", "鞋", "包", "淘寶", "蝦皮", "amazon", "shop", "buy"],
    entertainment: ["電影", "遊戲", "唱歌", "KTV", "旅遊", "門票", "Netflix", "movie", "game", "travel"],
    medical: ["醫", "藥", "看診", "掛號", "health", "medicine", "doctor", "hospital"],
    education: ["書", "課", "學費", "補習", "培訓", "book", "course", "tuition"],
    housing: ["房租", "水電", "瓦斯", "網路費", "管理費", "rent", "utility", "electric", "water"],
    salary: ["薪水", "薪資", "工資", "salary", "wage", "pay"],
    investment: ["投資", "股票", "基金", "利息", "invest", "stock", "dividend"],
  }

  for (const [cat, keywords] of Object.entries(categoryMap)) {
    if (keywords.some(k => text.includes(k))) {
      return cat
    }
  }

  return "other"
}
