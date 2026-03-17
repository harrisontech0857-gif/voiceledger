# VoiceLedger API 端點設計文件

## 概述

VoiceLedger 是 AI 財務秘書應用，提供完整的記帳、分析和對話功能。所有 API 端點透過 Supabase Edge Functions 實現，使用 TypeScript/Deno 開發。

**Base URL**: `https://<project-id>.supabase.co/functions/v1`

**認證**: Bearer Token (JWT from Supabase Auth)

---

## 1. 語音記帳 API

### 1.1 提交語音記帳
**端點**: `POST /voice-entry`

**功能**: 接收 Whisper 轉錄文字，進行語意解析、自動分類、多筆拆分

**請求頭**:
```
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

**請求體**:
```json
{
  "transcript": "早上買咖啡五十塊，下午超市買菜三百二十塊",
  "audio_duration_ms": 5000,
  "timestamp": "2026-03-18T09:30:00Z",
  "metadata": {
    "device_id": "uuid",
    "language": "zh-TW"
  }
}
```

**回應 (200 OK)**:
```json
{
  "success": true,
  "entries": [
    {
      "id": "uuid",
      "amount": 50,
      "currency": "TWD",
      "category": "food",
      "merchant": "coffee_shop",
      "description": "早上買咖啡",
      "timestamp": "2026-03-18T09:30:00Z",
      "source": "voice",
      "confidence": 0.95,
      "tags": ["飲料", "早餐"]
    },
    {
      "id": "uuid",
      "amount": 320,
      "currency": "TWD",
      "category": "groceries",
      "merchant": "supermarket",
      "description": "超市買菜",
      "timestamp": "2026-03-18T15:00:00Z",
      "source": "voice",
      "confidence": 0.92,
      "tags": ["食材"]
    }
  ],
  "parsing_details": {
    "sentence_count": 2,
    "split_ratio": 0.85,
    "model_used": "claude-3-5-sonnet",
    "processing_time_ms": 1240
  }
}
```

**錯誤回應 (400 Bad Request)**:
```json
{
  "success": false,
  "error": "invalid_transcript",
  "message": "Transcript is empty or too short",
  "code": "INVALID_INPUT"
}
```

**錯誤碼**:
- `INVALID_INPUT`: 輸入格式錯誤
- `PARSE_ERROR`: LLM 解析失敗
- `DB_ERROR`: 資料庫儲存失敗
- `AUTH_ERROR`: 認證失敗

---

## 2. 被動記帳推理 API

### 2.1 提交多模態線索
**端點**: `POST /passive-inference`

**功能**: 接收 GPS、照片、通知線索，計算信心分數，產生待確認記錄

**請求體**:
```json
{
  "sources": [
    {
      "type": "gps",
      "latitude": 25.0330,
      "longitude": 121.5654,
      "accuracy_m": 15,
      "timestamp": "2026-03-18T14:22:00Z"
    },
    {
      "type": "notification",
      "text": "SHOP: 7-ELEVEN 超商 金額 $48",
      "app": "bank",
      "timestamp": "2026-03-18T14:23:00Z"
    },
    {
      "type": "photo",
      "image_base64": "iVBORw0KGgoAAAANS...",
      "timestamp": "2026-03-18T14:21:00Z"
    }
  ],
  "metadata": {
    "device_id": "uuid"
  }
}
```

**回應 (200 OK)**:
```json
{
  "success": true,
  "inferred_entry": {
    "id": "uuid",
    "amount": 48,
    "currency": "TWD",
    "category": "convenience_store",
    "merchant": "7-eleven",
    "description": "超商消費",
    "timestamp": "2026-03-18T14:23:00Z",
    "source": "passive",
    "confidence": 0.87,
    "confidence_breakdown": {
      "location_match": 0.92,
      "notification_match": 0.95,
      "image_recognition": 0.65
    },
    "evidence": [
      "GPS 定位在 7-ELEVEN 店家",
      "銀行通知金額 $48",
      "照片顯示店內環境"
    ],
    "requires_confirmation": true,
    "user_action": "pending"
  },
  "inference_details": {
    "processing_time_ms": 2150,
    "models_used": ["vision", "location_matcher", "classifier"]
  }
}
```

**低信心回應 (202 Accepted)**:
```json
{
  "success": true,
  "inferred_entry": {
    "confidence": 0.52,
    "requires_confirmation": true,
    "note": "信心分數低，需要用戶確認"
  }
}
```

---

## 3. AI 對話 API

### 3.1 發送對話消息
**端點**: `POST /ai-chat`

**功能**: 處理自然語言查詢，執行 Text-to-SQL，回應用戶問題

**請求體**:
```json
{
  "message": "上個月我在食物上花了多少錢？",
  "session_id": "uuid",
  "context": {
    "user_timezone": "Asia/Taipei",
    "conversation_history": [
      {
        "role": "user",
        "content": "最近消費狀況"
      },
      {
        "role": "assistant",
        "content": "根據最近 7 天的數據..."
      }
    ]
  }
}
```

**回應 (200 OK)**:
```json
{
  "success": true,
  "response": {
    "message": "根據您的記錄，上個月在食物上花費 NT$4,850，平均每天約 $157。其中外食 $2,100，自煮 $2,750。",
    "data": {
      "total_amount": 4850,
      "category": "food",
      "period": "2026-02-18 to 2026-03-18",
      "breakdown": {
        "dining_out": 2100,
        "groceries": 2750
      },
      "daily_average": 157
    },
    "query_type": "category_summary",
    "sql_executed": "SELECT SUM(amount) FROM transactions WHERE category = 'food' AND date BETWEEN ...",
    "confidence": 0.93
  },
  "processing_details": {
    "parsing_time_ms": 340,
    "query_time_ms": 120,
    "total_time_ms": 460
  }
}
```

**對話類型支援**:
- `balance_query`: 餘額查詢
- `category_summary`: 分類統計
- `trend_analysis`: 趨勢分析
- `budget_check`: 預算檢查
- `comparison`: 時期對比
- `anomaly_detection`: 異常偵測
- `recommendation`: 理財建議

---

## 4. 每日金句生成 API

### 4.1 生成當日金句
**端點**: `GET /daily-wisdom`

**功能**: 根據用戶消費數據生成個人化金句

**查詢參數**:
```
?user_id=<uuid>
?date=2026-03-18 (可選，預設今日)
&tone=encouraging|cautious|analytical (可選，預設 encouraging)
```

**回應 (200 OK)**:
```json
{
  "success": true,
  "wisdom": {
    "quote": "您最近減少了衝動消費，這是理智的選擇。每一分錢的節制，都是未來財富的種子。",
    "tone": "encouraging",
    "data_insight": {
      "period": "last_7_days",
      "total_spending": 3420,
      "spending_trend": "decreasing",
      "biggest_category": "food",
      "interesting_pattern": "weekday_vs_weekend_ratio: 1.2"
    },
    "actionable_tip": "您在週末的消費比平日高 20%，試試制定週末預算計畫？",
    "generated_at": "2026-03-18T08:00:00Z",
    "expires_at": "2026-03-19T08:00:00Z"
  },
  "history": [
    {
      "date": "2026-03-17",
      "quote": "..."
    }
  ]
}
```

---

## 5. 生活日記生成 API

### 5.1 生成日記摘要
**端點**: `GET /life-diary`

**功能**: 將每日交易轉化為生活日記摘要

**查詢參數**:
```
?date=2026-03-18 (可選)
&style=narrative|report|poetic (可選，預設 narrative)
```

**回應 (200 OK)**:
```json
{
  "success": true,
  "diary": {
    "date": "2026-03-18",
    "title": "平凡而充實的一天",
    "summary": "早上搭車前往辦公室，在超商買了咖啡開始一天的工作。午餐與同事在公司附近便當店吃飯，下午下班後去超市採購一週的食材。晚上在家煮飯，過著簡樸而有規律的生活。",
    "narrative": {
      "morning": {
        "entries": ["咖啡 $50"],
        "mood": "清醒",
        "summary": "清晨的咖啡喚醒一天"
      },
      "afternoon": {
        "entries": ["午餐 $110"],
        "mood": "忙碌",
        "summary": "與同事共進午餐，分享工作進展"
      },
      "evening": {
        "entries": ["食材 $320"],
        "mood": "充實",
        "summary": "採購食材，為週末的料理做準備"
      }
    },
    "financial_snapshot": {
      "total_spent": 480,
      "categories": {
        "dining": 160,
        "groceries": 320
      },
      "mood_and_spending": "今天的消費反映了規律而節制的生活方式"
    },
    "daily_insight": "您的消費習慣表現出務實和計畫性，這是培養良好財務習慣的基石。",
    "style": "narrative"
  }
}
```

---

## 6. AI 秘書對話 API

### 6.1 秘書會話端點
**端點**: `POST /secretary-chat`

**功能**: 情境式對話，理解用戶情緒和需求

**請求體**:
```json
{
  "message": "最近工作太累了，感覺在亂花錢",
  "session_id": "uuid",
  "emotion_context": {
    "detected_emotion": "stressed",
    "stress_level": 7
  },
  "persona_config": {
    "tone": "supportive",
    "language": "zh-TW",
    "use_humor": true
  }
}
```

**回應 (200 OK)**:
```json
{
  "success": true,
  "response": {
    "message": "我聽到您最近有些疲憊。工作壓力下的消費確實容易失控，但您意識到這一點已經是很好的開始了。\n\n我剛好看到您這週的咖啡支出比平時多 30%——這很正常，當我們需要額外能量時。與其自責，不如我們一起看看：\n\n1️⃣ 這週是否有特別忙碌的專案？\n2️⃣ 您的理想預算範圍是多少？\n\n有時候，給自己一點寬容反而能更快走出壓力迴圈。",
    "emotional_awareness": {
      "detected_emotion": "stressed",
      "empathy_score": 0.92,
      "personalized": true
    },
    "recommendations": [
      {
        "type": "budget_adjustment",
        "content": "考慮為'自我照顧'分類設立彈性預算，允許適度的壓力消費"
      },
      {
        "type": "lifestyle_tip",
        "content": "定期休息能減少衝動消費。您下一個休假日是？"
      }
    ],
    "follow_up_questions": [
      "工作最忙的時期通常是什麼時候？",
      "您有固定的放鬆活動嗎？"
    ]
  },
  "session_info": {
    "session_id": "uuid",
    "conversation_turn": 5,
    "context_retained": true
  }
}
```

---

## 7. 統計分析 API

### 7.1 消費趨勢分析
**端點**: `GET /analytics/trends`

**查詢參數**:
```
?period=7d|30d|90d|1y
&group_by=daily|weekly|monthly
&category=all|food|transport|... (可選)
```

**回應 (200 OK)**:
```json
{
  "success": true,
  "trends": {
    "period": "30d",
    "total_spending": 12450,
    "daily_average": 415,
    "trend_direction": "decreasing",
    "trend_percentage": -8.5,
    "data": [
      {
        "date": "2026-03-18",
        "amount": 480,
        "category_breakdown": {
          "food": 350,
          "transport": 50,
          "entertainment": 80
        }
      }
    ],
    "category_distribution": {
      "food": {
        "amount": 5200,
        "percentage": 41.7,
        "trend": "stable"
      },
      "transport": {
        "amount": 1850,
        "percentage": 14.8,
        "trend": "increasing"
      }
    },
    "insights": [
      "食物支出佔比最高，但本月有所控制",
      "交通費上升 12%，可能與工作地點改變有關"
    ]
  }
}
```

### 7.2 預算追蹤
**端點**: `GET /analytics/budget`

**回應 (200 OK)**:
```json
{
  "success": true,
  "budgets": [
    {
      "category": "food",
      "monthly_limit": 5000,
      "spent": 4200,
      "remaining": 800,
      "percentage_used": 84,
      "status": "on_track",
      "days_left": 13
    },
    {
      "category": "transport",
      "monthly_limit": 2000,
      "spent": 1850,
      "remaining": 150,
      "percentage_used": 92.5,
      "status": "at_risk",
      "days_left": 13,
      "alert": "即將超過預算"
    }
  ],
  "total_budget": 12000,
  "total_spent": 10250,
  "overall_status": "on_track"
}
```

### 7.3 異常偵測
**端點**: `GET /analytics/anomalies`

**回應 (200 OK)**:
```json
{
  "success": true,
  "anomalies": [
    {
      "id": "uuid",
      "type": "spending_spike",
      "date": "2026-03-15",
      "amount": 2500,
      "category": "entertainment",
      "severity": "high",
      "description": "異常高的娛樂支出，比平時高 3 倍",
      "reason": "可能是朋友聚餐或特殊活動",
      "requires_review": true
    },
    {
      "id": "uuid",
      "type": "unusual_merchant",
      "date": "2026-03-16",
      "amount": 450,
      "merchant": "online_course_platform",
      "severity": "medium",
      "description": "新的消費類別",
      "reason": "首次在此商家消費",
      "requires_review": false
    }
  ],
  "anomaly_count": 2,
  "reviewed_count": 1
}
```

---

## 8. 訂閱管理 API

### 8.1 RevenueCat Webhook
**端點**: `POST /webhooks/revenucat`

**功能**: 接收並處理 RevenueCat 訂閱事件

**Webhook 簽名驗證**: 使用 RevenueCat 提供的簽名密鑰

**事件體** (Example: subscription_started):
```json
{
  "event": {
    "type": "subscription_started",
    "timestamp": "2026-03-18T10:30:00Z"
  },
  "subscriber": {
    "app_user_id": "user_123",
    "email": "user@example.com"
  },
  "product": {
    "entitlement_id": "premium",
    "product_id": "com.voiceledger.premium.month",
    "duration": "monthly"
  },
  "purchase": {
    "price": 4.99,
    "currency": "TWD",
    "period": "1 month"
  }
}
```

**回應 (200 OK)**:
```json
{
  "success": true,
  "action": "subscription_activated",
  "user_id": "uuid",
  "entitlements": [
    "unlimited_voice_entries",
    "advanced_analytics",
    "ai_secretary"
  ],
  "expires_at": "2026-04-18T10:30:00Z"
}
```

### 8.2 驗證訂閱狀態
**端點**: `GET /subscriptions/status`

**回應 (200 OK)**:
```json
{
  "success": true,
  "subscription": {
    "user_id": "uuid",
    "plan": "premium",
    "status": "active",
    "started_at": "2026-02-18T10:30:00Z",
    "expires_at": "2026-04-18T10:30:00Z",
    "auto_renew": true,
    "entitlements": [
      "unlimited_voice_entries",
      "advanced_analytics",
      "ai_secretary",
      "custom_budget"
    ]
  }
}
```

### 8.3 取消訂閱
**端點**: `POST /subscriptions/cancel`

**請求體**:
```json
{
  "reason": "user_requested",
  "feedback": "太貴了"
}
```

**回應 (200 OK)**:
```json
{
  "success": true,
  "status": "cancelled",
  "effective_date": "2026-04-18T10:30:00Z",
  "refund_eligible": false
}
```

---

## 數據模型

### Transaction
```
{
  id: uuid
  user_id: uuid
  amount: number (TWD)
  currency: string (ISO 4217)
  category: string (enum)
  subcategory: string
  merchant: string
  description: string
  timestamp: timestamp with tz
  source: 'voice' | 'passive' | 'manual' | 'import'
  confidence: number (0-1)
  tags: array of string
  notes: text
  receipt_image_url: string (optional)
  location: point (lat, lng)
  status: 'confirmed' | 'pending' | 'flagged'
  created_at: timestamp with tz
  updated_at: timestamp with tz
}
```

### Entry Category Enum
```
food
- dining_out
- groceries
- food_delivery

transport
- taxi
- public_transit
- car_maintenance
- fuel

entertainment
- movies
- games
- sports
- events

shopping
- clothing
- electronics
- home
- beauty

utilities
- electricity
- water
- internet
- phone

health
- medical
- fitness
- pharmacy

subscription
- streaming
- software
- memberships

education
- courses
- books
- tuition

other
```

---

## 錯誤處理標準

所有端點遵循統一的錯誤格式：

```json
{
  "success": false,
  "error": "<error_code>",
  "message": "<human_readable_message>",
  "code": 400,
  "details": {
    "field": "value",
    "error_subtype": "detailed_reason"
  }
}
```

### HTTP 狀態碼對應
| 狀態碼 | 含義 |
|------|------|
| 200 | 成功 |
| 202 | 已接受，正在處理 |
| 400 | 請求錯誤 |
| 401 | 未認證 |
| 403 | 無權限 |
| 404 | 資源不存在 |
| 409 | 衝突（重複提交等） |
| 429 | 請求過於頻繁 |
| 500 | 伺服器錯誤 |

---

## 速率限制

- **標準使用者**: 100 requests/minute
- **Premium 使用者**: 500 requests/minute
- **語音記帳**: 無限制（每日交易計數）
- **AI 對話**: 50 requests/minute
- **WebHook**: 10,000/day

---

## 認證與授權

### JWT Claims
```
{
  "sub": "user_id",
  "aud": "voiceledger",
  "role": "authenticated" | "admin",
  "subscription_tier": "free" | "premium" | "plus",
  "exp": 1234567890
}
```

### 必需的授權級別
- **public**: 無需認證 (404 會回傳)
- **user**: 需要有效 JWT
- **premium**: 需要 premium 訂閱
- **admin**: 管理員權限

---

## API 版本化

目前 API 版本: `v1`

未來版本計畫:
- `v2`: 新增 real-time WebSocket 支持
- `v3`: 新增多帳戶支持

舊版本 sunset policy: 發佈新版本後 6 個月內支持舊版本。

---

## 監測與日誌

所有端點返回 `X-Request-Id` 標頭用於追蹤：

```
X-Request-Id: uuid
X-Processing-Time: 1234ms
X-Model-Used: claude-3-5-sonnet
```

---

## 範例集成流程

### 完整語音記帳流程
1. 用戶說話 → 前端捕獲音頻
2. 前端送往 Whisper API 獲得文字轉錄
3. 前端調用 `POST /voice-entry` 並提交轉錄
4. 後端返回已解析的交易列表（可能多筆）
5. 用戶確認或編輯後，保存到資料庫
6. 后台自動觸發 `PUT /transactions/{id}/confirm`

### 被動記帳流程
1. 手機後台收集 GPS、通知、照片信號
2. 定期（每 5 分鐘）調用 `POST /passive-inference`
3. 如果信心度 > 0.8，自動加入待確認列表
4. 用戶在「確認待審」界面審核
5. 點擊確認時調用 `POST /transactions/{id}/confirm`

### AI 對話流程
1. 用戶在聊天界面輸入問題
2. 前端調用 `POST /ai-chat` 並帶上會話歷史
3. 後端執行 Text-to-SQL 查詢並調用 LLM
4. 返回自然語言回應 + 數據圖表
5. 前端渲染結果

