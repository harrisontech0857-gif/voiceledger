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
 * 接收語音轉文字的內容，用 AI 分析：
 * 1. 情緒判斷（mood）
 * 2. 主題標籤（tags）
 * 3. 生成一段溫暖的日記文字（diary）
 *
 * AI 優先順序：Anthropic Claude → Gemini → 規則式 fallback
 */

interface VoiceDiaryRequest {
  transcript: string
}

interface DiaryAnalysis {
  mood: string
  moodEmoji: string
  tags: string[]
  diary: string
  summary: string
}

const PROMPT = (transcript: string) => `你是一位溫暖的 AI 日記助手。使用者用語音記錄了以下內容，請幫忙分析並生成日記。

使用者說的話：
「${transcript}」

請用 JSON 格式回覆（不要加 markdown 標記，只回覆純 JSON）：
{
  "mood": "情緒（只能用以下其一：happy, calm, stressed, sad, excited, reflective）",
  "moodEmoji": "對應的 emoji（一個字元）",
  "tags": ["主題標籤1", "主題標籤2"],
  "diary": "用溫暖的第一人稱語氣，把使用者說的話改寫成一段日記（繁體中文，2-4 句話）",
  "summary": "一句話摘要（10字以內）"
}

注意：tags 最多 5 個，用繁體中文。diary 要保留使用者原意但更文學溫暖。`

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  try {
    const body = (await req.json()) as VoiceDiaryRequest
    if (!body.transcript || body.transcript.trim().length === 0) {
      return jsonResponse({ error: "請提供語音內容" }, 400)
    }

    const transcript = body.transcript.trim().slice(0, 2000)

    // 優先使用 Groq（免費、快速、額度大）
    const groqKey = Deno.env.get("GROQ_API_KEY")
    if (groqKey) {
      try {
        const analysis = await analyzeWithGroq(groqKey, transcript)
        return jsonResponse({ success: true, data: analysis, ai_used: "groq" })
      } catch (e) {
        console.error("Groq API 失敗:", e)
      }
    }

    // Fallback 2: Anthropic Claude
    const anthropicKey = Deno.env.get("ANTHROPIC_API_KEY")
    if (anthropicKey) {
      try {
        const analysis = await analyzeWithClaude(anthropicKey, transcript)
        return jsonResponse({ success: true, data: analysis, ai_used: "claude" })
      } catch (e) {
        console.error("Claude API 也失敗:", e)
      }
    }

    // Fallback 3: Gemini
    const geminiKey = Deno.env.get("GEMINI_API_KEY")
    if (geminiKey) {
      try {
        const analysis = await analyzeWithGemini(geminiKey, transcript)
        return jsonResponse({ success: true, data: analysis })
      } catch (e) {
        console.error("Gemini API 也失敗:", e)
      }
    }

    // 最終 fallback: 規則式
    console.warn("所有 AI API 都失敗，使用規則式 fallback")
    const fb = fallbackAnalysis(transcript)
    return jsonResponse({ success: true, data: fb, ai_used: "fallback" })
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "未知錯誤"
    console.error("voice-diary 錯誤:", message)
    return jsonResponse({ success: true, data: fallbackAnalysis("") })
  }
})

// ─── Groq API（OpenAI 相容格式）─────────────────

async function analyzeWithGroq(
  apiKey: string,
  transcript: string
): Promise<DiaryAnalysis> {
  const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: "llama-3.1-8b-instant",
      messages: [
        { role: "user", content: PROMPT(transcript) },
      ],
      max_tokens: 500,
      temperature: 0.7,
    }),
  })

  if (!response.ok) {
    const err = await response.text()
    throw new Error(`Groq API ${response.status}: ${err.slice(0, 200)}`)
  }

  const result = await response.json()
  const text = result.choices?.[0]?.message?.content || ""
  return parseJsonResponse(text, transcript)
}

// ─── Anthropic Claude API ────────────────────────

async function analyzeWithClaude(
  apiKey: string,
  transcript: string
): Promise<DiaryAnalysis> {
  const response = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": apiKey,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: "claude-3-5-haiku-20241022",
      max_tokens: 500,
      messages: [
        { role: "user", content: PROMPT(transcript) },
      ],
    }),
  })

  if (!response.ok) {
    const err = await response.text()
    throw new Error(`Claude API ${response.status}: ${err.slice(0, 200)}`)
  }

  const result = await response.json()
  const text = result.content?.[0]?.text || ""
  return parseJsonResponse(text, transcript)
}

// ─── Gemini API ──────────────────────────────────

async function analyzeWithGemini(
  apiKey: string,
  transcript: string
): Promise<DiaryAnalysis> {
  // 嘗試多個模型
  const models = ["gemini-2.5-flash-lite", "gemini-2.0-flash-lite", "gemini-2.0-flash"]

  for (const model of models) {
    try {
      const response = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            contents: [{ parts: [{ text: PROMPT(transcript) }] }],
            generationConfig: { temperature: 0.7, maxOutputTokens: 500 },
          }),
        }
      )

      if (!response.ok) continue // 嘗試下一個模型

      const result = await response.json()
      const text = result.candidates?.[0]?.content?.parts?.[0]?.text || ""
      return parseJsonResponse(text, transcript)
    } catch {
      continue
    }
  }

  throw new Error("所有 Gemini 模型都無法使用")
}

// ─── 共用 JSON 解析 ──────────────────────────────

function parseJsonResponse(text: string, transcript: string): DiaryAnalysis {
  const cleaned = text
    .replace(/```json\n?/g, "")
    .replace(/```\n?/g, "")
    .trim()

  try {
    return JSON.parse(cleaned) as DiaryAnalysis
  } catch {
    return fallbackAnalysis(transcript)
  }
}

// ─── 規則式 Fallback ─────────────────────────────

function fallbackAnalysis(transcript: string): DiaryAnalysis {
  const lower = transcript.toLowerCase()
  let mood = "calm"
  let moodEmoji = "😌"

  if (lower.includes("開心") || lower.includes("高興") || lower.includes("棒")) {
    mood = "happy"; moodEmoji = "😊"
  } else if (lower.includes("累") || lower.includes("壓力") || lower.includes("煩")) {
    mood = "stressed"; moodEmoji = "😮‍💨"
  } else if (lower.includes("難過") || lower.includes("傷心")) {
    mood = "sad"; moodEmoji = "😢"
  } else if (lower.includes("興奮") || lower.includes("期待")) {
    mood = "excited"; moodEmoji = "🤩"
  }

  const tags: string[] = []
  const tagMap: Record<string, string> = {
    吃: "美食", 咖啡: "咖啡", 工作: "工作", 朋友: "社交",
    運動: "運動", 買: "購物", 家: "家庭",
  }
  for (const [kw, tag] of Object.entries(tagMap)) {
    if (lower.includes(kw) && !tags.includes(tag)) tags.push(tag)
  }
  if (tags.length === 0) tags.push("日常")

  return {
    mood,
    moodEmoji,
    tags: tags.slice(0, 5),
    diary: transcript.length > 0 ? `今天，${transcript}。` : "平靜的一天。",
    summary: transcript.length > 10 ? transcript.slice(0, 10) + "⋯" : transcript || "日常記錄",
  }
}

function jsonResponse(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  })
}
