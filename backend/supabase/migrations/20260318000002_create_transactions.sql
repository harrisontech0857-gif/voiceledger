-- 交易紀錄表
CREATE TABLE IF NOT EXISTS transactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('expense', 'income')),
  amount DOUBLE PRECISION NOT NULL CHECK (amount >= 0),
  currency TEXT DEFAULT 'TWD',
  category TEXT NOT NULL DEFAULT 'other',
  description TEXT DEFAULT '',
  note TEXT DEFAULT '',
  voice_transcript TEXT,
  location_lat DOUBLE PRECISION,
  location_lng DOUBLE PRECISION,
  location_name TEXT,
  is_recurring BOOLEAN DEFAULT false,
  recurring_interval TEXT,
  photos TEXT[] DEFAULT '{}',
  tags TEXT[] DEFAULT '{}',
  sync_status TEXT DEFAULT 'synced',
  transaction_date TIMESTAMPTZ DEFAULT now() NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TRIGGER set_transactions_updated_at
  BEFORE UPDATE ON transactions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- RLS
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "使用者可讀取自己的交易"
  ON transactions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "使用者可新增自己的交易"
  ON transactions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "使用者可更新自己的交易"
  ON transactions FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "使用者可刪除自己的交易"
  ON transactions FOR DELETE
  USING (auth.uid() = user_id);

-- 索引
CREATE INDEX idx_transactions_user_id ON transactions(user_id);
CREATE INDEX idx_transactions_date ON transactions(transaction_date DESC);
CREATE INDEX idx_transactions_category ON transactions(category);
CREATE INDEX idx_transactions_type ON transactions(type);
CREATE INDEX idx_transactions_user_date ON transactions(user_id, transaction_date DESC);
