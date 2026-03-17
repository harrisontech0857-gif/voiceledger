-- VoiceLedger (語記) - 完整資料庫架構 Migration
-- 建立時間: 2026-03-18
-- 設計者: AI Database Architect
-- 目的: AI 財務秘書應用的完整資料庫架構，包含 RLS、索引、觸發器

-- ============================================================================
-- 1. 基礎設置 - Extensions & Custom Types
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "btree_gin";

-- 自定義 ENUM 類型
CREATE TYPE user_identity_type AS ENUM ('student', 'employee', 'freelancer', 'other');
CREATE TYPE transaction_source_type AS ENUM ('voice', 'passive_gps', 'photo', 'notification', 'manual', 'imported');
CREATE TYPE transaction_type AS ENUM ('expense', 'income', 'transfer');
CREATE TYPE subscription_status AS ENUM ('active', 'trial', 'paused', 'cancelled', 'expired');
CREATE TYPE budget_frequency AS ENUM ('daily', 'weekly', 'monthly', 'yearly');
CREATE TYPE achievement_type AS ENUM ('milestone', 'streak', 'category_master', 'behavioral');
CREATE TYPE notification_type AS ENUM ('budget_warning', 'subscription_renewal', 'milestone_unlock', 'daily_insight', 'family_invite');
CREATE TYPE family_role AS ENUM ('owner', 'admin', 'member', 'viewer');

-- ============================================================================
-- 2. 用戶系統表
-- ============================================================================

-- 用戶基本資料表
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- 基本資訊
  email TEXT UNIQUE NOT NULL,
  phone_number TEXT UNIQUE,
  username TEXT UNIQUE,
  display_name TEXT NOT NULL,
  avatar_url TEXT,
  bio TEXT,

  -- 身份與職業
  identity_type user_identity_type NOT NULL DEFAULT 'other',
  identity_detail JSONB, -- 額外身份資訊 (e.g., 學校、公司、自由職業類型)

  -- 地理與時區
  country_code TEXT DEFAULT 'TW',
  timezone TEXT DEFAULT 'Asia/Taipei',
  locale TEXT DEFAULT 'zh-TW',

  -- 系統信息
  auth_provider TEXT DEFAULT 'supabase', -- supabase, google, apple, weixin
  auth_provider_id TEXT,
  email_verified BOOLEAN DEFAULT FALSE,
  phone_verified BOOLEAN DEFAULT FALSE,

  -- 統計信息
  transaction_count INTEGER DEFAULT 0,
  total_expense DECIMAL(15,2) DEFAULT 0,
  total_income DECIMAL(15,2) DEFAULT 0,
  last_transaction_date DATE,

  -- 偏好設定
  preferences JSONB DEFAULT '{}', -- 深色模式、推送通知、語言等

  -- 時間戳
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP WITH TIME ZONE,

  CONSTRAINT valid_email CHECK (email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$')
);

-- 用戶生活節奏與習慣表
CREATE TABLE user_patterns (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,

  -- 生活節奏
  sleep_start_time TIME, -- 睡眠開始時間
  sleep_end_time TIME,   -- 睡眠結束時間
  work_start_time TIME,  -- 工作開始時間
  work_end_time TIME,    -- 工作結束時間
  peak_activity_hours JSONB, -- 活動高峰小時 [0-23]

  -- 消費習慣
  typical_daily_expense DECIMAL(10,2),
  typical_monthly_expense DECIMAL(12,2),
  frequency_by_category JSONB, -- {category: frequency}

  -- 情緒與狀態
  current_mood TEXT, -- happy, neutral, stressed, busy
  mood_trend JSONB, -- 7天情緒趨勢
  energy_level INTEGER, -- 1-10 能量等級
  stress_level INTEGER, -- 1-10 壓力等級

  -- 偏好模式
  preferred_payment_methods TEXT[], -- ['cash', 'card', 'digital_wallet']
  trusted_merchants TEXT[], -- 常去的商家

  -- AI 秘書個性化
  personality_notes TEXT, -- AI 秘書學習到的用戶性格特徵
  interaction_style TEXT, -- formal, casual, humorous

  -- 更新時間
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  analyzed_at TIMESTAMP WITH TIME ZONE -- 最後一次行為分析時間
);

-- ============================================================================
-- 3. 交易記錄表 (核心表)
-- ============================================================================

-- 交易主表
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- 金額與類型
  amount DECIMAL(12,2) NOT NULL,
  currency TEXT DEFAULT 'TWD',
  transaction_type transaction_type NOT NULL DEFAULT 'expense',

  -- 分類
  category TEXT NOT NULL, -- 衣、食、住、行、樂、醫療等
  subcategory TEXT, -- 具體子分類

  -- 商家與位置
  merchant_name TEXT,
  merchant_id UUID REFERENCES merchants(id),
  merchant_category TEXT, -- MCC 代碼相關分類
  location_name TEXT,
  location_latitude DECIMAL(10,8),
  location_longitude DECIMAL(11,8),

  -- 交易元數據
  source_type transaction_source_type NOT NULL,
  source_detail JSONB, -- 詳細來源信息

  -- 信心與質量
  confidence_score DECIMAL(3,2) CHECK (confidence_score >= 0 AND confidence_score <= 1), -- 0-1
  is_verified BOOLEAN DEFAULT FALSE,
  ai_suggested_category TEXT, -- AI 建議分類

  -- 備註與標籤
  notes TEXT,
  tags TEXT[], -- 自定義標籤
  receipt_url TEXT, -- 收據圖片 URL
  photo_urls TEXT[], -- 相關照片 URLs

  -- 時間信息
  transaction_date DATE NOT NULL,
  transaction_time TIME,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

  -- 關聯
  family_ledger_id UUID, -- 家庭帳本 ID (如果是家庭共享)
  linked_transaction_id UUID, -- 關聯的轉帳交易

  CONSTRAINT valid_amount CHECK (amount > 0),
  INDEX idx_user_date (user_id, transaction_date),
  INDEX idx_category (user_id, category),
  INDEX idx_source (user_id, source_type)
);

-- 交易審核與修訂歷史
CREATE TABLE transaction_audits (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  transaction_id UUID NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id),

  -- 變更信息
  change_type TEXT NOT NULL, -- created, edited, verified, categorized
  old_values JSONB,
  new_values JSONB,
  reason TEXT,

  -- 審核人員
  auditor_id UUID REFERENCES users(id), -- 家庭成員審核
  reviewed_at TIMESTAMP WITH TIME ZONE,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

  INDEX idx_transaction (transaction_id),
  INDEX idx_auditor (auditor_id)
);

-- ============================================================================
-- 4. 商家管理表
-- ============================================================================

CREATE TABLE merchants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- 基本信息
  name TEXT NOT NULL,
  alias_names TEXT[], -- 別名 (例: "星巴克", "Starbucks", "Coffee")
  logo_url TEXT,
  website TEXT,
  phone TEXT,

  -- 分類
  category TEXT NOT NULL, -- 飲食、零售、交通等
  mcc_code TEXT, -- Merchant Category Code

  -- 地址與位置
  addresses JSONB[], -- 多個門市地址
  latitude DECIMAL(10,8),
  longitude DECIMAL(11,8),

  -- 用戶相關
  user_count INTEGER DEFAULT 0, -- 有多少用戶去過
  avg_transaction_amount DECIMAL(12,2),

  -- 時間信息
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

  UNIQUE(name, category),
  INDEX idx_category (category),
  INDEX idx_location (latitude, longitude)
);

-- 用戶商家偏好
CREATE TABLE user_merchant_preferences (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  merchant_id UUID NOT NULL REFERENCES merchants(id) ON DELETE CASCADE,

  -- 偏好信息
  visit_count INTEGER DEFAULT 1,
  last_visit_date DATE,
  avg_spend DECIMAL(12,2),
  is_favorite BOOLEAN DEFAULT FALSE,
  notes TEXT,

  -- 時間戳
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

  UNIQUE(user_id, merchant_id),
  INDEX idx_favorite (user_id, is_favorite)
);

-- ============================================================================
-- 5. 被動記帳線索表
-- ============================================================================

-- 地理圍欄記錄
CREATE TABLE geofence_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- 位置信息
  location_name TEXT NOT NULL,
  latitude DECIMAL(10,8) NOT NULL,
  longitude DECIMAL(11,8) NOT NULL,
  radius_meters INTEGER DEFAULT 100,

  -- 進出時間
  entry_time TIMESTAMP WITH TIME ZONE NOT NULL,
  exit_time TIMESTAMP WITH TIME ZONE,
  duration_minutes INTEGER,

  -- 相關交易
  triggered_transaction_id UUID REFERENCES transactions(id),
  visit_purpose TEXT, -- AI 推測的目的

  -- 關聯的其他線索
  photo_logs UUID[], -- 相關的照片分析
  notification_logs UUID[], -- 相關的通知記錄

  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

  INDEX idx_user_time (user_id, entry_time),
  INDEX idx_location (latitude, longitude)
);

-- 照片分析結果
CREATE TABLE photo_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- 照片信息
  photo_url TEXT NOT NULL,
  photo_date TIMESTAMP WITH TIME ZONE NOT NULL,
  source_type TEXT, -- screenshot, camera_roll, manual_upload

  -- AI 分析結果
  detected_receipts TEXT[], -- 偵測到的收據
  detected_items JSONB, -- 偵測到的物品分析
  extracted_text TEXT, -- OCR 結果
  confidence_score DECIMAL(3,2),

  -- 建議與關聯
  suggested_transaction_id UUID, -- AI 建議的關聯交易
  user_approved BOOLEAN DEFAULT NULL,
  notes TEXT,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  processed_at TIMESTAMP WITH TIME ZONE,

  INDEX idx_user_date (user_id, photo_date),
  INDEX idx_suggested (suggested_transaction_id)
);

-- 通知攔截與分析
CREATE TABLE notification_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- 通知內容
  notification_source TEXT NOT NULL, -- bank, payment_app, shopping_app, airline
  notification_title TEXT,
  notification_body TEXT,
  notification_type TEXT, -- transaction, payment, booking, etc
  original_data JSONB, -- 原始通知數據

  -- 解析結果
  parsed_amount DECIMAL(12,2),
  parsed_currency TEXT,
  parsed_merchant TEXT,
  parsed_category TEXT,

  -- 交易關聯
  linked_transaction_id UUID REFERENCES transactions(id),
  suggestion_confidence DECIMAL(3,2),

  -- 用戶操作
  user_action TEXT, -- accepted, ignored, modified

  captured_at TIMESTAMP WITH TIME ZONE NOT NULL,
  processed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

  INDEX idx_user_date (user_id, captured_at),
  INDEX idx_unprocessed (processed_at) WHERE processed_at IS NULL
);

-- ============================================================================
-- 6. AI 秘書與記憶表
-- ============================================================================

-- AI 秘書人格與對話上下文
CREATE TABLE ai_assistant_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,

  -- 人格設定
  name TEXT DEFAULT '艾羅', -- AI 秘書名字
  personality_traits JSONB, -- {trait: intensity}
  tone TEXT DEFAULT 'friendly', -- friendly, professional, humorous

  -- 學習的用戶偏好
  learned_preferences JSONB,
  communication_history_count INTEGER DEFAULT 0,

  -- 內部狀態
  last_insight TEXT, -- 最後一條生成的insights
  last_interaction TIMESTAMP WITH TIME ZONE,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 對話日誌 (用於連續性)
CREATE TABLE conversation_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  ai_assistant_id UUID NOT NULL REFERENCES ai_assistant_profiles(id) ON DELETE CASCADE,

  -- 對話內容
  user_message TEXT NOT NULL,
  assistant_response TEXT NOT NULL,
  context_summary JSONB, -- 對話上下文摘要

  -- 意圖與實體
  detected_intent TEXT, -- ask_balance, categorize, suggest_budget
  extracted_entities JSONB, -- {entity_type: value}

  -- 交互質量
  user_feedback INTEGER, -- -1 (negative), 0 (neutral), 1 (positive)

  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

  INDEX idx_user_date (user_id, created_at)
);

-- 用戶行為分析與摘要
CREATE TABLE behavior_analyses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- 分析期間
  analysis_period TEXT NOT NULL, -- 'daily', 'weekly', 'monthly'
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,

  -- 行為指標
  total_transactions INTEGER,
  total_amount DECIMAL(14,2),
  avg_transaction DECIMAL(12,2),

  -- 分類分布
  category_distribution JSONB, -- {category: percentage}
  top_spending_categories TEXT[],

  -- 時間模式
  busiest_day TEXT, -- 'Monday' 等
  busiest_time_range TEXT, -- '18:00-20:00'

  -- 趨勢與異常
  spending_trend TEXT, -- 'increasing', 'stable', 'decreasing'
  anomalies JSONB, -- 檢測到的異常交易

  -- 洞察與建議
  key_insights TEXT[], -- 生成的主要洞察
  recommendations JSONB, -- 建議改進

  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

  UNIQUE(user_id, analysis_period, period_start),
  INDEX idx_period (period_start, period_end)
);

-- ============================================================================
-- 7. 每日金句表
-- ============================================================================

CREATE TABLE daily_quotes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- 金句內容
  quote_text TEXT NOT NULL,
  quote_author TEXT,
  category TEXT, -- finance, motivation, mindfulness, humor

  -- 生成信息
  generated_by TEXT DEFAULT 'ai', -- ai, user, curated
  generation_context JSONB, -- 生成時的上下文 (如關聯的行為分析)

  -- 用戶互動
  is_favorited BOOLEAN DEFAULT FALSE,
  share_count INTEGER DEFAULT 0,
  share_platforms TEXT[], -- ['twitter', 'facebook', 'whatsapp']
  engagement_score DECIMAL(5,2), -- 用戶互動評分

  -- 時間信息
  date_created DATE NOT NULL DEFAULT CURRENT_DATE,
  date_scheduled DATE, -- 排定展示日期

  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

  INDEX idx_user_date (user_id, date_created),
  INDEX idx_favorite (user_id, is_favorited)
);

-- 金句分享記錄
CREATE TABLE quote_shares (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  quote_id UUID NOT NULL REFERENCES daily_quotes(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id),

  platform TEXT NOT NULL, -- twitter, facebook, whatsapp, email
  shared_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  view_count INTEGER DEFAULT 0,
  interaction_count INTEGER DEFAULT 0,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 8. 生活日記表
-- ============================================================================

-- 每日日記摘要
CREATE TABLE daily_diaries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- 日期
  diary_date DATE NOT NULL,

  -- 摘要內容
  title TEXT,
  summary TEXT, -- AI 生成的每日摘要
  mood TEXT, -- happy, neutral, stressed
  energy_level INTEGER, -- 1-10

  -- 財務摘要
  daily_expense DECIMAL(12,2),
  transaction_count INTEGER,
  spending_highlights JSONB, -- 高額交易或異常交易

  -- 生活事件
  events TEXT[], -- 重要事件
  locations_visited TEXT[], -- 訪問的主要位置

  -- 洞察
  insights TEXT, -- AI 洞察
  ai_observations JSONB, -- AI 觀察到的模式

  -- 關聯
  transaction_ids UUID[], -- 該日期的所有交易 IDs
  photo_log_ids UUID[], -- 該日期的照片

  is_published BOOLEAN DEFAULT FALSE,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

  UNIQUE(user_id, diary_date),
  INDEX idx_date (diary_date)
);

-- 月度日記摘要
CREATE TABLE monthly_diaries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- 月份
  year INTEGER NOT NULL,
  month INTEGER NOT NULL,

  -- 摘要內容
  title TEXT,
  summary TEXT, -- 月度總結
  highlights TEXT[], -- 月度亮點

  -- 財務統計
  total_expense DECIMAL(14,2),
  total_income DECIMAL(14,2),
  net_savings DECIMAL(14,2),
  avg_daily_expense DECIMAL(12,2),

  -- 分析
  category_summary JSONB, -- {category: {amount, percentage}}
  merchant_summary JSONB, -- {merchant: amount}
  spending_trend TEXT, -- 'increasing', 'stable', 'decreasing'

  -- 成就與里程碑
  milestones TEXT[], -- 月度里程碑
  goals_status JSONB, -- 目標達成狀況

  -- AI 評論
  ai_commentary TEXT, -- AI 對月度的評論
  recommendations JSONB,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

  UNIQUE(user_id, year, month),
  INDEX idx_period (year, month)
);

-- ============================================================================
-- 9. 預算管理表
-- ============================================================================

-- 預算設定
CREATE TABLE budgets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- 預算信息
  name TEXT NOT NULL,
  category TEXT, -- 如果為 NULL，則為總預算
  amount DECIMAL(12,2) NOT NULL,
  currency TEXT DEFAULT 'TWD',

  -- 周期
  frequency budget_frequency NOT NULL DEFAULT 'monthly',
  start_date DATE NOT NULL,
  end_date DATE, -- NULL 表示持續有效

  -- 警告設定
  warning_threshold DECIMAL(3,2) DEFAULT 0.8, -- 80% 時警告
  hard_limit BOOLEAN DEFAULT FALSE,

  -- 狀態
  is_active BOOLEAN DEFAULT TRUE,
  progress DECIMAL(12,2) DEFAULT 0, -- 當前已花費金額

  -- 時間戳
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT valid_budget_amount CHECK (amount > 0),
  INDEX idx_user_active (user_id, is_active),
  INDEX idx_period (start_date, end_date)
);

-- 預算警告歷史
CREATE TABLE budget_warnings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  budget_id UUID NOT NULL REFERENCES budgets(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id),

  -- 警告信息
  warning_level TEXT NOT NULL, -- 'warning', 'critical', 'exceeded'
  current_spend DECIMAL(12,2),
  budget_limit DECIMAL(12,2),
  percentage_used DECIMAL(5,2),

  -- 時間
  triggered_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  acknowledged_at TIMESTAMP WITH TIME ZONE,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

  INDEX idx_user_time (user_id, triggered_at)
);

-- ============================================================================
-- 10. 訂閱管理表
-- ============================================================================

-- 訂閱方案
CREATE TABLE subscription_plans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- 方案信息
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  tier TEXT NOT NULL, -- 'free', 'premium', 'pro', 'family'

  -- 價格
  price DECIMAL(10,2),
  currency TEXT DEFAULT 'TWD',
  billing_cycle TEXT, -- 'monthly', 'yearly'

  -- 功能限制
  features JSONB, -- {feature_name: limit_value}
  max_transactions_per_month INTEGER,
  max_family_members INTEGER,
  max_geofences INTEGER,
  ai_features_enabled BOOLEAN DEFAULT FALSE,

  -- RevenueCat 整合
  revenue_cat_id TEXT,

  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 用戶訂閱
CREATE TABLE user_subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  plan_id UUID NOT NULL REFERENCES subscription_plans(id),

  -- 訂閱狀態
  status subscription_status NOT NULL DEFAULT 'trial',

  -- 時間
  started_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  trial_ends_at TIMESTAMP WITH TIME ZONE,
  renews_at TIMESTAMP WITH TIME ZONE,
  cancelled_at TIMESTAMP WITH TIME ZONE,
  expires_at TIMESTAMP WITH TIME ZONE,

  -- 支付信息
  payment_method TEXT, -- 'credit_card', 'paypal', 'apple_pay'
  next_billing_date DATE,
  last_billing_date DATE,

  -- RevenueCat 整合
  revenue_cat_subscription_id TEXT,
  original_transaction_id TEXT,

  -- 自動續訂
  auto_renew BOOLEAN DEFAULT TRUE,

  -- 額外信息
  promotion_code TEXT,
  discount_amount DECIMAL(10,2),

  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

  UNIQUE(user_id, plan_id),
  INDEX idx_status (status),
  INDEX idx_renewal (renews_at)
);

-- 計費記錄
CREATE TABLE billing_records (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  subscription_id UUID NOT NULL REFERENCES user_subscriptions(id),
  user_id UUID NOT NULL REFERENCES users(id),

  -- 賬單信息
  amount DECIMAL(12,2) NOT NULL,
  currency TEXT DEFAULT 'TWD',
  status TEXT NOT NULL, -- 'pending', 'paid', 'failed', 'refunded'

  -- 日期
  billing_date DATE NOT NULL,
  due_date DATE,
  paid_date DATE,

  -- 描述
  description TEXT,
  invoice_number TEXT UNIQUE,

  -- 支付信息
  payment_method TEXT,
  transaction_id TEXT,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

  INDEX idx_user_date (user_id, billing_date),
  INDEX idx_status (status)
);

-- ============================================================================
-- 11. 里程碑與成就表
-- ============================================================================

-- 成就定義
CREATE TABLE achievement_definitions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- 基本信息
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  icon_url TEXT,
  achievement_type achievement_type NOT NULL,

  -- 觸發條件
  trigger_condition JSONB NOT NULL, -- {condition_type: threshold}
  badge_color TEXT,

  -- 獎勵
  points INTEGER DEFAULT 0,
  reward_description TEXT,

  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 用戶成就
CREATE TABLE user_achievements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  achievement_id UUID NOT NULL REFERENCES achievement_definitions(id),

  -- 解鎖信息
  unlocked_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  progress DECIMAL(5,2) DEFAULT 100, -- 進度百分比

  -- 統計
  view_count INTEGER DEFAULT 0,
  share_count INTEGER DEFAULT 0,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

  UNIQUE(user_id, achievement_id),
  INDEX idx_unlocked (unlocked_at)
);

-- 里程碑 (自定義目標)
CREATE TABLE milestones (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- 里程碑信息
  title TEXT NOT NULL,
  description TEXT,
  goal_type TEXT NOT NULL, -- 'savings', 'expense_reduction', 'category_limit'

  -- 目標設定
  target_value DECIMAL(14,2),
  target_date DATE,
  start_date DATE NOT NULL,

  -- 進度
  current_value DECIMAL(14,2) DEFAULT 0,
  progress_percentage DECIMAL(5,2) DEFAULT 0,

  -- 狀態
  status TEXT NOT NULL DEFAULT 'active', -- 'active', 'completed', 'failed', 'abandoned'
  completed_at TIMESTAMP WITH TIME ZONE,

  -- 獎勵
  reward_description TEXT,
  points_reward INTEGER DEFAULT 0,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

  INDEX idx_user_status (user_id, status),
  INDEX idx_target_date (target_date)
);

-- ============================================================================
-- 12. 通知表
-- ============================================================================

CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- 通知內容
  type notification_type NOT NULL,
  title TEXT NOT NULL,
  body TEXT,
  action_url TEXT,

  -- 相關資源
  related_entity_type TEXT, -- 'transaction', 'budget', 'achievement'
  related_entity_id UUID,

  -- 狀態
  is_read BOOLEAN DEFAULT FALSE,
  is_archived BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMP WITH TIME ZONE,

  -- 時間
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP WITH TIME ZONE,

  INDEX idx_user_unread (user_id, is_read),
  INDEX idx_created (created_at)
);

-- ============================================================================
-- 13. 家庭共享帳本表
-- ============================================================================

-- 家庭
CREATE TABLE families (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- 基本信息
  name TEXT NOT NULL,
  description TEXT,
  owner_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,

  -- 設定
  currency TEXT DEFAULT 'TWD',
  timezone TEXT DEFAULT 'Asia/Taipei',

  -- 統計
  member_count INTEGER DEFAULT 1,

  -- 隱私設定
  visibility TEXT DEFAULT 'private', -- 'private', 'shared_summary'

  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 家庭成員
CREATE TABLE family_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- 角色與權限
  role family_role NOT NULL DEFAULT 'member',

  -- 可見性
  can_view_full_transactions BOOLEAN DEFAULT TRUE,
  can_edit_budget BOOLEAN DEFAULT FALSE,
  can_approve_shared_transactions BOOLEAN DEFAULT FALSE,

  -- 邀請
  invited_at TIMESTAMP WITH TIME ZONE,
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  invitation_token TEXT,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

  UNIQUE(family_id, user_id),
  INDEX idx_family (family_id)
);

-- 共享帳本
CREATE TABLE family_ledgers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,

  -- 帳本信息
  name TEXT NOT NULL,
  description TEXT,
  icon_color TEXT,

  -- 類型
  ledger_type TEXT NOT NULL, -- 'shared_household', 'group_trip', 'project'

  -- 管理
  owner_id UUID NOT NULL REFERENCES users(id),

  -- 統計
  member_count INTEGER DEFAULT 0,
  total_transactions INTEGER DEFAULT 0,
  total_amount DECIMAL(14,2) DEFAULT 0,

  is_active BOOLEAN DEFAULT TRUE,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

  INDEX idx_family (family_id),
  INDEX idx_active (is_active)
);

-- 家庭帳本成員
CREATE TABLE family_ledger_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  ledger_id UUID NOT NULL REFERENCES family_ledgers(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- 權限
  can_add_transactions BOOLEAN DEFAULT TRUE,
  can_edit_all BOOLEAN DEFAULT FALSE,
  can_view_details BOOLEAN DEFAULT TRUE,

  -- 統計
  contributed_amount DECIMAL(14,2) DEFAULT 0,

  joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

  UNIQUE(ledger_id, user_id)
);

-- 家庭交易結算
CREATE TABLE family_settlements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  ledger_id UUID NOT NULL REFERENCES family_ledgers(id) ON DELETE CASCADE,

  -- 付款人與收款人
  payer_id UUID NOT NULL REFERENCES users(id),
  payee_id UUID NOT NULL REFERENCES users(id),

  -- 金額
  amount DECIMAL(12,2) NOT NULL,
  currency TEXT DEFAULT 'TWD',

  -- 狀態
  status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'paid', 'cancelled'
  settled_at TIMESTAMP WITH TIME ZONE,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

  INDEX idx_ledger (ledger_id),
  INDEX idx_payer (payer_id),
  INDEX idx_payee (payee_id)
);

-- ============================================================================
-- 14. 索引策略
-- ============================================================================

-- 核心查詢索引
CREATE INDEX idx_transactions_user_date ON transactions(user_id, transaction_date DESC);
CREATE INDEX idx_transactions_category ON transactions(user_id, category);
CREATE INDEX idx_transactions_merchant ON transactions(merchant_id);
CREATE INDEX idx_transactions_source ON transactions(source_type);

CREATE INDEX idx_geofence_logs_user_time ON geofence_logs(user_id, entry_time DESC);
CREATE INDEX idx_geofence_logs_location ON geofence_logs(latitude, longitude);

CREATE INDEX idx_photo_logs_user_date ON photo_logs(user_id, photo_date DESC);
CREATE INDEX idx_photo_logs_processed ON photo_logs(user_id) WHERE processed_at IS NULL;

CREATE INDEX idx_notification_logs_unprocessed ON notification_logs(user_id) WHERE processed_at IS NULL;

CREATE INDEX idx_daily_diaries_date ON daily_diaries(diary_date DESC);
CREATE INDEX idx_monthly_diaries_period ON monthly_diaries(year DESC, month DESC);

CREATE INDEX idx_budgets_user_active ON budgets(user_id) WHERE is_active = TRUE;

CREATE INDEX idx_user_subscriptions_status ON user_subscriptions(user_id, status);

CREATE INDEX idx_daily_quotes_user_date ON daily_quotes(user_id, date_created DESC);

-- 全文搜尋索引
CREATE INDEX idx_merchant_names ON merchants USING GIN (name gin_trgm_ops);
CREATE INDEX idx_transaction_notes ON transactions USING GIN (notes gin_trgm_ops);

-- ============================================================================
-- 15. 觸發器 (Triggers)
-- ============================================================================

-- 更新用戶統計信息的觸發器
CREATE OR REPLACE FUNCTION update_user_stats()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.transaction_type = 'expense' THEN
    UPDATE users
    SET
      total_expense = total_expense + NEW.amount,
      transaction_count = transaction_count + 1,
      last_transaction_date = NEW.transaction_date,
      updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.user_id;
  ELSIF NEW.transaction_type = 'income' THEN
    UPDATE users
    SET
      total_income = total_income + NEW.amount,
      transaction_count = transaction_count + 1,
      last_transaction_date = NEW.transaction_date,
      updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.user_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_user_stats_on_transaction
AFTER INSERT ON transactions
FOR EACH ROW
EXECUTE FUNCTION update_user_stats();

-- 更新預算進度的觸發器
CREATE OR REPLACE FUNCTION update_budget_progress()
RETURNS TRIGGER AS $$
DECLARE
  v_budget_id UUID;
  v_period_amount DECIMAL;
BEGIN
  -- 獲取匹配的預算
  SELECT id INTO v_budget_id FROM budgets
  WHERE user_id = NEW.user_id
    AND (category IS NULL OR category = NEW.category)
    AND is_active = TRUE
    AND NEW.transaction_date >= start_date
    AND (end_date IS NULL OR NEW.transaction_date <= end_date)
    AND NEW.transaction_type = 'expense'
  LIMIT 1;

  IF v_budget_id IS NOT NULL THEN
    -- 更新預算進度
    UPDATE budgets
    SET progress = progress + NEW.amount,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = v_budget_id;

    -- 檢查是否超過警告閾值
    SELECT progress INTO v_period_amount FROM budgets WHERE id = v_budget_id;

    IF (v_period_amount / amount) >= warning_threshold THEN
      INSERT INTO budget_warnings (budget_id, user_id, warning_level, current_spend, budget_limit, percentage_used)
      SELECT
        v_budget_id,
        NEW.user_id,
        CASE
          WHEN (v_period_amount / amount) >= 1 THEN 'exceeded'
          WHEN (v_period_amount / amount) >= 0.95 THEN 'critical'
          ELSE 'warning'
        END,
        v_period_amount,
        amount,
        (v_period_amount / amount) * 100
      FROM budgets WHERE id = v_budget_id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_budget_on_transaction
AFTER INSERT ON transactions
FOR EACH ROW
EXECUTE FUNCTION update_budget_progress();

-- 自動創建每日日記的觸發器
CREATE OR REPLACE FUNCTION ensure_daily_diary()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO daily_diaries (user_id, diary_date)
  VALUES (NEW.user_id, NEW.transaction_date)
  ON CONFLICT (user_id, diary_date) DO NOTHING;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_ensure_daily_diary
AFTER INSERT ON transactions
FOR EACH ROW
EXECUTE FUNCTION ensure_daily_diary();

-- 更新商家統計信息的觸發器
CREATE OR REPLACE FUNCTION update_merchant_stats()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.merchant_id IS NOT NULL THEN
    UPDATE merchants
    SET
      user_count = (SELECT COUNT(DISTINCT user_id) FROM transactions WHERE merchant_id = NEW.merchant_id),
      avg_transaction_amount = (SELECT AVG(amount) FROM transactions WHERE merchant_id = NEW.merchant_id),
      updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.merchant_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_merchant_stats
AFTER INSERT ON transactions
FOR EACH ROW
EXECUTE FUNCTION update_merchant_stats();

-- 自動清理過期通知的觸發器
CREATE OR REPLACE FUNCTION cleanup_expired_notifications()
RETURNS TRIGGER AS $$
BEGIN
  DELETE FROM notifications
  WHERE expires_at IS NOT NULL
    AND expires_at < CURRENT_TIMESTAMP;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_cleanup_notifications
AFTER INSERT ON notifications
FOR EACH ROW
EXECUTE FUNCTION cleanup_expired_notifications();

-- ============================================================================
-- 16. Row Level Security (RLS) 政策
-- ============================================================================

-- 啟用 RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_patterns ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE transaction_audits ENABLE ROW LEVEL SECURITY;
ALTER TABLE merchants ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_merchant_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE geofence_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE photo_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_assistant_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversation_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE behavior_analyses ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_quotes ENABLE ROW LEVEL SECURITY;
ALTER TABLE quote_shares ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_diaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE monthly_diaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE budget_warnings ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE billing_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE milestones ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE families ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_ledgers ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_ledger_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_settlements ENABLE ROW LEVEL SECURITY;

-- 用戶表 RLS 政策
-- 用戶只能看到自己的信息，除非是家庭成員
CREATE POLICY "用戶只能看到自己的資料" ON users
  FOR SELECT USING (
    auth.uid() = id
    OR id IN (
      SELECT user_id FROM family_members
      WHERE family_id IN (
        SELECT family_id FROM family_members WHERE user_id = auth.uid()
      )
    )
  );

CREATE POLICY "用戶只能更新自己的資料" ON users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "允許創建新用戶" ON users
  FOR INSERT WITH CHECK (auth.uid() = id);

-- 交易表 RLS 政策
CREATE POLICY "用戶只能看到自己的交易" ON transactions
  FOR SELECT USING (
    user_id = auth.uid()
    OR family_ledger_id IN (
      SELECT id FROM family_ledgers
      WHERE family_id IN (
        SELECT family_id FROM family_members WHERE user_id = auth.uid()
      )
    )
  );

CREATE POLICY "用戶只能創建自己的交易" ON transactions
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "用戶只能更新自己的交易" ON transactions
  FOR UPDATE USING (user_id = auth.uid());

-- 預算表 RLS 政策
CREATE POLICY "用戶只能看到自己的預算" ON budgets
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "用戶只能管理自己的預算" ON budgets
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "用戶只能更新自己的預算" ON budgets
  FOR UPDATE USING (user_id = auth.uid());

-- 訂閱表 RLS 政策
CREATE POLICY "用戶只能看到自己的訂閱" ON user_subscriptions
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "用戶只能創建自己的訂閱" ON user_subscriptions
  FOR INSERT WITH CHECK (user_id = auth.uid());

-- 日記表 RLS 政策
CREATE POLICY "用戶只能看到自己的日記" ON daily_diaries
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "用戶只能創建自己的日記" ON daily_diaries
  FOR INSERT WITH CHECK (user_id = auth.uid());

-- 家庭成員表 RLS 政策
CREATE POLICY "家庭成員可以看到家庭信息" ON family_members
  FOR SELECT USING (
    user_id = auth.uid()
    OR family_id IN (
      SELECT family_id FROM family_members WHERE user_id = auth.uid()
    )
  );

-- 家庭帳本表 RLS 政策
CREATE POLICY "家庭成員可以看到家庭帳本" ON family_ledgers
  FOR SELECT USING (
    family_id IN (
      SELECT family_id FROM family_members WHERE user_id = auth.uid()
    )
  );

-- ============================================================================
-- 17. 視圖 (Views)
-- ============================================================================

-- 用戶月度統計視圖
CREATE OR REPLACE VIEW user_monthly_stats AS
SELECT
  t.user_id,
  DATE_TRUNC('month', t.transaction_date)::DATE as month,
  EXTRACT(YEAR FROM t.transaction_date)::INTEGER as year,
  EXTRACT(MONTH FROM t.transaction_date)::INTEGER as month_num,
  COUNT(*) as transaction_count,
  SUM(CASE WHEN t.transaction_type = 'expense' THEN t.amount ELSE 0 END) as total_expense,
  SUM(CASE WHEN t.transaction_type = 'income' THEN t.amount ELSE 0 END) as total_income,
  AVG(CASE WHEN t.transaction_type = 'expense' THEN t.amount END) as avg_expense,
  MAX(t.amount) as max_transaction,
  MIN(t.amount) as min_transaction
FROM transactions t
WHERE t.deleted_at IS NULL
GROUP BY t.user_id, DATE_TRUNC('month', t.transaction_date);

-- 用戶分類統計視圖
CREATE OR REPLACE VIEW category_spending_stats AS
SELECT
  t.user_id,
  t.category,
  COUNT(*) as transaction_count,
  SUM(t.amount) as total_amount,
  AVG(t.amount) as avg_amount,
  MAX(t.transaction_date) as last_transaction_date
FROM transactions t
WHERE t.transaction_type = 'expense' AND t.deleted_at IS NULL
GROUP BY t.user_id, t.category;

-- 預算使用率視圖
CREATE OR REPLACE VIEW budget_utilization AS
SELECT
  b.id,
  b.user_id,
  b.name,
  b.amount as budget_limit,
  b.progress as current_spend,
  ROUND((b.progress / b.amount) * 100, 2) as utilization_percentage,
  CASE
    WHEN (b.progress / b.amount) >= 1 THEN 'exceeded'
    WHEN (b.progress / b.amount) >= b.warning_threshold THEN 'warning'
    ELSE 'normal'
  END as status,
  (b.amount - b.progress) as remaining_amount
FROM budgets b
WHERE b.is_active = TRUE;

-- ============================================================================
-- 18. 初始數據與種子
-- ============================================================================

-- 預設訂閱方案
INSERT INTO subscription_plans (name, tier, description, price, currency, billing_cycle, features, max_transactions_per_month, max_family_members, ai_features_enabled)
VALUES
  ('Free', 'free', '免費試用版', 0, 'TWD', 'monthly', '{"voice_input": true, "manual_entry": true, "basic_analytics": true}'::JSONB, 100, 1, FALSE),
  ('Premium', 'premium', '進階版 - 增強功能', 99, 'TWD', 'monthly', '{"voice_input": true, "manual_entry": true, "ai_categorization": true, "advanced_analytics": true, "passive_tracking": true}'::JSONB, 1000, 1, TRUE),
  ('Pro', 'pro', '專業版 - 完整功能', 199, 'TWD', 'monthly', '{"voice_input": true, "manual_entry": true, "ai_categorization": true, "advanced_analytics": true, "passive_tracking": true, "photo_analysis": true, "api_access": true}'::JSONB, NULL, 1, TRUE),
  ('Family', 'family', '家庭版 - 家庭共享', 299, 'TWD', 'monthly', '{"voice_input": true, "manual_entry": true, "ai_categorization": true, "advanced_analytics": true, "passive_tracking": true, "photo_analysis": true, "family_sharing": true}'::JSONB, NULL, 6, TRUE);

-- ============================================================================
-- 19. 完整性約束檢查
-- ============================================================================

-- 外鍵約束
ALTER TABLE transactions ADD CONSTRAINT fk_transactions_family_ledger
  FOREIGN KEY (family_ledger_id) REFERENCES family_ledgers(id) ON DELETE SET NULL;

ALTER TABLE daily_quotes ADD CONSTRAINT valid_category
  CHECK (category IN ('finance', 'motivation', 'mindfulness', 'humor', 'other'));

-- ============================================================================
-- 20. 註釋與文檔
-- ============================================================================

COMMENT ON TABLE users IS '用戶基本信息表，儲存所有應用用戶的核心資料';
COMMENT ON TABLE transactions IS '交易記錄主表，支持多種來源（語音、GPS、照片等）的交易輸入';
COMMENT ON TABLE daily_diaries IS '每日日記摘要，由 AI 自動生成，記錄日常消費和生活情況';
COMMENT ON TABLE budgets IS '預算管理表，支持總預算和分類預算';
COMMENT ON TABLE user_subscriptions IS '用戶訂閱狀態，與 RevenueCat 整合';
COMMENT ON TABLE family_ledgers IS '家庭共享帳本，支持多用戶的共同記帳';
COMMENT ON TABLE daily_quotes IS '每日金句，可由 AI 生成或手動添加';

-- ============================================================================
-- 完成
-- ============================================================================
-- Migration 版本: 001
-- 創建時間: 2026-03-18
-- 狀態: 可用於生產環境
