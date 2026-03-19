import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
}

/**
 * Voice Diary Edge Function
 *
 * 接收語音轉文字的內容，用 Gemini AI 分析：
 * 1. 情緒判斷（mood）
 * 2. 主題標籤（tags）
 * 3. 生成一段溫暖的日記文字（diary）
 */

interface VoiceDiaryRequest {
  transcript: string // 語音轉文字的原始文本
  date?: string // 日期 (YYYY-MM-DD)
}

interface DiaryAnalysis {
  mood: string // happy, calm, stressed, sad, excited, reflective
  moodEmoji: string
  tags: string[] // 主題標籤 e.g. ["工作", "咖啡", "朋友"]
  diary: string // AI 生成的日記段落
  summary: string // 一句話摘要
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  try {
    const geminiKey = Deno.env.get("GEMINI_API_KEY")
    if (!geminiKey) {
      // Fallback: 無 Gemini key 時用規則式分析
      const body = (await req.json()) as VoiceDiaryRequest
      return jsonResponse({
        success: true,
        data: fallbackAnalysis(body.transcript),
      })
    }

    const body = (await req.json()) as VoiceDiaryRequest
    if (!body.transcript || body.transcript.trim().length === 0) {
      return jsonResponse({ error: "請提供語音內容" }, 400)
    }

    const transcript = body.transcript.trim().slice(0, 2000)

    // 呼叫 Gemini API
    const analysis = await analyzeWithGemini(geminiKey, transcript)

    return jsonResponse({ success: true, data: analysis })
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "未知錯誤"
    console.error("voice-diary 錯誤:", message)

    // Fallback
    try {
      const body = await req.json()
      return jsonResponse({
        success: true,
        data: fallbackAnalysis(body.transcript || ""),
      })
    } catch {
      return jsonResponse({ error: message }, 500)
    }
  }
})

async function analyzeWithGemini(
  apiKey: string,
  transcript: string
): Promise<DiaryAnalysis> {
  const prompt = `你是一位溫暖的 AI 日記助手。使用者用語音記錄了以下內容，請幫忙分析並生成日記。

使用者說的話：
「${transcript}」

請用 JSON 格式回覆（不要加 markdown 標記）：
{
  "mood": "情緒（只能用以下其一：happy, calm, stressed, sad, excited, reflective）",
  "moodEmoji": "對應的 emoji（一個字元）",
  "tags": ["主題標籤1", "主題標籤2"],
  "diary": "用溫暖的第一人稱語氣，把使用者說的話改寫成一段日記（繁體中文，2-4 句話）",
  "summary": "一句話摘要（10字以內）"
}

注意：
- tags 最多 5 個，用繁體中文
- diary 要保留使用者原意，但用更文學、溫暖的方式表達
- 如果使用者提到金額或消費，也納入日記但不要變成記帳格式`

  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${apiKey}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: {
          temperature: 0.7,
          maxOutputTokens: 500,
        },
      }),
    }
  )

  if (!response.ok) {
    throw new Error(`Gemini API 錯誤: ${response.status}`)
  }

  const result = await response.json()
  const text =
    result.candidates?.[0]?.content?.parts?.[0]?.text || ""

  // 解析 JSON（移除可能的 markdown 包裝）
  const cleaned = text
    .replace(/```json\n?/g, "")
    .replace(/```\n?/g, "")
    .trim()

  try {
    return JSON.parse(cleaned) as DiaryAnalysis
  } catch {
    // JSON 解析失敗，fallback
    return fallbackAnalysis(transcript)
  }
}

function fallbackAnalysis(transcript: string): DiaryAnalysis {
  // 簡單規則式情緒判斷
  const lower = transcript.toLowerCase()
  let mood = "calm"
  let moodEmoji = "😌"

  if (
    lower.includes("開心") ||
    lower.includes("高興") ||
    lower.includes("棒")
  ) {
    mood = "happy"
    moodEmoji = "😊"
  } else if (
    lower.includes("累") ||
    lower.includes("壓力") ||
    lower.includes("煩")
  ) {
    mood = "stressed"
    moodEmoji = "😮‍💨"
  } else if (
    lower.includes("難過") ||
    lower.includes("傷心") ||
    lower.includes("失望")
  ) {
    mood = "sad"
    moodEmoji = "😢"
  } else if (
    lower.includes("興奮") ||
    lower.includes("期待") ||
    lower.includes("太好了")
  ) {
    mood = "excited"
    moodEmoji = "🤩"
  }

  // 簡單標籤提取
  const tags: string[] = []
  const tagMap: Record<string, string> = {
    吃: "美食",
    喝: "飲品",
    咖啡: "咖啡",
    工作: "工作",
    會議: "工作",
    朋友: "社交",
    家人: "家庭",
    運動: "運動",
    看書: "閱讀",
    電影: "娛樂",
    買: "購物",
    花: "消費",
  }
  for (const [keyword, tag] of Object.entries(tagMap)) {
    if (lower.includes(keyword) && !tags.includes(tag)) {
      tags.push(tag)
    }
  }
  if (tags.length === 0) tags.push("日常")

  return {
    mood,
    moodEmoji,
    tags: tags.slice(0, 5),
    diary: transcript.length > 0 ? `今天，${transcript}。` : "平靜的一天。",
    summary:
      transcript.length > 10
        ? transcript.slice(0, 10) + "⋯"
        : transcript || "日常記錄",
  }
}

function jsonResponse(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  })
}
