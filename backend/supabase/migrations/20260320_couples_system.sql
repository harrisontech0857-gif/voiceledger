-- 情侶日記 v2.0 — 配對系統 + 共同寵物
-- 日期: 2026-03-20

-- 1. couples 表
CREATE TABLE IF NOT EXISTS public.couples (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_a UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  user_b UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  invite_code TEXT NOT NULL UNIQUE,
  pet_name TEXT DEFAULT '小財',
  pet_exp INT DEFAULT 0,
  pet_streak INT DEFAULT 0,
  pet_mood TEXT DEFAULT 'neutral',
  last_fed_by UUID,
  last_fed_at TIMESTAMPTZ,
  feed_turn UUID,         -- 輪到誰餵
  status TEXT DEFAULT 'pending',  -- pending / active / dissolved
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.couples ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Couple members can read" ON public.couples FOR SELECT USING (auth.uid() = user_a OR auth.uid() = user_b);
CREATE POLICY "Creator can update" ON public.couples FOR UPDATE USING (auth.uid() = user_a OR auth.uid() = user_b) WITH CHECK (auth.uid() = user_a OR auth.uid() = user_b);
CREATE POLICY "Anyone can insert" ON public.couples FOR INSERT WITH CHECK (auth.uid() = user_a);
CREATE TRIGGER update_couples_updated_at BEFORE UPDATE ON public.couples FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 2. user_profiles 加 couple_id
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS couple_id UUID REFERENCES public.couples(id) ON DELETE SET NULL;

-- 3. 伴侶 ID 查詢函數
CREATE OR REPLACE FUNCTION get_partner_id(uid UUID)
RETURNS UUID LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT CASE WHEN c.user_a = uid THEN c.user_b WHEN c.user_b = uid THEN c.user_a ELSE NULL END
  FROM couples c WHERE (c.user_a = uid OR c.user_b = uid) AND c.status = 'active' LIMIT 1;
$$;

-- 4. 伴侶可讀取對方日記
CREATE POLICY "Partner can read diaries" ON public.life_diaries
  FOR SELECT USING (auth.uid() = user_id OR user_id = get_partner_id(auth.uid()));
