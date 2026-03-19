import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
}

/**
 * Life Diary Edge Function
 *
 * 將使用者的每日交易轉化為敘事日記，
 * 結合情感分析和消費模式產生溫暖的日記文字。
 *
 * GET  /life-diary?date=2026-03-19  — 取得指定日期日記
 * POST /life-diary                   — 生成/重新生成日記
 */

interface DiaryEntry {
  id: string
  user_id: string
  diary_date: string
  content: string
  mood: string
  highlight: string
  total_expense: number
  total_income: number
  transaction_count: number
  created_at: string
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

    // 用 anon key 驗證使用者身份
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

    // 用 service role 進行資料操作
    const supabase = createClient(supabaseUrl, serviceRoleKey)

    if (req.method === "GET") {
      return await handleGetDiary(req, supabase, user.id)
    } else if (req.method === "POST") {
      return await handleGenerateDiary(req, supabase, user.id)
    }

    return jsonResponse({ error: "不支援的方法" }, 405)
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "未知錯誤"
    console.error("life-diary 錯誤:", message)
    return jsonResponse({ error: message }, 500)
  }
})

async function handleGetDiary(
  req: Request,
  supabase: ReturnType<typeof createClient>,
  userId: string
) {
  const url = new URL(req.url)
  const dateStr =
    url.searchParams.get("date") || new Date().toISOString().split("T")[0]

  const { data, error } = await supabase
    .from("life_diaries")
    .select("*")
    .eq("user_id", userId)
    .eq("diary_date", dateStr)
    .maybeSingle()

  if (error) {
    return jsonResponse({ error: "取得日記失敗: " + error.message }, 500)
  }

  if (!data) {
    return jsonResponse({
      success: true,
      data: null,
      message: "該日期尚無日記，可以 POST 生成",
    })
  }

  return jsonResponse({ success: true, data })
}

async function handleGenerateDiary(
  req: Request,
  supabase: ReturnType<typeof createClient>,
  userId: string
) {
  const body = await req.json().catch(() => ({}))
  const dateStr =
    body.date || new Date().toISOString().split("T")[0]

  // 取得該日交易
  const dayStart = `${dateStr}T00:00:00.000Z`
  const dayEnd = `${dateStr}T23:59:59.999Z`

  const { data: transactions, error: txError } = await supabase
    .from("transactions")
    .select(
      "amount, transaction_type, category, description, created_at, location_name"
    )
    .eq("user_id", userId)
    .gte("created_at", dayStart)
    .lte("created_at", dayEnd)
    .order("created_at", { ascending: true })

  if (txError) {
    return jsonResponse({ error: "取得交易失敗: " + txError.message }, 500)
  }

  const txList = transactions || []

  // 計算摘要
  let totalExpense = 0
  let totalIncome = 0
  const categories: Record<string, number> = {}

  for (const tx of txList) {
    if (tx.transaction_type === "income") {
      totalIncome += tx.amount
    } else {
      totalExpense += tx.amount
      const cat = tx.category || "other"
      categories[cat] = (categories[cat] || 0) + tx.amount
    }
  }

  // 判斷心情
  const mood = determineMood(totalExpense, totalIncome, txList.length)

  // 找出亮點
  const highlight = findHighlight(txList)

  // 生成日記內容
  const content = generateDiaryContent(
    dateStr,
    txList,
    totalExpense,
    totalIncome,
    categories,
    mood
  )

  // 儲存或更新日記
  const diaryData = {
    user_id: userId,
    diary_date: dateStr,
    content,
    mood,
    highlight,
    total_expense: totalExpense,
    total_income: totalIncome,
    transaction_count: txList.length,
  }

  const { data: saved, error: saveError } = await supabase
    .from("life_diaries")
    .upsert(diaryData, { onConflict: "user_id,diary_date" })
    .select()
    .single()

  if (saveError) {
    // 如果資料表不存在，仍回傳日記內容
    console.error("儲存日記失敗:", saveError.message)
    return jsonResponse({ success: true, data: diaryData, persisted: false })
  }

  return jsonResponse({ success: true, data: saved, persisted: true })
}

function determineMood(
  expense: number,
  income: number,
  count: number
): string {
  if (count === 0) return "peaceful" // 沒有交易，平靜的一天
  if (income > expense * 2) return "joyful" // 收入遠超支出
  if (expense > 5000) return "cautious" // 大額支出
  if (count >= 5) return "busy" // 很多筆交易
  return "balanced" // 正常
}

function findHighlight(
  transactions: Record<string, unknown>[]
): string {
  if (transactions.length === 0) return "悠閒的一天"

  // 找出最大筆交易
  let maxTx = transactions[0]
  for (const tx of transactions) {
    if ((tx.amount as number) > (maxTx.amount as number)) {
      maxTx = tx
    }
  }

  return (maxTx.description as string) || "日常消費"
}

function generateDiaryContent(
  dateStr: string,
  transactions: Record<string, unknown>[],
  totalExpense: number,
  totalIncome: number,
  categories: Record<string, number>,
  mood: string
): string {
  const date = new Date(dateStr)
  const weekdays = ["日", "一", "二", "三", "四", "五", "六"]
  const weekday = weekdays[date.getDay()]
  const dateDisplay = `${date.getMonth() + 1}月${date.getDate()}日（週${weekday}）`

  if (transactions.length === 0) {
    return `${dateDisplay}\n\n今天沒有記錄任何消費，是個平靜的日子。也許在家休息，也許忙到忘了記帳。無論如何，偶爾放慢腳步也是一種生活的智慧。`
  }

  const lines: string[] = [`${dateDisplay}\n`]

  // 開場
  const moodOpening: Record<string, string> = {
    joyful: "今天是豐收的一天！",
    cautious: "今天有一些大額支出，但每一筆都有它的價值。",
    busy: "忙碌充實的一天，腳步不停歇。",
    balanced: "平穩的一天，日子就該這樣細水長流。",
    peaceful: "寧靜的一天。",
  }
  lines.push(moodOpening[mood] || "又是嶄新的一天。")

  // 消費紀事
  if (totalExpense > 0) {
    const topCategory = Object.entries(categories).sort(
      (a, b) => b[1] - a[1]
    )[0]
    const categoryNames: Record<string, string> = {
      food: "餐飲",
      transport: "交通",
      entertainment: "娛樂",
      shopping: "購物",
      utilities: "日用",
      health: "健康",
      education: "教育",
      investment: "投資",
      other: "其他",
    }
    const catName = categoryNames[topCategory[0]] || topCategory[0]
    lines.push(
      `\n今天共有 ${transactions.length} 筆記錄，支出 NT$${totalExpense.toLocaleString()}，其中「${catName}」佔比最高。`
    )
  }

  if (totalIncome > 0) {
    lines.push(`收入方面進帳 NT$${totalIncome.toLocaleString()}，不錯呢！`)
  }

  // 一些交易描述
  const notable = transactions.slice(0, 3)
  if (notable.length > 0) {
    lines.push("\n生活片段：")
    for (const tx of notable) {
      const desc = tx.description as string
      const amount = tx.amount as number
      const isIncome = tx.transaction_type === "income"
      if (desc) {
        lines.push(
          isIncome
            ? `• ${desc}，進帳 NT$${amount.toLocaleString()}`
            : `• ${desc}，花了 NT$${amount.toLocaleString()}`
        )
      }
    }
  }

  // 結尾
  const closings = [
    "\n好好休息，明天繼續加油！🌙",
    "\n今天辛苦了，期待明天更好的自己 ✨",
    "\n每一天都在為未來的自己努力著 💪",
  ]
  lines.push(closings[date.getDate() % closings.length])

  return lines.join("\n")
}

function jsonResponse(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  })
}
