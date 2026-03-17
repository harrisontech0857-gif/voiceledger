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
  Deno.env.get("SUPABASE_ANON_KEY") || ""
);

const anthropic = new Anthropic({
  apiKey: Deno.env.get("ANTHROPIC_API_KEY"),
});

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
  timestamp: string;
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
    .select("amount, category, timestamp")
    .eq("user_id", user_id)
    .eq("status", "confirmed")
    .gte("timestamp", start.toISOString())
    .lte("timestamp", end.toISOString())
    .order("timestamp", { ascending: false });

  if (error) {
    throw new Error(`Failed to fetch transactions: ${error.message}`);
  }

  // Calculate daily statistics
  const daily_stats: Record<string, number> = {};
  const category_breakdown: Record<string, number> = {};

  for (const tx of transactions || []) {
    const date = new Date(tx.timestamp).toISOString().split("T")[0];
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
    const day_of_week = new Date(tx.timestamp).getDay();
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

  const message = await anthropic.messages.create({
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
