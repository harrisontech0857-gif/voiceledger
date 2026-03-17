# VoiceLedger (語記) - Supabase 資料庫設置

## 概述

此目錄包含 VoiceLedger AI 財務秘書應用的完整資料庫架構和遷移文件。

---

## 文件結構

```
backend/supabase/
├── migrations/
│   └── 001_初始架構.sql          ← 完整的資料庫初始化 SQL
└── README.md                     ← 本文件

../docs/
├── 資料庫架構設計.md             ← 詳細的架構設計文檔
└── 資料庫表快速參考.md           ← 表格快速查詢指南
```

---

## 快速開始

### 1. 在 Supabase 中應用遷移

#### 方式 A: 使用 Supabase CLI

```bash
# 安裝 Supabase CLI (如果尚未安裝)
npm install -g supabase

# 登錄
supabase login

# 鏈接到項目
supabase link --project-ref YOUR_PROJECT_REF

# 應用遷移
supabase db push
```

#### 方式 B: 使用 Supabase Dashboard

1. 打開 Supabase Dashboard
2. 進入 SQL Editor
3. 複製 `001_初始架構.sql` 的內容
4. 粘貼到編輯器
5. 執行

#### 方式 C: 使用 psql 命令行

```bash
# 連接到 PostgreSQL
psql -h db.PROJECT_REF.supabase.co -U postgres -d postgres

# 輸入密碼
# 創建數據庫
CREATE DATABASE voiceledger;

# 連接到新數據庫
\c voiceledger

# 執行遷移
\i 001_初始架構.sql
```

---

## 架構概述

### 核心組件

1. **用戶系統** (2 表)
   - `users`: 用戶基本信息
   - `user_patterns`: 用戶習慣和模式

2. **交易記錄** (2 表)
   - `transactions`: 所有金融交易
   - `transaction_audits`: 變更審計

3. **被動記帳線索** (3 表)
   - `geofence_logs`: GPS 圍欄進出
   - `photo_logs`: 照片分析結果
   - `notification_logs`: 支付通知攔截

4. **AI 秘書與分析** (3 表)
   - `ai_assistant_profiles`: AI 秘書設置
   - `conversation_logs`: 對話歷史
   - `behavior_analyses`: 行為分析結果

5. **日記與內容** (4 表)
   - `daily_diaries`: 每日摘要
   - `monthly_diaries`: 月度摘要
   - `daily_quotes`: 每日金句
   - `quote_shares`: 金句分享

6. **預算管理** (2 表)
   - `budgets`: 預算配置
   - `budget_warnings`: 警告歷史

7. **訂閱與計費** (3 表)
   - `subscription_plans`: 可用方案
   - `user_subscriptions`: 用戶訂閱
   - `billing_records`: 計費記錄

8. **家庭共享** (5 表)
   - `families`: 家庭
   - `family_members`: 家庭成員
   - `family_ledgers`: 共享帳本
   - `family_ledger_members`: 帳本成員
   - `family_settlements`: 費用結算

9. **成就與里程碑** (3 表)
   - `achievement_definitions`: 成就定義
   - `user_achievements`: 用戶成就
   - `milestones`: 用戶里程碑

10. **其他** (1 表)
    - `notifications`: 應用內通知

**總計: 27 個表**

---

## 關鍵特性

### Row Level Security (RLS)

所有用戶相關表都啟用了 RLS，確保數據隔離：

- 用戶只能訪問自己的數據
- 家庭成員可以訪問共享數據
- 完全的隐私保護

### 自動化觸發器

5 個觸發器自動維護數據完整性：

1. 更新用戶統計信息
2. 跟蹤預算進度
3. 自動創建日記
4. 更新商家統計
5. 清理過期通知

### 複合索引

19 個精心優化的索引確保查詢性能：

- 交易表優化的複合索引
- 時間範圍查詢優化
- 全文搜尋支持 (GIN 索引)
- 位置查詢支持

### JSONB 靈活性

使用 JSONB 字段支持靈活的數據結構：

- `preferences`: 用戶偏好
- `source_detail`: 交易來源詳情
- `personality_traits`: AI 秘書人格
- 等等...

---

## 驗證安裝

安裝完成後，驗證所有表已正確創建：

```sql
-- 檢查表數量
SELECT COUNT(*) as table_count FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE';
-- 應返回 27

-- 檢查索引數量
SELECT COUNT(*) as index_count FROM pg_indexes
WHERE schemaname = 'public';
-- 應返回 25+ (包括主鍵和外鍵索引)

-- 檢查視圖
SELECT * FROM information_schema.views
WHERE table_schema = 'public';
-- 應返回 3 個視圖

-- 檢查觸發器
SELECT COUNT(*) as trigger_count FROM information_schema.triggers
WHERE trigger_schema = 'public';
-- 應返回 5 個觸發器

-- 檢查初始數據
SELECT COUNT(*) FROM subscription_plans;
-- 應返回 4 (Free, Premium, Pro, Family)
```

---

## 常見操作

### 查詢用戶月度支出

```sql
SELECT * FROM user_monthly_stats
WHERE user_id = 'YOUR_USER_ID'
ORDER BY month DESC
LIMIT 12;
```

### 檢查預算狀態

```sql
SELECT * FROM budget_utilization
WHERE user_id = 'YOUR_USER_ID'
ORDER BY utilization_percentage DESC;
```

### 獲取用戶分類支出

```sql
SELECT * FROM category_spending_stats
WHERE user_id = 'YOUR_USER_ID'
ORDER BY total_amount DESC;
```

### 創建新用戶

```sql
INSERT INTO users (email, display_name, timezone)
VALUES ('user@example.com', 'John Doe', 'Asia/Taipei')
RETURNING id;
```

### 記錄交易

```sql
INSERT INTO transactions (
  user_id,
  amount,
  transaction_type,
  category,
  merchant_name,
  source_type,
  transaction_date,
  confidence_score
) VALUES (
  'user-id',
  150.50,
  'expense',
  'food',
  'Starbucks',
  'voice',
  CURRENT_DATE,
  0.95
) RETURNING id;
```

---

## 性能基準

| 查詢類型 | 目標響應時間 |
|---------|-----------|
| 單月交易列表 | < 50ms |
| 年度統計 | < 100ms |
| 分類報告 | < 100ms |
| 異常檢測 | < 500ms |
| 家庭結算 | < 200ms |

---

## 備份與恢復

### 備份

```bash
# 使用 Supabase CLI
supabase db pull

# 或使用 pg_dump
pg_dump -h db.PROJECT_REF.supabase.co -U postgres voiceledger > backup.sql
```

### 恢復

```bash
# 使用 psql
psql -h db.PROJECT_REF.supabase.co -U postgres voiceledger < backup.sql
```

---

## 文檔參考

詳細文檔位於 `docs/` 目錄：

1. **資料庫架構設計.md** - 完整的架構文檔
   - 表結構詳解
   - 設計決策
   - RLS 政策
   - 索引策略
   - 觸發器與自動化
   - 常用查詢

2. **資料庫表快速參考.md** - 快速查詢指南
   - 所有 27 個表的簡要信息
   - 欄位清單
   - 關鍵索引
   - ENUM 類型
   - 快速查詢模板

---

## 故障排除

### 問題：連接被拒絕

**解決方案**:
- 檢查 Supabase 項目設置中的連接字符串
- 確保您的 IP 在允許列表中
- 檢查密碼是否正確

### 問題：權限錯誤

**解決方案**:
- 確保使用 `postgres` 用戶或具有足夠權限的用戶
- 檢查 RLS 政策是否正確配置

### 問題：外鍵約束違反

**解決方案**:
- 確保父記錄存在後再插入子記錄
- 檢查 ON DELETE 政策 (CASCADE vs RESTRICT)

### 問題：查詢性能緩慢

**解決方案**:
- 檢查是否使用了正確的索引
- 運行 `ANALYZE` 更新統計信息
- 查看執行計劃: `EXPLAIN ANALYZE SELECT ...`

---

## 升級與維護

### 添加新表

1. 創建新的 migration 文件：`002_添加新表.sql`
2. 使用 `supabase db push` 應用
3. 更新文檔

### 修改現有表

1. 創建 migration 文件
2. 包含 ALTER TABLE 語句
3. 確保向下兼容

### 數據遷移

```sql
-- 示例：從舊表遷移到新表
INSERT INTO new_table
SELECT * FROM old_table;

-- 驗證
SELECT COUNT(*) FROM old_table;
SELECT COUNT(*) FROM new_table;

-- 清理
DROP TABLE old_table;
```

---

## 最佳實踐

### 1. 始終使用 UNIQUE 約束

```sql
-- 好
UNIQUE(user_id, category)

-- 避免重複數據
```

### 2. 使用 JSONB 存儲靈活數據

```sql
-- 避免頻繁添加列
preferences JSONB
→ preferences->>'theme' = 'dark'
```

### 3. 定期分析和重新索引

```sql
ANALYZE;
REINDEX DATABASE voiceledger;
```

### 4. 監控查詢性能

```sql
SELECT query, calls, mean_time, max_time
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 10;
```

### 5. 定期備份

設置自動每日備份到外部存儲

---

## 監控和告警

### 啟用 pg_stat_statements

```sql
-- 在 postgresql.conf 中添加
shared_preload_libraries = 'pg_stat_statements'
```

### 監控關鍵指標

- 連接數
- 查詢延遲
- 磁盤空間
- 複製延遲 (如適用)

---

## 聯繫與支持

如有問題，請參考：

1. [Supabase 官方文檔](https://supabase.com/docs)
2. [PostgreSQL 官方文檔](https://www.postgresql.org/docs)
3. 項目文檔在 `docs/` 目錄

---

## 版本歷史

| 版本 | 日期 | 說明 |
|------|------|------|
| 1.0 | 2026-03-18 | 初始版本 - 27 個表，完整的架構 |

---

**最後更新**: 2026-03-18
