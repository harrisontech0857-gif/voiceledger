import { serve } from "https://deno.land/std@0.192.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.0";
import { Anthropic } from "https://esm.sh/@anthropic-ai/sdk@0.10.0";

interface VoiceEntryRequest {
  transcript: string;
  audio_duration_ms: number;
  timestamp: string;
  metadata: {
    device_id: string;
    language?: string;
  };
}

interface ParsedEntry {
  id: string;
  amount: number;
  currency: string;
  category: string;
  merchant: string;
  description: string;
  timestamp: string;
  source: string;
  confidence: number;
  tags: string[];
}

interface VoiceEntryResponse {
  success: boolean;
  entries?: ParsedEntry[];
  parsing_details?: {
    sentence_count: number;
    split_ratio: number;
    model_used: string;
    processing_time_ms: number;
  };
  error?: string;
  message?: string;
  code?: string;
}

const supabase = createClient(
  Deno.env.get("SUPABASE_URL") || "",
  Deno.env.get("SUPABASE_ANON_KEY") || ""
);

const anthropic = new Anthropic({
  apiKey: Deno.env.get("ANTHROPIC_API_KEY"),
});

async function parse_voice_transcript(
  transcript: string,
  language: string = "zh-TW"
): Promise<{
  entries: any[];
  sentence_count: number;
  split_ratio: number;
}> {
  const prompt = `You are a financial transaction parser. Parse the following voice transcript and extract all spending entries.

IMPORTANT INSTRUCTIONS:
1. The user speaks in ${language}
2. If the transcript contains multiple transactions, SPLIT them into separate entries
3. For each transaction extract: amount, category, merchant/store name, description, estimated time
4. Return ONLY valid JSON array with transactions
5. Use confidence scores (0-1) for each transaction
6. Currency is TWD (Taiwan Dollar)

CATEGORIES: food, dining_out, groceries, food_delivery, transport, taxi, public_transit, car_maintenance, fuel, entertainment, movies, games, sports, events, shopping, clothing, electronics, home, beauty, utilities, electricity, water, internet, phone, health, medical, fitness, pharmacy, subscription, streaming, software, memberships, education, courses, books, tuition, other

Transcript: "${transcript}"

Return JSON array with this structure:
[{
  "amount": number,
  "currency": "TWD",
  "category": "string",
  "merchant": "string",
  "description": "string",
  "confidence": number (0-1),
  "tags": ["string"]
}]`;

  const message = await anthropic.messages.create({
    model: "claude-3-5-sonnet-20241022",
    max_tokens: 1024,
    messages: [
      {
        role: "user",
        content: prompt,
      },
    ],
  });

  const content = message.content[0];
  if (content.type !== "text") {
    throw new Error("Unexpected response type from Claude");
  }

  // Extract JSON from response
  const json_match = content.text.match(/\[[\s\S]*\]/);
  if (!json_match) {
    throw new Error("Could not extract JSON from response");
  }

  const parsed_entries = JSON.parse(json_match[0]);
  const sentence_count = transcript.split(/[。！？]/g).length;
  const split_ratio =
    parsed_entries.length > 1 ? parsed_entries.length / sentence_count : 1.0;

  return {
    entries: parsed_entries,
    sentence_count,
    split_ratio: Math.min(split_ratio, 1.0),
  };
}

function generate_uuid(): string {
  return crypto.randomUUID();
}

function categorize_merchant(merchant: string): string {
  const merchant_lower = merchant.toLowerCase();

  // Food & Dining
  if (
    merchant_lower.match(
      /coffee|cafe|咖啡|便當|食堂|餐廳|飯館|麵店|日式|中式|牛肉|海鮮|火鍋/
    )
  ) {
    return "dining_out";
  }
  if (
    merchant_lower.match(
      /超市|超商|7-eleven|全家|ok便利|costco|量販|菜市場|果菜市場/
    )
  ) {
    return "groceries";
  }

  // Transport
  if (
    merchant_lower.match(
      /uber|taxi|計程車|悠遊卡|一卡通|台北公運|高鐵|台鐵|捷運/
    )
  ) {
    return "transport";
  }

  // Entertainment
  if (merchant_lower.match(/電影|Netflix|Disney|kktv|院線|演唱會|ktv/)) {
    return "entertainment";
  }

  // Shopping
  if (merchant_lower.match(/momo|pchome|uniqlo|h&m|zara|屈臣氏|cosmax/)) {
    return "shopping";
  }

  // Utilities & Subscriptions
  if (
    merchant_lower.match(
      /中華電信|台灣大哥大|遠傳|亞太|電力公司|水務|網際網路/
    )
  ) {
    return "utilities";
  }

  // Health
  if (merchant_lower.match(/醫院|診所|藥房|藥局|健身房|瑜珈/)) {
    return "health";
  }

  return "other";
}

function estimate_timestamp(
  base_timestamp: string,
  description: string
): string {
  // Try to extract time from description
  const time_match = description.match(/(\d{1,2})[:|時](\d{1,2})/);

  if (!time_match) {
    return base_timestamp; // Use original timestamp
  }

  const hour = parseInt(time_match[1]);
  const minute = parseInt(time_match[2]);

  const base_date = new Date(base_timestamp);
  base_date.setHours(hour, minute, 0, 0);

  return base_date.toISOString();
}

async function store_entries(
  user_id: string,
  entries: ParsedEntry[]
): Promise<void> {
  const { error } = await supabase.from("transactions").insert(
    entries.map((entry) => ({
      user_id,
      amount: entry.amount,
      currency: entry.currency,
      category: entry.category,
      merchant: entry.merchant,
      description: entry.description,
      timestamp: entry.timestamp,
      source: entry.source,
      confidence: entry.confidence,
      tags: entry.tags,
      status: "confirmed",
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    }))
  );

  if (error) {
    throw new Error(`Database insert failed: ${error.message}`);
  }
}

serve(async (req: Request) => {
  const start_time = performance.now();

  // CORS
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
          code: "INVALID_AUTH",
        }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      );
    }

    const token = auth_header.slice(7);

    // Verify JWT and get user
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
          code: "INVALID_TOKEN",
        }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      );
    }

    const user_id = user.id;

    // Parse request body
    const body: VoiceEntryRequest = await req.json();

    // Validate input
    if (!body.transcript || body.transcript.trim().length === 0) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "INVALID_INPUT",
          message: "Transcript is empty or too short",
          code: "EMPTY_TRANSCRIPT",
        }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    if (body.transcript.length > 1000) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "INVALID_INPUT",
          message: "Transcript is too long (max 1000 characters)",
          code: "TRANSCRIPT_TOO_LONG",
        }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const language = body.metadata?.language || "zh-TW";
    const base_timestamp = body.timestamp || new Date().toISOString();

    // Parse with Claude
    const parse_result = await parse_voice_transcript(
      body.transcript,
      language
    );

    // Transform parsed entries
    const entries: ParsedEntry[] = parse_result.entries.map((entry) => ({
      id: generate_uuid(),
      amount: entry.amount,
      currency: entry.currency,
      category: entry.category,
      merchant:
        entry.merchant ||
        categorize_merchant(entry.merchant || entry.description),
      description: entry.description,
      timestamp: estimate_timestamp(base_timestamp, entry.description),
      source: "voice",
      confidence: entry.confidence,
      tags: entry.tags || [],
    }));

    // Store in database
    await store_entries(user_id, entries);

    const processing_time = performance.now() - start_time;

    const response: VoiceEntryResponse = {
      success: true,
      entries,
      parsing_details: {
        sentence_count: parse_result.sentence_count,
        split_ratio: parse_result.split_ratio,
        model_used: "claude-3-5-sonnet",
        processing_time_ms: Math.round(processing_time),
      },
    };

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
    console.error("Error in voice-entry function:", error);

    const response: VoiceEntryResponse = {
      success: false,
      error: "PARSE_ERROR",
      message: error instanceof Error ? error.message : "Unknown error",
      code: "PROCESSING_FAILED",
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
