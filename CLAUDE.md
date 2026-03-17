# CLAUDE.md — AI 開發輔助指引

## 專案概要

VoiceLedger (語記) 是一個 AI 驅動的口說記帳 App，使用 Flutter 跨平台開發，後端為 Supabase，AI 引擎整合 Whisper + Claude/GPT。

## 開發流程

本專案採用 OMC 五層生命週期 + 三重審查機制：
- L1 需求策略層 → L2 架構設計層 → L3 開發實作層 → L4 交付部署層 → L5 營運監控層
- 每層通過 R1(AI審查) + R2(人工確認) + R3(自動化驗證) 後才進入下一層

## 技術棧

- **前端**: Flutter 3.x + Dart 3.x + Riverpod
- **後端**: Supabase (PostgreSQL + Auth + Storage + Edge Functions)
- **AI**: OpenAI Whisper API + Claude/GPT API
- **自動化**: n8n + GitHub Actions
- **付費**: RevenueCat
- **監控**: Sentry + Mixpanel

## 專案結構

- `docs/` — 規劃文件、架構設計、API 文件
- `app/` — Flutter 主專案
- `backend/` — Supabase 設定與 Edge Functions
- `ai/` — AI Prompt 模板與評估
- `.github/` — CI/CD 與 Issue 模板

## 開發規範

1. Commit message 使用 conventional commits 格式 (feat:, fix:, docs:, chore:)
2. 分支策略: main (穩定) + develop (開發) + feature/* (功能分支)
3. 所有 PR 必須通過 CI 且至少一次 Code Review
4. 檔案命名使用 zh-TW（文件類）或 snake_case（程式碼）
5. AI 生成的程式碼必須附帶單元測試

## 關鍵決策記錄

| 決策 | 選擇 | 原因 |
|------|------|------|
| 跨平台框架 | Flutter | 效能優、語音整合成熟、一套代碼 |
| 後端 | Supabase | 免費額度充足、PostgreSQL、即時訂閱 |
| 收費模式 | Freemium 訂閱 | 語音次數為自然付費牆 |
| 狀態管理 | Riverpod | 類型安全、測試友善、Provider 進化版 |

## 常用指令

```bash
# 開發
flutter run
flutter test
flutter analyze

# 建構
flutter build apk --release
flutter build ios --release

# Supabase
supabase start
supabase db push
supabase functions serve
```
