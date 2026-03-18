import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

// Gemini API 設定
const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY") || ""
const GEMINI_MODEL = "gemini-2.0-flash"
const GEMINI_URL = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`

// ============================================================
// 統一 AI 入口：action 決定功能
// ============================================================
// action: "parse" | "chat" | "quote" | "analyze"
// ============================================================

interface RequestBody {
  action: "parse" | "chat" | "quote" | "analyze"
  text?: string
  conversationHistory?: { role: string; content: string }[]
  transactions?: any[]
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
      return jsonResponse({ error: "未授權" }, 401)
    }

    if (!GEMINI_API_KEY) {
      return jsonResponse({ error: "Gemini API Key 未設定，請聯繫開發者" }, 500)
    }

    const body: RequestBody = await req.json()

    let result: any

    switch (body.action) {
      case "parse":
        result = await handleParse(body.text || "")
        break
      case "chat":
        result = await handleChat(body.text || "", body.conversationHistory || [])
        break
      case "quote":
        result = await handleQuote()
        break
      case "analyze":
        result = await handleAnalyze(body.text || "", body.transactions || [])
        break
      default:
        return jsonResponse({ error: `未知的 action: ${body.action}` }, 400)
    }

    return jsonResponse({ success: true, data: result })
  } catch (error) {
    console.error("gemini-ai error:", error)
    return jsonResponse({ error: error.message || "處理失敗" }, 500)
  }
})

// ============================================================
// 1. parse — 從自然對話中提取交易（核心功能）
// ============================================================
async function handleParse(text: string) {
  const prompt = `你是一個台灣記帳 App 的 AI 引擎。使用者會用口語描述他的花費，你要從中提取所有交易。

## 重要規則
1. 使用者可能一句話包含多筆交易，你必須全部提取
2. 使用者可能用很口語的方式描述，例如「今天中午吃便當花了85塊然後坐計程車回家250」
3. 金額可能用「塊」「元」「NT$」或直接講數字
4. 如果使用者沒有明確說金額，但有描述消費行為，設 amount 為 0 並標記 needs_review
5. 類別必須是以下之一：餐飲、交通、購物、娛樂、日用、健康、教育、投資、薪資、其他
6. 幣別預設 TWD

## 使用者說的話
「${text}」

## 回覆格式（只回 JSON，不要其他文字）
{
  "transactions": [
    {
      "amount": 數字,
      "category": "類別",
      "description": "簡短描述",
      "type": "expense 或 income",
      "confidence": 0到1的信心度,
      "needs_review": true或false
    }
  ],
  "summary": "用一句話描述所有交易",
  "feedback": "一句鼓勵或理財小提示（20字內）"
}`

  const response = await callGemini(prompt)

  // 解析 JSON
  try {
    const jsonStr = response
      .replace(/```json\n?/g, "")
      .replace(/```\n?/g, "")
      .trim()
    return JSON.parse(jsonStr)
  } catch {
    // 如果解析失敗，用 regex 嘗試
    const jsonMatch = response.match(/\{[\s\S]*\}/)
    if (jsonMatch) {
      try {
        return JSON.parse(jsonMatch[0])
      } catch {
        // 最後退路：返回原始文字讓 client 處理
        return {
          transactions: [{
            amount: 0,
            category: "其他",
            description: text,
            type: "expense",
            confidence: 0.3,
            needs_review: true,
          }],
          summary: text,
          feedback: "請確認交易內容",
        }
      }
    }
    return { transactions: [], summary: text, feedback: "無法解析" }
  }
}

// ============================================================
// 2. chat — AI 財務秘書對話
// ============================================================
async function handleChat(
  message: string,
  history: { role: string; content: string }[]
) {
  const systemPrompt = `你是「語記」App 的 AI 財務秘書，專門協助使用者記帳和理財。
規則：
- 用繁體中文回答，語氣友善親切
- 回覆簡潔，不超過 100 字
- 幣別預設新台幣 NT$
- 如果使用者提到花費，主動幫他分析
- 可以給理財建議，但要務實`

  // 組合對話歷史
  const contents: any[] = []

  // System instruction 放在第一個 user message
  if (history.length === 0) {
    contents.push({
      role: "user",
      parts: [{ text: systemPrompt + "\n\n使用者：" + message }],
    })
  } else {
    // 加入歷史
    for (const msg of history.slice(-10)) { // 只取最近 10 條
      contents.push({
        role: msg.role === "user" ? "user" : "model",
        parts: [{ text: msg.content }],
      })
    }
    contents.push({
      role: "user",
      parts: [{ text: message }],
    })
  }

  const reply = await callGeminiChat(contents)

  // 生成建議
  let suggestion = "試試問「這個月花了多少」"
  const lower = message.toLowerCase()
  if (lower.includes("支出") || lower.includes("花")) {
    suggestion = "查看本月統計報告"
  } else if (lower.includes("預算") || lower.includes("存錢")) {
    suggestion = "設定每月儲蓄目標"
  } else if (lower.includes("分析") || lower.includes("建議")) {
    suggestion = "讓我幫你分析消費習慣"
  }

  return { reply, suggestion }
}

// ============================================================
// 3. quote — 每日理財金句
// ============================================================
async function handleQuote() {
  const prompt = "請給我一句原創的理財勵志金句（繁體中文，20字以內），風格可以幽默、溫暖或睿智。不要加引號，只回金句本身。"
  const quote = await callGemini(prompt)
  return { quote: quote.trim() }
}

// ============================================================
// 4. analyze — 分析交易描述
// ============================================================
async function handleAnalyze(text: string, transactions: any[]) {
  const prompt = `使用者記了一筆帳：「${text}」
簡短回覆（30字內），確認你理解了這筆交易，並給一句鼓勵或理財小提示。`

  const response = await callGemini(prompt)
  return { response: response.trim() }
}

// ============================================================
// Gemini API 呼叫
// ============================================================
async function callGemini(prompt: string): Promise<string> {
  const res = await fetch(GEMINI_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: {
        temperature: 0.7,
        maxOutputTokens: 1024,
      },
    }),
  })

  if (!res.ok) {
    const err = await res.text()
    throw new Error(`Gemini API error: ${res.status} ${err}`)
  }

  const data = await res.json()
  return data.candidates?.[0]?.content?.parts?.[0]?.text || ""
}

async function callGeminiChat(contents: any[]): Promise<string> {
  const res = await fetch(GEMINI_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents,
      generationConfig: {
        temperature: 0.8,
        maxOutputTokens: 512,
      },
    }),
  })

  if (!res.ok) {
    const err = await res.text()
    throw new Error(`Gemini API error: ${res.status} ${err}`)
  }

  const data = await res.json()
  return data.candidates?.[0]?.content?.parts?.[0]?.text || ""
}

// ============================================================
// Helper
// ============================================================
function jsonResponse(data: any, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  })
}
