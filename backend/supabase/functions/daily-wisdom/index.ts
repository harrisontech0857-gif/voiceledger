import { serve } from "https://deno.land/std@0.192.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.0";
import { Anthropic } from "https://esm.sh/@anthropic-ai/sdk@0.10.0";

interface DailyWisdomRequest {
  user_id?: string;
  date?: string;
  tone?: "encouraging" | "cautious" | "analytical";
}

interface DataInsight {
  period: string;
  total_spending: number;
  spending_trend: "increasing" | "decreasing" | "stable";
  biggest_category: string;
  interesting_pattern: string;
}

interface DailyWisdom {
  date: string;
  quote: string;
  tone: string;
  data_insight: DataInsight;
  actionable_tip: string;
  generated_at: string;
  expires_at: string;
}

interface WisdomHistory {
  date: string;
  quote: string;
}

interface DailyWisdomResponse {
  success: boolean;
  wisdom?: DailyWisdom;
  history?: WisdomHistory[];
  error?: string;
  message?: string;
}

const supabase = createClient(
  Deno.env.get("SUPABASE_URL") || "",
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || ""
);

const enableAiApi = (Deno.env.get("ENABLE_AI_API") || "false").toLowerCase() === "true";

const anthropic = enableAiApi ? new Anthropic({
  apiKey: Deno.env.get("ANTHROPIC_API_KEY"),
}) : null;

// 50 條內建的繁體中文理財金句
const builtInQuotes = [
  "財富不是來自收入，而是來自如何花費。",
  "最好的投資就是投資於你自己的知識。",
  "儲蓄不是為了錢，而是為了自由。",
  "消費要節制，快樂要適度。",
  "今天的節儉，就是明天的富有。",
  "人生最大的資本，是時間和健康。",
  "金錢會說謊，數字不會。",
  "小錢不浪費，大錢才能存。",
  "預算是通往財務自由的路標。",
  "理性消費，享受生活，兩者可以兼得。",
  "被動收入讓你睡覺也在賺錢。",
  "投資自己，永遠不虧。",
  "計畫好的消費，不會傷害存款。",
  "每筆消費都是一個選擇，好好珍惜每一個。",
  "複利是世界上第八大奇蹟。",
  "貧困源於無計畫，富有源於有策略。",
  "今天不存錢，未來就得省錢。",
  "人生最大的遺憾，是沒能及早存錢。",
  "理財不難，難在持之以恆。",
  "金錢只是工具，目標才是方向。",
  "小步持續，大步達成。",
  "消費清單能救你的錢包。",
  "每一分錢都在為你的未來投票。",
  "習慣改變，人生就改變。",
  "理財的第一步，是停止浪費。",
  "存錢不是為了有錢，而是為了有選擇權。",
  "花錢要聰慧，存錢要堅持。",
  "預算自由，人生自由。",
  "不花無謂的錢，才能花值得的錢。",
  "理財是一場馬拉松，不是短跑。",
  "每一筆消費，都在塑造你的未來。",
  "高收入不一定等於高存款。",
  "健康的財務，來自健康的習慣。",
  "只有你能拯救你的錢包。",
  "持續學習理財，終身受益。",
  "消費決定了你的品質，存錢決定了你的未來。",
  "財務自由不是終點，而是旅程。",
  "每天進步一點點，一年大不同。",
  "你的消費反映了你的優先順序。",
  "理財高手的秘訣，就是重複做簡單的事。",
  "改變觀念，改變生活。",
  "金錢會跟著你的習慣走。",
  "存錢是最好的投資，投資自己是最好的回報。",
  "想要有富人的生活，先要有富人的習慣。",
  "理財成功的關鍵，是早起步。",
  "消費是生活的一部分，不是全部。",
  "每個富人都是從節儉開始的。",
  "目標明確，行動就明確。",
  "你的錢在哪，你的人生就在哪。",
  "理財不是限制，而是自由。",
];

function getQuoteOfDay(): string {
  const today = new Date();
  const dayOfYear = Math.floor((today.getTime() - new Date(today.getFullYear(), 0, 0).getTime()) / 1000 / 60 / 60 / 24);
  return builtInQuotes[dayOfYear % builtInQuotes.length];
}

function generate_uuid(): string {
  return crypto.randomUUID();
}

function get_date_range(
  target_date: Date
): {
  start: Date;
  end: Date;
} {
  const end = new Date(target_date);
  end.setHours(23, 59, 59, 999);

  const start = new Date(target_date);
  start.setDate(start.getDate() - 7);
  start.setHours(0, 0, 0, 0);

  return { start, end };
}

interface TransactionData {
  amount: number;
  category: string;
  transaction_date: string;
}

async function fetch_spending_data(
  user_id: string,
  target_date: Date
): Promise<{
  transactions: TransactionData[];
  daily_stats: Record<string, number>;
  category_breakdown: Record<string, number>;
}> {
  const { start, end } = get_date_range(target_date);

  const { data: transactions, error } = await supabase
    .from("transactions")
    .select("amount, category, transaction_date")
    .eq("user_id", user_id)
    .eq("is_verified", true)
    .gte("transaction_date", start.toISOString().split("T")[0])
    .lte("transaction_date", end.toISOString().split("T")[0])
    .order("transaction_date", { ascending: false });

  if (error) {
    throw new Error(`Failed to fetch transactions: ${error.message}`);
  }

  // Calculate daily statistics
  const daily_stats: Record<string, number> = {};
  const category_breakdown: Record<string, number> = {};

  for (const tx of transactions || []) {
    const date = tx.transaction_date;
    daily_stats[date] = (daily_stats[date] || 0) + tx.amount;
    category_breakdown[tx.category] =
      (category_breakdown[tx.category] || 0) + tx.amount;
  }

  return {
    transactions: transactions || [],
    daily_stats,
    category_breakdown,
  };
}

interface DailyStats {
  total_spending: number;
  daily_average: number;
  transactions_count: number;
  biggest_category: string;
  biggest_category_amount: number;
}

function analyze_spending_data(
  transactions: TransactionData[],
  daily_stats: Record<string, number>,
  category_breakdown: Record<string, number>
): {
  stats: DailyStats;
  trend: "increasing" | "decreasing" | "stable";
  pattern: string;
} {
  const total_spending = transactions.reduce((sum, tx) => sum + tx.amount, 0);
  const days_count = Object.keys(daily_stats).length || 1;
  const daily_average = Math.round(total_spending / days_count);

  // Determine trend
  const daily_values = Object.values(daily_stats).sort((a, b) => a - b);
  const first_half_avg =
    daily_values.slice(0, Math.floor(daily_values.length / 2)).reduce((a, b) => a + b, 0) /
    Math.max(1, Math.floor(daily_values.length / 2));
  const second_half_avg =
    daily_values.slice(Math.floor(daily_values.length / 2)).reduce((a, b) => a + b, 0) /
    Math.max(1, daily_values.length - Math.floor(daily_values.length / 2));

  let trend: "increasing" | "decreasing" | "stable" = "stable";
  if (second_half_avg > first_half_avg * 1.1) {
    trend = "increasing";
  } else if (second_half_avg < first_half_avg * 0.9) {
    trend = "decreasing";
  }

  // Find biggest category
  const [biggest_category, biggest_amount] = Object.entries(
    category_breakdown
  ).sort((a, b) => b[1] - a[1])[0] || ["other", 0];

  // Detect pattern
  const weekday_totals: Record<number, number> = {};
  for (const tx of transactions) {
    const day_of_week = new Date(tx.transaction_date).getDay();
    weekday_totals[day_of_week] =
      (weekday_totals[day_of_week] || 0) + tx.amount;
  }

  const weekday_avg =
    Object.values(weekday_totals)
      .slice(1, 6)
      .reduce((a, b) => a + b, 0) / 5;
  const weekend_avg =
    (weekday_totals[0] + weekday_totals[6]) / 2;
  const weekend_ratio = (weekend_avg / weekday_avg).toFixed(1);

  let pattern = "平衡的消費模式";
  if (weekend_ratio > 1.2) {
    pattern = `weekday_vs_weekend_ratio: ${weekend_ratio} (週末消費偏高)`;
  } else if (weekend_ratio < 0.8) {
    pattern = `weekday_vs_weekend_ratio: ${weekend_ratio} (平日消費偏高)`;
  }

  return {
    stats: {
      total_spending,
      daily_average,
      transactions_count: transactions.length,
      biggest_category,
      biggest_category_amount: Math.round(biggest_amount),
    },
    trend,
    pattern,
  };
}

// 本地金句生成 - 根據消費情況選擇合適的金句
function generate_wisdom_quote_local(
  stats: {
    stats: {
      total_spending: number;
      daily_average: number;
      transactions_count: number;
      biggest_category: string;
      biggest_category_amount: number;
    };
    trend: "increasing" | "decreasing" | "stable";
    pattern: string;
  }
): {
  quote: string;
  actionable_tip: string;
} {
  const todayQuote = getQuoteOfDay();
  let actionableTip = "今天記下您的每一筆消費，明天就會看到改變。";

  // 根據消費趨勢提供建議
  if (stats.trend === "increasing") {
    actionableTip = `您的消費呈上升趨勢。建議檢視 ${stats.stats.biggest_category} 的支出，嘗試調整預算。`;
  } else if (stats.trend === "decreasing") {
    actionableTip = "您的消費呈下降趨勢，這很棒！保持這個勢頭，持續努力。";
  } else {
    actionableTip = `您的消費相對穩定。在 ${stats.stats.biggest_category} 方面的支出最多，可以考慮進一步優化。`;
  }

  return {
    quote: todayQuote,
    actionable_tip: actionableTip,
  };
}

async function generate_wisdom_quote(
  user_id: string,
  stats: {
    stats: {
      total_spending: number;
      daily_average: number;
      transactions_count: number;
      biggest_category: string;
      biggest_category_amount: number;
    };
    trend: "increasing" | "decreasing" | "stable";
    pattern: string;
  },
  tone: string = "encouraging"
): Promise<{
  quote: string;
  actionable_tip: string;
}> {
  // 如果 AI API 未啟用，使用本地金句庫
  if (!enableAiApi || !anthropic) {
    console.log("ENABLE_AI_API is false, using built-in quotes");
    return generate_wisdom_quote_local(stats);
  }

  const tone_instruction = {
    encouraging:
      "Use positive and motivating language to encourage good financial habits",
    cautious:
      "Provide a gentle warning about potential overspending without being judgmental",
    analytical: "Provide data-driven insights and concrete recommendations",
  };

  const prompt = `You are a wise financial AI assistant. Generate a personalized daily financial wisdom quote for a user in Traditional Chinese.

User Spending Data (Last 7 days):
- Total Spending: NT$${stats.stats.total_spending}
- Daily Average: NT$${stats.stats.daily_average}
- Transaction Count: ${stats.stats.transactions_count}
- Biggest Category: ${stats.stats.biggest_category} (NT$${stats.stats.biggest_category_amount})
- Trend: ${stats.trend}
- Pattern: ${stats.pattern}

Tone: ${tone}
Instructions: ${tone_instruction[tone as keyof typeof tone_instruction]}

Generate in this JSON format:
{
  "quote": "A meaningful, personalized financial wisdom quote (2-3 sentences)",
  "actionable_tip": "One specific, actionable tip based on their spending patterns"
}

Requirements:
- Quote should reference their specific spending data
- Be conversational and warm
- Include metaphors or relatable examples when relevant
- Tip should be concrete and implementable`;

  const message = await anthropic!.messages.create({
    model: "claude-3-5-sonnet-20241022",
    max_tokens: 512,
    messages: [
      {
        role: "user",
        content: prompt,
      },
    ],
  });

  const content = message.content[0];
  if (content.type !== "text") {
    throw new Error("Unexpected response type");
  }

  const json_match = content.text.match(/\{[\s\S]*\}/);
  if (!json_match) {
    throw new Error("Could not parse wisdom response");
  }

  return JSON.parse(json_match[0]);
}

async function fetch_wisdom_history(
  user_id: string,
  limit: number = 7
): Promise<WisdomHistory[]> {
  const { data, error } = await supabase
    .from("daily_wisdom")
    .select("date, quote")
    .eq("user_id", user_id)
    .order("date", { ascending: false })
    .limit(limit);

  if (error) {
    console.error("Failed to fetch wisdom history:", error);
    return [];
  }

  return (data || []).map((item) => ({
    date: item.date,
    quote: item.quote,
  }));
}

async function store_wisdom(
  user_id: string,
  wisdom: DailyWisdom
): Promise<void> {
  const { error } = await supabase.from("daily_wisdom").insert([
    {
      user_id,
      date: wisdom.date,
      quote: wisdom.quote,
      tone: wisdom.tone,
      data_insight: wisdom.data_insight,
      actionable_tip: wisdom.actionable_tip,
      generated_at: wisdom.generated_at,
      expires_at: wisdom.expires_at,
    },
  ]);

  if (error) {
    console.error("Failed to store wisdom:", error);
    // Don't throw - wisdom generation shouldn't fail if storage fails
  }
}

serve(async (req: Request) => {
  const start_time = performance.now();

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: { "Access-Control-Allow-Origin": "*" } });
  }

  try {
    // Extract user from auth header
    const auth_header = req.headers.get("Authorization");
    if (!auth_header || !auth_header.startsWith("Bearer ")) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "AUTH_ERROR",
          message: "Missing or invalid authorization header",
        }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      );
    }

    const token = auth_header.slice(7);
    const {
      data: { user },
      error: auth_error,
    } = await supabase.auth.getUser(token);

    if (auth_error || !user) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "AUTH_ERROR",
          message: "Invalid or expired token",
        }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      );
    }

    // Parse query parameters
    const url = new URL(req.url);
    const target_date_str = url.searchParams.get("date");
    const tone = (url.searchParams.get("tone") as any) || "encouraging";

    const target_date = target_date_str
      ? new Date(target_date_str)
      : new Date();

    const user_id = user.id;

    // Check if wisdom already generated for this date
    const { data: existing } = await supabase
      .from("daily_wisdom")
      .select("*")
      .eq("user_id", user_id)
      .eq("date", target_date.toISOString().split("T")[0])
      .single();

    if (existing) {
      // Return cached wisdom
      const history = await fetch_wisdom_history(user_id);
      const response: DailyWisdomResponse = {
        success: true,
        wisdom: existing as DailyWisdom,
        history,
      };

      return new Response(JSON.stringify(response), {
        status: 200,
        headers: {
          "Content-Type": "application/json",
          "X-Request-Id": generate_uuid(),
          "Access-Control-Allow-Origin": "*",
        },
      });
    }

    // Fetch spending data
    const spending_data = await fetch_spending_data(user_id, target_date);

    // Analyze data
    const analysis = analyze_spending_data(
      spending_data.transactions,
      spending_data.daily_stats,
      spending_data.category_breakdown
    );

    // Generate wisdom
    const { quote, actionable_tip } = await generate_wisdom_quote(
      user_id,
      analysis,
      tone
    );

    const now = new Date();
    const expires = new Date(now);
    expires.setDate(expires.getDate() + 1);

    const wisdom: DailyWisdom = {
      date: target_date.toISOString().split("T")[0],
      quote,
      tone,
      data_insight: {
        period: "last_7_days",
        total_spending: analysis.stats.total_spending,
        spending_trend: analysis.trend,
        biggest_category: analysis.stats.biggest_category,
        interesting_pattern: analysis.pattern,
      },
      actionable_tip,
      generated_at: now.toISOString(),
      expires_at: expires.toISOString(),
    };

    // Store wisdom (non-blocking)
    store_wisdom(user_id, wisdom).catch((err) =>
      console.error("Storage error:", err)
    );

    // Fetch history
    const history = await fetch_wisdom_history(user_id);

    const response: DailyWisdomResponse = {
      success: true,
      wisdom,
      history,
    };

    const processing_time = performance.now() - start_time;

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: {
        "Content-Type": "application/json",
        "X-Request-Id": generate_uuid(),
        "X-Processing-Time": `${Math.round(processing_time)}ms`,
        "Access-Control-Allow-Origin": "*",
      },
    });
  } catch (error) {
    console.error("Error in daily-wisdom function:", error);

    const response: DailyWisdomResponse = {
      success: false,
      error: "WISDOM_ERROR",
      message: error instanceof Error ? error.message : "Unknown error",
    };

    return new Response(JSON.stringify(response), {
      status: 500,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    });
  }
});
