# VoiceLedger 語記

> AI 驅動的口說記帳 App — 說一句話，記好每一筆帳

## 特色功能

**語境感知多筆記帳** — 一次說完多筆消費，AI 自動拆分、分類、標記場景

**AI 財務教練** — 不只記帳，主動分析消費模式並給出可執行的省錢建議

**對話式帳本查詢** — 用自然語言問「上個月飲料花了多少？」，AI 即時回答並附帶趨勢分析

**智能發票 OCR** — 拍照掃描 + 語音補充，混合輸入效率最高

**消費預測與異常偵測** — 預測月底支出，偵測異常大額消費即時提醒

## 技術棧

| 層級 | 技術 |
|------|------|
| 前端 | Flutter 3.x + Dart + Riverpod |
| 後端 | Supabase (PostgreSQL + Auth + Edge Functions) |
| AI | OpenAI Whisper + Claude/GPT API |
| 自動化 | n8n + GitHub Actions |
| 付費 | RevenueCat |

## 專案結構

```
voiceledger/
├── .github/          # CI/CD 與 Issue 模板
├── ai/prompts/       # AI Prompt 模板
├── docs/             # 專案規劃書與設計文件
├── app/              # Flutter 主專案 (即將建立)
├── backend/          # Supabase 設定 (即將建立)
├── CLAUDE.md         # AI 開發輔助指引
└── README.md
```

## 開發流程

本專案採用 **OMC 五層生命週期** + **三重審查機制**：

```
L1 需求策略 → L2 架構設計 → L3 開發實作 → L4 交付部署 → L5 營運監控
     ↓              ↓              ↓              ↓              ↓
  [R1+R2+R3]    [R1+R2+R3]    [R1+R2+R3]    [R1+R2+R3]    [R1+R2+R3]
```

- **R1**: AI 自動審查 (程式碼品質、安全)
- **R2**: 人工確認審查 (業務邏輯、UX)
- **R3**: 整合驗證審查 (自動測試、效能)

## 收費模式

| 方案 | 價格 | 重點功能 |
|------|------|---------|
| Free | 免費 | 每月 30 筆語音記帳 |
| Pro | NT$ 99/月 | 無限語音 + AI 分類 + 財務教練 |
| Premium | NT$ 199/月 | 對話式查詢 + 消費預測 + 家庭共享 |

## 里程碑

- [x] M0: 專案規劃與 Repo 建立
- [ ] M1: 架構設計 (Week 2-3)
- [ ] M2: MVP 核心功能 (Week 4-7)
- [ ] M3: AI 增強功能 (Week 8-10)
- [ ] M4: 付費系統 (Week 11-12)
- [ ] M5: Beta 測試 (Week 13-14)
- [ ] M6: 正式上架 (Week 15-16)

## License

MIT
