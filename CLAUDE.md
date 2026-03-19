# VoiceLedger (語記) — 開發標準

## 產品定位
情侶語音日記 × 寵物養成。兩人各自說出自己的一天，AI 寫成日記，輪流餵養一隻共同寵物。

## 技術棧
- Flutter 3.29.2 + Dart 3.7.x + Riverpod
- Supabase (PostgreSQL + Auth + Edge Functions + RLS)
- AI: Groq API (Llama 3.1) → Claude → Gemini → 規則式 fallback
- CI: GitHub Actions (6 jobs)

## 開發流程（每次變更必須遵循）

### 1. Plan — 想清楚再動手
- 明確要改什麼、為什麼改
- 列出所有受影響的檔案
- 如果是大變更，先寫規格

### 2. Build — 實作
- 遵循既有架構模式
- 新 service 放 `lib/services/`，新頁面放 `lib/features/<name>/`
- 環境變數用 `String.fromEnvironment`，不要硬編碼

### 3. Review — 自我審查（推送前必做）
- 確認所有 import 正確（不引用已刪除的模組）
- 確認沒有殘留的舊功能程式碼
- 跑 `grep -rn 'TransactionCategory\|transactionServiceProvider\|petProvider' lib/features/` 確認舊交易/舊寵物引用已清除
- 確認新增的 Provider 有在正確位置註冊

### 4. Test — 本地驗證（推送前必做）
- `dart format lib/ test/`（用 Dart 3.7.x）
- 搜尋未定義的 getter/method：`grep -rn "isn't defined\|not found" 2>/dev/null`
- 確認 CI 會過：analyze + format + test + build

### 5. Ship — 推送
- git add → commit → push
- 等 CI 跑完確認 6/6 全綠
- CI 失敗就自己修，不問使用者
- 只有 CI 全綠才通知使用者

### 6. Reflect — 回顧
- 記錄做了什麼、為什麼
- 更新相關文件

## Git 設定
- user.name: "Harrison Wu"
- user.email: "harrison.tech.0857@gmail.com"
- remote 已含 PAT，直接 push 即可
- commit 格式：`type(scope): 繁體中文描述`
- 結尾加 `Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>`

## Supabase 設定
- Project Ref: `dpqgrwoqalwfodblctqm`
- Access Token: `sbp_93714b787d7d33917556992ef54aec5596974f8f`
- voice-diary 部署加 `--no-verify-jwt`
- 從 `backend/supabase/` 目錄執行 CLI，需先 `supabase link`

## 重要 DB 表
- `couples` — 配對、共同寵物狀態、輪流餵食
- `life_diaries` — 語音日記（RLS 允許伴侶讀取）
- `user_profiles` — 使用者資料 + couple_id
- `transactions` — 舊版記帳（付費功能，目前不使用）

## 禁止事項
- 不推送有 compile error 的程式碼
- 不保留引用已刪除模組的 import
- 不讓使用者幫忙測試或除錯
- 不問「要我繼續嗎」— 直接做完
- 不重複問已經回答過的問題
