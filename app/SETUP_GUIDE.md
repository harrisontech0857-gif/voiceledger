zh-TW# VoiceLedger 設置指南

完整的開發環境配置和項目初始化步驟。

## 前置需求

### 系統要求
- **Flutter**: 3.16.0 或更高版本
- **Dart**: 3.2.0 或更高版本
- **IDE**: VS Code 或 Android Studio
- **平台支持**: iOS 14.0+, Android 8.0+

### 外部服務帳戶
1. **Supabase** (https://supabase.com)
   - 項目 URL
   - Anon 公鑰
   - 數據庫訪問權限

2. **RevenueCat** (https://www.revenuecat.com)
   - API 密鑰

3. **OpenAI** (可選，用於 Edge Functions)
   - API 密鑰

## 第 1 步：環境設置

### 1.1 安裝 Flutter

```bash
# 使用 Flutter 版本管理器 (推薦)
fvm install 3.16.0
fvm use 3.16.0

# 或直接下載
# 訪問: https://flutter.dev/docs/get-started/install
```

### 1.2 檢查環境

```bash
flutter doctor
# 確保所有項目都打上 ✓

# 列出可用的設備
flutter devices
```

### 1.3 克隆項目

```bash
git clone <repository-url> voiceledger
cd voiceledger/app
```

## 第 2 步：配置環境變量

### 2.1 創建 .env 文件

```bash
cp .env.example .env
```

### 2.2 填入配置值

編輯 `.env` 文件:

```env
# Supabase 配置 (從 Supabase 儀表板獲取)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# RevenueCat 配置
REVENUECAT_API_KEY=appl_AbCdEfGhIjKlMnOpQrStUvWxYz...

# OpenAI 配置 (用於 AI 功能)
OPENAI_API_KEY=sk-...

# 環境模式
APP_ENV=dev
```

**獲取 Supabase 密鑰**:
1. 登錄 Supabase 控制台
2. 選擇項目
3. 點擊 "Settings" → "API"
4. 複製 "Project URL" 和 "anon key"

**獲取 RevenueCat 密鑰**:
1. 登錄 RevenueCat 控制台
2. 項目設置
3. 複製 API 密鑰

### 2.3 安全提示

⚠️ **重要**: 不要將 `.env` 文件提交到 Git

確保 `.gitignore` 包含:
```
.env
.env.local
.env.*.local
```

## 第 3 步：依賴安裝

### 3.1 獲取依賴

```bash
flutter pub get
```

### 3.2 代碼生成

生成 Freezed 模型、Riverpod 提供者、JSON 序列化等：

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**可選：監視模式** (開發時自動生成)

```bash
flutter pub run build_runner watch
```

### 3.3 預期生成的文件

檢查是否生成了以下文件：

```
lib/models/transaction.freezed.dart
lib/models/transaction.g.dart
lib/models/user_profile.freezed.dart
lib/models/user_profile.g.dart
lib/core/env.g.dart
```

如果文件不存在，運行:
```bash
flutter clean
flutter pub get
flutter pub run build_runner build
```

## 第 4 步：Supabase 後端配置

### 4.1 創建數據庫表

在 Supabase SQL 編輯器中執行 (使用 psql):

```sql
-- 交易表
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  amount DECIMAL(12, 2) NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
  category TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  description TEXT NOT NULL,
  notes TEXT,
  voice_transcript TEXT,
  photo_url TEXT,
  latitude DECIMAL(9, 6),
  longitude DECIMAL(9, 6),
  location_name TEXT,
  is_recurring BOOLEAN DEFAULT false,
  recurring_frequency TEXT,
  updated_at TIMESTAMP DEFAULT now()
);

-- 創建索引以提高查詢性能
CREATE INDEX transactions_user_id_idx ON transactions(user_id);
CREATE INDEX transactions_created_at_idx ON transactions(created_at DESC);

-- 用戶資料表
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  display_name TEXT,
  avatar_url TEXT,
  bio TEXT,
  total_income DECIMAL(15, 2) DEFAULT 0,
  total_expense DECIMAL(15, 2) DEFAULT 0,
  is_premium BOOLEAN DEFAULT false,
  premium_expires_at TIMESTAMP,
  premium_provider TEXT,
  premium_product_id TEXT,
  locale TEXT DEFAULT 'zh_TW',
  theme_mode TEXT DEFAULT 'light',
  notifications_enabled BOOLEAN DEFAULT true,
  location_tracking_enabled BOOLEAN DEFAULT true,
  voice_input_enabled BOOLEAN DEFAULT true,
  daily_budget DECIMAL(10, 2) DEFAULT 300,
  monthly_budget TEXT,
  voice_entries INT DEFAULT 0,
  last_voice_entry_at TIMESTAMP,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

-- 啟用行級安全 (RLS)
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- RLS 策略：用戶只能看到自己的交易
CREATE POLICY transactions_user_policy ON transactions
  FOR ALL USING (auth.uid() = user_id);

-- RLS 策略：用戶只能看到自己的資料
CREATE POLICY user_profiles_user_policy ON user_profiles
  FOR ALL USING (auth.uid() = id);
```

### 4.2 驗證表結構

在 Supabase 控制台中：
1. 轉到 "Table Editor"
2. 驗證 `transactions` 和 `user_profiles` 表已創建
3. 檢查欄位和索引

### 4.3 設置 RLS 策略

確認行級安全已啟用：
1. 選擇表 → "Auth" 選項卡
2. 確認所有策略都已設置

## 第 5 步：本地開發

### 5.1 在模擬器/設備上運行

```bash
# 列出可用設備
flutter devices

# 在特定設備上運行（調試模式）
flutter run -d <device_id>

# 全屏運行
flutter run

# 特定平台
flutter run -d chrome      # Web
flutter run -d emulator-5555  # Android
```

### 5.2 調試選項

```bash
# 詳細日誌
flutter run -v

# 帶性能分析
flutter run --profile

# 發布模式（最終測試）
flutter run --release
```

### 5.3 主要調試工具

**Dart DevTools**:
```bash
# 在調試會話期間按 'd' 打開
# 或手動開啟
dart devtools
```

**Logcat (Android)**:
```bash
adb logcat | grep flutter
```

**Console (iOS)**:
```bash
xcrun simctl spawn booted log stream --level=debug
```

## 第 6 步：功能配置

### 6.1 麥克風權限（Android）

**AndroidManifest.xml** (`android/app/src/main/AndroidManifest.xml`):

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### 6.2 位置權限（iOS）

**Info.plist** (`ios/Runner/Info.plist`):

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>語記需要您的位置來自動記錄消費地點</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>語記需要您的位置來自動記錄消費地點</string>

<key>NSMicrophoneUsageDescription</key>
<string>語記需要訪問麥克風來進行語音記帳</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>語記需要訪問相機膠卷來分析購物照片</string>
```

### 6.3 測試權限

在應用首次啟動時，系統會請求權限。

檢查權限狀態：
```dart
final hasPermission = await Permission.microphone.isDenied;
```

## 第 7 步：測試應用

### 7.1 運行單元測試

```bash
flutter test
```

### 7.2 運行特定測試文件

```bash
flutter test test/services/voice_service_test.dart
```

### 7.3 集成測試

```bash
flutter test integration_test/app_test.dart
```

### 7.4 測試檢查清單

- [ ] 語音輸入工作正常
- [ ] AI 秘書返回回應
- [ ] 交易已保存到 Supabase
- [ ] 位置追蹤正常工作
- [ ] 深色模式切換
- [ ] 登出正確清除緩存

## 第 8 步：構建用於發布

### 8.1 Android APK

```bash
# 創建簽名密鑰 (首次)
keytool -genkey -v -keystore ~/key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias my-key-alias

# 創建 key.properties
echo "storePassword=<password>" > android/key.properties
echo "keyPassword=<password>" >> android/key.properties
echo "keyAlias=my-key-alias" >> android/key.properties
echo "storeFile=<path-to-key.jks>" >> android/key.properties

# 構建 APK
flutter build apk --split-per-abi

# 或完整應用包 (推薦在 Play Store 上傳)
flutter build appbundle
```

### 8.2 iOS IPA

```bash
# 構建 release 版本
flutter build ios --release

# 通過 Xcode 發布
open ios/Runner.xcworkspace
# 選擇 Product → Archive
```

### 8.3 構建選項

```bash
# 啟用混淆 (Android)
flutter build apk --obfuscate --split-debug-info=<output>

# 指定構建號
flutter build apk --build-number=2 --build-name=1.0.1
```

## 第 9 步：性能優化

### 9.1 使用發布模式測試

```bash
flutter run --release
```

### 9.2 分析應用大小

```bash
flutter build apk --analyze-size
```

### 9.3 檢查依賴

```bash
flutter pub outdated
```

## 故障排除

### 問題：Build Runner 錯誤

**解決方案**:
```bash
flutter clean
rm -rf .dart_tool/
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### 問題：語音識別不工作

**檢查項**:
- [ ] 麥克風權限已授予
- [ ] 語言設置為 zh_TW
- [ ] 網絡連接正常
- [ ] 設備麥克風正常

**修復**:
```dart
final isInitialized = await voiceService.initialize();
if (!isInitialized) {
  print('Speech to text initialization failed');
}
```

### 問題：Supabase 連接失敗

**檢查項**:
- [ ] `.env` 中的 URL 正確
- [ ] ANON_KEY 有效
- [ ] 網絡連接正常
- [ ] Supabase 項目正在運行

**測試連接**:
```dart
final client = Supabase.instance.client;
final response = await client.auth.getSession();
print('Auth session: $response');
```

### 問題：深色模式未切換

**檢查項**:
- [ ] `isDarkModeProvider` 已初始化
- [ ] Theme 應用 `themeMode: isDarkMode ? ... : ...`

### 問題：位置追蹤不工作

**檢查項**:
- [ ] 位置權限已授予
- [ ] 設備位置服務已啟用
- [ ] 使用物理設備（模擬器不可靠）
- [ ] 沒有 GPS 信號的地方可能延遲

## 常用命令速查

```bash
# 日常開發
flutter run                              # 運行應用
flutter pub get                          # 安裝依賴
flutter pub run build_runner watch       # 監視代碼生成
flutter format lib/                      # 格式化代碼
flutter analyze                          # 代碼分析

# 測試
flutter test                             # 運行所有測試
flutter test -v                          # 詳細輸出

# 構建
flutter build apk                        # 構建 Android APK
flutter build ios                        # 構建 iOS app
flutter build web                        # 構建 Web 應用

# 清理和重置
flutter clean                            # 清除構建工件
flutter pub cache repair                 # 修復包緩存
flutter config --no-analytics            # 禁用分析

# 設備和模擬器
flutter devices                          # 列出可用設備
flutter emulators                        # 列出可用模擬器
flutter emulators --launch <id>          # 啟動模擬器
```

## 下一步

完成此設置後：

1. 📖 閱讀 `README.md` 了解功能概述
2. 📁 查看 `PROJECT_STRUCTURE.md` 理解代碼組織
3. 🔧 配置 Edge Functions 用於 AI 功能
4. 🧪 編寫和運行測試
5. 📱 在真實設備上測試
6. 🚀 準備發布構建

## 獲取幫助

- **官方文檔**: https://flutter.dev/docs
- **Supabase 文檔**: https://supabase.com/docs
- **Riverpod 文檔**: https://riverpod.dev
- **GitHub Issues**: 報告 bug 或請求功能

---

**最後更新**: 2026年3月18日
**維護者**: VoiceLedger 開發團隊
