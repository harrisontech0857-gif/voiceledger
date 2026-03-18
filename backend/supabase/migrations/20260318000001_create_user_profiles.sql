-- 使用者個人資料表
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
  email TEXT,
  display_name TEXT DEFAULT '',
  avatar_url TEXT,
  locale TEXT DEFAULT 'zh_TW',
  theme_mode TEXT DEFAULT 'system',
  currency TEXT DEFAULT 'TWD',
  daily_budget DOUBLE PRECISION DEFAULT 0,
  monthly_budget DOUBLE PRECISION DEFAULT 0,
  enable_notifications BOOLEAN DEFAULT true,
  enable_location_tracking BOOLEAN DEFAULT false,
  is_premium BOOLEAN DEFAULT false,
  subscription_tier TEXT DEFAULT 'free',
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- 自動更新 updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_user_profiles_updated_at
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "使用者可讀取自己的資料"
  ON user_profiles FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "使用者可新增自己的資料"
  ON user_profiles FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "使用者可更新自己的資料"
  ON user_profiles FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 索引
CREATE INDEX idx_user_profiles_user_id ON user_profiles(user_id);

-- 新用戶自動建立 profile
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (user_id, email)
  VALUES (NEW.id, NEW.email);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
