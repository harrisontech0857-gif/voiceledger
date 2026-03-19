# 語記 — 情侶語音日記 × 寵物養成 MVP 規格書

> 版本：2.0 MVP
> 日期：2026-03-20

## 一句話定位

**兩個人各自說出自己的一天，AI 寫成日記，一起養一隻寵物。**

---

## 免費版功能（MVP 上架）

### 1. 配對系統
- A 產生 6 位邀請碼
- B 輸入邀請碼完成配對
- 配對後共享一隻寵物
- 一個帳號同時只能有一個伴侶

### 2. 語音日記
- 各自錄語音 → AI 分析情緒 + 標籤 → 生成日記文字
- 只能**看**對方的日記文字（不能聽語音）
- 每人每天可以寫多則，同一天的日記會追加
- 日記頁面：行事曆標記 + 選日期看雙方日記

### 3. 共同養寵物（輪流餵食）
- 兩人共養一隻招財貓
- **輪流餵食機制**：
  - A 寫日記 → 餵了一餐 → 輪到 B
  - B 寫日記 → 餵了一餐 → 輪到 A
  - 同一個人連續寫不算第二餐（必須對方先寫）
- 寵物狀態：
  - 兩人都有寫 → 開心（吃飽）
  - 只有一人寫 → 等待（肚子咕嚕）
  - 都沒寫 → 餓肚子 → 睡著
- 寵物進化：需要累積雙人互動次數

### 4. 首頁
- 共同寵物主視覺
- 今天的餵食狀態（你寫了/對方還沒寫）
- 對方最新日記摘要（一句話）
- 每日金句

### 5. 底部導航
- 首頁（寵物+狀態）
- AI 秘書（對話）
- [語音按鈕]
- 日記（行事曆+雙方日記）
- 設定

---

## 付費版功能（未來更新）

### AI 情緒洞察（Pro）
- AI 分析雙方情緒趨勢
- 週報：兩人的情緒曲線、關係分數
- AI 建議（例：「B 這週壓力較大，建議安排放鬆約會」）
- 重要事件標記（紀念日、吵架、特殊時刻）
- AI 諮詢建議

---

## 資料庫設計

### couples 表（新增）
```sql
CREATE TABLE couples (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_a UUID NOT NULL REFERENCES auth.users(id),
  user_b UUID REFERENCES auth.users(id),  -- 配對前為 null
  invite_code TEXT NOT NULL UNIQUE,
  pet_name TEXT DEFAULT '小財',
  pet_exp INT DEFAULT 0,
  pet_streak INT DEFAULT 0,
  pet_mood TEXT DEFAULT 'neutral',
  last_fed_by UUID,          -- 最後餵食的人
  last_fed_at TIMESTAMPTZ,
  feed_turn UUID,            -- 現在輪到誰餵（另一個人）
  created_at TIMESTAMPTZ DEFAULT now(),
  status TEXT DEFAULT 'pending'  -- pending / active / dissolved
);
```

### user_profiles 修改
```sql
ALTER TABLE user_profiles
  ADD COLUMN couple_id UUID REFERENCES couples(id);
```

### life_diaries 修改
- 已有 user_id，不用改
- RLS 新增：伴侶可以讀取對方的日記

---

## 頁面流程

### 新用戶流程
1. Google 登入
2. Onboarding（3 頁）
3. 配對頁面：
   - 「建立邀請碼」→ 顯示 6 位碼 + 分享按鈕
   - 「輸入對方的邀請碼」→ 配對成功
4. 給寵物取名
5. 進入首頁

### 日常使用流程
1. 打開 App → 首頁看寵物 + 對方狀態
2. 點語音按鈕 → 說話 → AI 生成日記 → 確認保存
3. 寵物吃了一餐 → 顯示「輪到對方了」
4. 對方寫了 → 推播通知「對方寫了日記，快來看看」
5. 點日記頁 → 看對方的日記
