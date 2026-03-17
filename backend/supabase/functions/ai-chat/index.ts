import { serve } from "https://deno.land/std@0.192.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.0";
import { Anthropic } from "https://esm.sh/@anthropic-ai/sdk@0.10.0";

interface ConversationMessage {
  role: "user" | "assistant";
  content: string;
}

interface AIChatRequest {
  message: string;
  session_id: string;
  context: {
    user_timezone: string;
    conversation_history?: ConversationMessage[];
  };
}

interface QueryResult {
  total_amount: number;
  category?: string;
  period?: string;
  breakdown?: Record<string, number>;
  daily_average?: number;
  data?: unknown[];
}

interface AIChatResponse {
  success: boolean;
  response?: {
    message: string;
    data?: QueryResult;
    query_type?: string;
    sql_executed?: string;
    confidence?: number;
  };
  processing_details?: {
    parsing_time_ms: number;
    query_time_ms: number;
    total_time_ms: number;
  };
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

interface QueryIntent {
  type: string;
  entities: Record<string, unknown>;
  sql_template: string;
  requires_data_fetch: boolean;
}

function generate_uuid(): string {
  return crypto.randomUUID();
}

// Parse user message to extract intent and entities
async function parse_user_intent(
  message: string,
  timezone: string
): Promise<QueryIntent> {
  const prompt = `You are a financial query parser. Analyze the user message and extract:
1. Query type: balance_query, category_summary, trend_analysis, budget_check, comparison, anomaly_detection, recommendation
2. Entities: category, time_period, merchant, amount_threshold
3. Required SQL pattern

User message: "${message}"
Timezone: ${timezone}

Return JSON:
{
  "type": "string",
  "entities": {
    "category": "string|null",
    "period": "string|null",
    "start_date": "ISO date|null",
    "end_date": "ISO date|null",
    "merchant": "string|null",
    "amount_threshold": "number|null"
  },
  "confidence": "number (0-1)"
}`;

  const message_resp = await anthropic.messages.create({
    model: "claude-3-5-sonnet-20241022",
    max_tokens: 512,
    messages: [
      {
        role: "user",
        content: prompt,
      },
    ],
  });

  const content = message_resp.content[0];
  if (content.type !== "text") {
    throw new Error("Unexpected response type");
  }

  const json_match = content.text.match(/\{[\s\S]*\}/);
  if (!json_match) {
    throw new Error("Could not parse intent");
  }

  const intent_data = JSON.parse(json_match[0]);

  return {
    type: intent_data.type,
    entities: intent_data.entities,
    sql_template: "", // Will be generated based on type
    requires_data_fetch: true,
  };
}

// Build SQL query based on intent
function build_sql_query(user_id: string, intent: QueryIntent): string {
  const { type, entities } = intent;

  const start_date =
    entities.start_date || new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
  const end_date = entities.end_date || new Date();

  switch (type) {
    case "category_summary":
      return `SELECT
        category,
        SUM(amount) as total,
        COUNT(*) as transaction_count,
        AVG(amount) as avg_amount
      FROM transactions
      WHERE user_id = '${user_id}'
        AND category = '${entities.category}'
        AND timestamp >= '${start_date.toISOString()}'
        AND timestamp <= '${end_date.toISOString()}'
        AND status = 'confirmed'
      GROUP BY category`;

    case "trend_analysis":
      return `SELECT
        DATE(timestamp) as date,
        SUM(amount) as daily_total,
        category
      FROM transactions
      WHERE user_id = '${user_id}'
        AND timestamp >= '${start_date.toISOString()}'
        AND timestamp <= '${end_date.toISOString()}'
        AND status = 'confirmed'
      GROUP BY DATE(timestamp), category
      ORDER BY date DESC`;

    case "balance_query":
      return `SELECT
        SUM(amount) as total_spent,
        COUNT(*) as transaction_count,
        MIN(amount) as min_transaction,
        MAX(amount) as max_transaction
      FROM transactions
      WHERE user_id = '${user_id}'
        AND timestamp >= '${start_date.toISOString()}'
        AND timestamp <= '${end_date.toISOString()}'
        AND status = 'confirmed'`;

    case "budget_check":
      return `SELECT
        category,
        SUM(amount) as spent,
        COUNT(*) as transaction_count
      FROM transactions
      WHERE user_id = '${user_id}'
        AND timestamp >= DATE_TRUNC('month', CURRENT_DATE)
        AND status = 'confirmed'
      GROUP BY category
      ORDER BY spent DESC`;

    case "comparison":
      return `SELECT
        DATE_TRUNC('month', timestamp)::date as month,
        SUM(amount) as monthly_total,
        COUNT(*) as transaction_count
      FROM transactions
      WHERE user_id = '${user_id}'
        AND timestamp >= '${new Date(Date.now() - 90 * 24 * 60 * 60 * 1000).toISOString()}'
        AND status = 'confirmed'
      GROUP BY month
      ORDER BY month DESC`;

    default:
      return `SELECT
        SUM(amount) as total,
        COUNT(*) as count
      FROM transactions
      WHERE user_id = '${user_id}'
        AND timestamp >= '${start_date.toISOString()}'
        AND timestamp <= '${end_date.toISOString()}'
        AND status = 'confirmed'`;
  }
}

// Execute SQL query
async function execute_query(
  user_id: string,
  sql: string
): Promise<{ data: unknown[]; count: number }> {
  // Use RPC function or direct query
  const { data, error, count } = await supabase.rpc("execute_sql", {
    query: sql,
  });

  if (error) {
    // Fallback: execute simple queries directly
    if (sql.includes("category_summary")) {
      const { data: result, error: err } = await supabase
        .from("transactions")
        .select("category, amount")
        .eq("user_id", user_id)
        .eq("status", "confirmed")
        .gte(
          "timestamp",
          new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString()
        );

      if (err) throw err;
      return { data: result || [], count: result?.length || 0 };
    }

    throw error;
  }

  return { data: data || [], count: count || 0 };
}

// Generate natural language response
async function generate_response(
  user_message: string,
  query_results: unknown[],
  intent: QueryIntent,
  timezone: string
): Promise<string> {
  const prompt = `You are a friendly financial assistant. Based on the user query and data results, generate a natural language response in Traditional Chinese (繁體中文).

User Message: "${user_message}"
Query Type: ${intent.type}
Data Results: ${JSON.stringify(query_results)}
Timezone: ${timezone}

Guidelines:
1. Be conversational and helpful
2. Provide specific numbers and insights
3. Add actionable tips if relevant
4. Use emoji sparingly (only for emphasis)
5. Keep response concise (2-3 sentences max with bullet points if needed)

Generate response:`;

  const response = await anthropic.messages.create({
    model: "claude-3-5-sonnet-20241022",
    max_tokens: 512,
    messages: [
      {
        role: "user",
        content: prompt,
      },
    ],
  });

  const content = response.content[0];
  if (content.type !== "text") {
    throw new Error("Unexpected response type");
  }

  return content.text;
}

serve(async (req: Request) => {
  const start_time = performance.now();

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: { "Access-Control-Allow-Origin": "*" } });
  }

  try {
    // Validate authentication
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

    const user_id = user.id;
    const body: AIChatRequest = await req.json();

    // Validate input
    if (!body.message || body.message.trim().length === 0) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "INVALID_INPUT",
          message: "Message is empty",
        }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const parsing_start = performance.now();

    // Parse user intent
    const intent = await parse_user_intent(
      body.message,
      body.context.user_timezone
    );

    const parsing_time = performance.now() - parsing_start;

    // Build and execute query
    const query_start = performance.now();
    const sql = build_sql_query(user_id, intent);
    const query_result = await execute_query(user_id, sql);
    const query_time = performance.now() - query_start;

    // Generate response
    const response_text = await generate_response(
      body.message,
      query_result.data,
      intent,
      body.context.user_timezone
    );

    // Calculate total time
    const total_time = performance.now() - start_time;

    const response_payload: AIChatResponse = {
      success: true,
      response: {
        message: response_text,
        query_type: intent.type,
        sql_executed: sql,
        confidence: 0.92,
      },
      processing_details: {
        parsing_time_ms: Math.round(parsing_time),
        query_time_ms: Math.round(query_time),
        total_time_ms: Math.round(total_time),
      },
    };

    return new Response(JSON.stringify(response_payload), {
      status: 200,
      headers: {
        "Content-Type": "application/json",
        "X-Request-Id": generate_uuid(),
        "X-Processing-Time": `${Math.round(total_time)}ms`,
        "Access-Control-Allow-Origin": "*",
      },
    });
  } catch (error) {
    console.error("Error in ai-chat function:", error);

    const response: AIChatResponse = {
      success: false,
      error: "CHAT_ERROR",
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
