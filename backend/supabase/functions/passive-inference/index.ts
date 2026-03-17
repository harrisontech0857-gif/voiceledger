import { serve } from "https://deno.land/std@0.192.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.0";
import { Anthropic } from "https://esm.sh/@anthropic-ai/sdk@0.10.0";

interface GPSSource {
  type: "gps";
  latitude: number;
  longitude: number;
  accuracy_m: number;
  timestamp: string;
}

interface NotificationSource {
  type: "notification";
  text: string;
  app: string;
  timestamp: string;
}

interface PhotoSource {
  type: "photo";
  image_base64: string;
  timestamp: string;
}

type DataSource = GPSSource | NotificationSource | PhotoSource;

interface PassiveInferenceRequest {
  sources: DataSource[];
  metadata: {
    device_id: string;
  };
}

interface LocationMatch {
  name: string;
  category: string;
  coordinates: {
    lat: number;
    lng: number;
  };
  distance_m: number;
  match_score: number;
}

interface InferredEntry {
  id: string;
  amount: number;
  currency: string;
  category: string;
  merchant: string;
  description: string;
  timestamp: string;
  source: string;
  confidence: number;
  confidence_breakdown: {
    location_match: number;
    notification_match: number;
    image_recognition: number;
  };
  evidence: string[];
  requires_confirmation: boolean;
  user_action: string;
}

interface PassiveInferenceResponse {
  success: boolean;
  inferred_entry?: InferredEntry;
  inference_details?: {
    processing_time_ms: number;
    models_used: string[];
  };
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

function generate_uuid(): string {
  return crypto.randomUUID();
}

// Haversine formula to calculate distance between two coordinates
function calculate_distance(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number
): number {
  const R = 6371000; // Earth radius in meters
  const phi1 = (lat1 * Math.PI) / 180;
  const phi2 = (lat2 * Math.PI) / 180;
  const delta_phi = ((lat2 - lat1) * Math.PI) / 180;
  const delta_lambda = ((lng2 - lng1) * Math.PI) / 180;

  const a =
    Math.sin(delta_phi / 2) * Math.sin(delta_phi / 2) +
    Math.cos(phi1) *
      Math.cos(phi2) *
      Math.sin(delta_lambda / 2) *
      Math.sin(delta_lambda / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c;
}

async function extract_notification_data(
  notification_text: string
): Promise<{
  amount: number | null;
  merchant: string | null;
  confidence: number;
}> {
  // Extract amount (supports TWD, USD, etc.)
  const amount_match = notification_text.match(/[\$￥NT\$]\s*(\d+(?:[.,]\d+)?)/);
  const amount = amount_match ? parseFloat(amount_match[1].replace(/,/g, "")) : null;

  // Try to extract merchant/store name
  const merchant_patterns = [
    /(?:在|at|@)\s*([^金額消費]*)/,
    /店(?:\s*|：)([^金額]*)/,
    /([A-Z][A-Z0-9\s]*(?:SHOP|STORE))/,
    /([0-9]{1,2}-ELEVEN|全家|OK便利|FamilyMart)/,
  ];

  let merchant: string | null = null;
  for (const pattern of merchant_patterns) {
    const match = notification_text.match(pattern);
    if (match) {
      merchant = match[1].trim();
      break;
    }
  }

  const confidence = (amount ? 0.6 : 0.3) + (merchant ? 0.35 : 0);

  return {
    amount,
    merchant,
    confidence: Math.min(confidence, 0.95),
  };
}

async function match_nearby_locations(
  latitude: number,
  longitude: number,
  accuracy_m: number
): Promise<LocationMatch[]> {
  // In production, query against Google Places API or local business database
  // For now, return mock data based on common locations in Taipei
  const common_locations = [
    {
      name: "7-ELEVEN",
      category: "convenience_store",
      coordinates: { lat: 25.033, lng: 121.5654 },
    },
    {
      name: "全家便利商店",
      category: "convenience_store",
      coordinates: { lat: 25.0331, lng: 121.5655 },
    },
    {
      name: "星巴克咖啡",
      category: "cafe",
      coordinates: { lat: 25.0329, lng: 121.5653 },
    },
    {
      name: "頂好超市",
      category: "supermarket",
      coordinates: { lat: 25.0332, lng: 121.5656 },
    },
  ];

  const matches = common_locations
    .map((loc) => ({
      ...loc,
      distance_m: calculate_distance(
        latitude,
        longitude,
        loc.coordinates.lat,
        loc.coordinates.lng
      ),
      match_score: 0,
    }))
    .filter((loc) => loc.distance_m < accuracy_m * 5) // Within reasonable range
    .map((loc) => ({
      ...loc,
      match_score: Math.max(0, 1 - loc.distance_m / (accuracy_m * 5)),
    }))
    .sort((a, b) => b.match_score - a.match_score)
    .slice(0, 3);

  return matches;
}

// 本地圖像分析備選方案 - 使用規則匹配而不需要 AI API
function analyze_transaction_image_local(): Promise<{
  merchant: string | null;
  category: string | null;
  confidence: number;
  description: string;
}> {
  return Promise.resolve({
    merchant: null,
    category: null,
    confidence: 0.3,
    description: "圖像分析需要啟用 ENABLE_AI_API",
  });
}

async function analyze_transaction_image(
  image_base64: string
): Promise<{
  merchant: string | null;
  category: string | null;
  confidence: number;
  description: string;
}> {
  // 如果 AI API 未啟用，使用本地備選方案
  if (!enableAiApi || !anthropic) {
    console.log("ENABLE_AI_API is false, using local fallback");
    return analyze_transaction_image_local();
  }

  // 使用 Claude 的視覺 API
  try {
    const message = await anthropic!.messages.create({
      model: "claude-3-5-sonnet-20241022",
      max_tokens: 256,
      messages: [
        {
          role: "user",
          content: [
            {
              type: "image",
              source: {
                type: "base64",
                media_type: "image/jpeg",
                data: image_base64,
              },
            },
            {
              type: "text",
              text: 'Analyze this receipt/store image. Extract: merchant name, category (food/shopping/transport/etc), estimated amount if visible, and description. Return as JSON: {"merchant": "", "category": "", "amount": null, "description": "", "confidence": 0.0}',
            },
          ],
        },
      ],
    });

    const content = message.content[0];
    if (content.type !== "text") {
      return {
        merchant: null,
        category: null,
        confidence: 0,
        description: "Unable to analyze image",
      };
    }

    const json_match = content.text.match(/\{[\s\S]*\}/);
    if (json_match) {
      return JSON.parse(json_match[0]);
    }

    return {
      merchant: null,
      category: null,
      confidence: 0,
      description: "Unable to parse image analysis",
    };
  } catch (error) {
    console.error("Image analysis error:", error);
    return {
      merchant: null,
      category: null,
      confidence: 0,
      description: "Image analysis failed",
    };
  }
}

async function infer_transaction(
  gps_source: GPSSource | null,
  notification_source: NotificationSource | null,
  photo_source: PhotoSource | null
): Promise<InferredEntry> {
  const confidences = {
    location_match: 0,
    notification_match: 0,
    image_recognition: 0,
  };
  const evidence: string[] = [];

  let merchant = "Unknown";
  let amount = 0;
  let category = "other";
  let description = "Transaction";

  const timestamp = notification_source?.timestamp ||
    photo_source?.timestamp ||
    gps_source?.timestamp ||
    new Date().toISOString();

  // 1. Process GPS data
  if (gps_source) {
    const location_matches = await match_nearby_locations(
      gps_source.latitude,
      gps_source.longitude,
      gps_source.accuracy_m
    );

    if (location_matches.length > 0) {
      const top_match = location_matches[0];
      confidences.location_match = top_match.match_score * 0.92;
      merchant = top_match.name;
      category = top_match.category;
      evidence.push(
        `GPS 定位在 ${top_match.name} 店家 (距離 ${Math.round(top_match.distance_m)}m)`
      );
    }
  }

  // 2. Process notification data
  if (notification_source) {
    const notification_analysis = await extract_notification_data(
      notification_source.text
    );

    if (notification_analysis.amount) {
      amount = notification_analysis.amount;
      confidences.notification_match = 0.95;
      evidence.push(`銀行通知金額 $${amount}`);
    }

    if (notification_analysis.merchant && !merchant) {
      merchant = notification_analysis.merchant;
      evidence.push(`通知商家名稱: ${merchant}`);
    }
  }

  // 3. Process photo data
  if (photo_source) {
    const image_analysis = await analyze_transaction_image(
      photo_source.image_base64
    );

    if (image_analysis.confidence > 0.5) {
      confidences.image_recognition = image_analysis.confidence;
      if (image_analysis.merchant && !merchant) {
        merchant = image_analysis.merchant;
      }
      if (image_analysis.category && category === "other") {
        category = image_analysis.category;
      }
      if (image_analysis.amount && !amount) {
        amount = image_analysis.amount;
      }
      evidence.push(`照片識別: ${image_analysis.description}`);
    }
  }

  // Calculate overall confidence
  const avg_confidence = (
    confidences.location_match +
    confidences.notification_match +
    confidences.image_recognition
  ) / 3;

  return {
    id: generate_uuid(),
    amount: Math.round(amount),
    currency: "TWD",
    category,
    merchant,
    description: description,
    timestamp,
    source: "passive",
    confidence: avg_confidence,
    confidence_breakdown: confidences,
    evidence,
    requires_confirmation: avg_confidence < 0.8,
    user_action: "pending",
  };
}

async function store_inferred_entry(
  user_id: string,
  entry: InferredEntry
): Promise<void> {
  const { error } = await supabase.from("transactions").insert([
    {
      user_id,
      amount: entry.amount,
      currency: entry.currency,
      transaction_type: "expense",
      category: entry.category,
      merchant_name: entry.merchant,
      notes: entry.description,
      transaction_date: entry.timestamp.split("T")[0],
      transaction_time: entry.timestamp.split("T")[1]?.split("+")[0] || null,
      source_type: "notification",
      source_detail: {
        confidence_breakdown: entry.confidence_breakdown,
        evidence: entry.evidence,
      },
      confidence_score: entry.confidence,
      is_verified: !entry.requires_confirmation,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    },
  ]);

  if (error) {
    throw new Error(`Database insert failed: ${error.message}`);
  }
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
    const body: PassiveInferenceRequest = await req.json();

    // Validate sources
    if (!body.sources || body.sources.length === 0) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "INVALID_INPUT",
          message: "No data sources provided",
        }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Extract different source types
    const gps_source = body.sources.find(
      (s): s is GPSSource => s.type === "gps"
    );
    const notification_source = body.sources.find(
      (s): s is NotificationSource => s.type === "notification"
    );
    const photo_source = body.sources.find(
      (s): s is PhotoSource => s.type === "photo"
    );

    // Perform inference
    const inferred_entry = await infer_transaction(
      gps_source || null,
      notification_source || null,
      photo_source || null
    );

    // Store in database
    await store_inferred_entry(user_id, inferred_entry);

    const processing_time = performance.now() - start_time;
    const status_code = inferred_entry.confidence >= 0.8 ? 200 : 202;

    const response: PassiveInferenceResponse = {
      success: true,
      inferred_entry,
      inference_details: {
        processing_time_ms: Math.round(processing_time),
        models_used: [
          "vision",
          "location_matcher",
          "classifier",
          "confidence_scorer",
        ],
      },
    };

    return new Response(JSON.stringify(response), {
      status: status_code,
      headers: {
        "Content-Type": "application/json",
        "X-Request-Id": generate_uuid(),
        "X-Processing-Time": `${Math.round(processing_time)}ms`,
        "Access-Control-Allow-Origin": "*",
      },
    });
  } catch (error) {
    console.error("Error in passive-inference function:", error);

    const response: PassiveInferenceResponse = {
      success: false,
      error: "INFERENCE_ERROR",
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
