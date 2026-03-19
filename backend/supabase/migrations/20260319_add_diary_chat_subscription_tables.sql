-- Migration: 新增 life_diaries、chat_logs、subscription_events 資料表
-- 日期: 2026-03-19

-- 1. life_diaries — AI 日記
CREATE TABLE IF NOT EXISTS public.life_diaries (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  diary_date DATE NOT NULL,
  content TEXT NOT NULL DEFAULT '',
  mood TEXT DEFAULT 'balanced',
  highlight TEXT DEFAULT '',
  total_expense DOUBLE PRECISION DEFAULT 0,
  total_income DOUBLE PRECISION DEFAULT 0,
  transaction_count INTEGER DEFAULT 0,
  personal_note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, diary_date)
);

ALTER TABLE public.life_diaries ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read own diaries" ON public.life_diaries FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own diaries" ON public.life_diaries FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own diaries" ON public.life_diaries FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE TRIGGER update_life_diaries_updated_at BEFORE UPDATE ON public.life_diaries
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 2. chat_logs — AI 對話紀錄
CREATE TABLE IF NOT EXISTS public.chat_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  user_message TEXT NOT NULL,
  assistant_reply TEXT NOT NULL,
  source TEXT DEFAULT 'ai-chat',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.chat_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read own chat logs" ON public.chat_logs FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own chat logs" ON public.chat_logs FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 3. subscription_events — RevenueCat 訂閱事件
CREATE TABLE IF NOT EXISTS public.subscription_events (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  event_id TEXT,
  product_id TEXT,
  store TEXT,
  environment TEXT,
  period_type TEXT,
  price DOUBLE PRECISION,
  currency TEXT,
  purchased_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  cancel_reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.subscription_events ENABLE ROW LEVEL SECURITY;

-- 4. user_profiles 新增訂閱欄位
ALTER TABLE public.user_profiles
  ADD COLUMN IF NOT EXISTS subscription_plan TEXT,
  ADD COLUMN IF NOT EXISTS subscription_status TEXT DEFAULT 'none',
  ADD COLUMN IF NOT EXISTS subscription_expires_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS subscription_store TEXT,
  ADD COLUMN IF NOT EXISTS cancel_reason TEXT,
  ADD COLUMN IF NOT EXISTS auth_id TEXT;

-- 5. 更新 handle_new_user trigger（支援 Google OAuth）
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email, display_name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.email, ''),
    COALESCE(
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'name',
      split_part(COALESCE(NEW.email, ''), '@', 1)
    ),
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE LOG 'handle_new_user failed for %: %', NEW.id, SQLERRM;
  RETURN NEW;
END;
$$;
