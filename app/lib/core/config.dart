/// 應用程式設定
///
/// 包含 Supabase 連線設定及功能開關
/// 註: 此檔案使用常數值，未來可改用 envied 套件進行碼代工產生
library;

class AppConfig {
  /// Supabase 項目 URL
  /// 例: https://dpqgrwoqalwfodblctqm.supabase.co
  static const String supabaseUrl = 'https://dpqgrwoqalwfodblctqm.supabase.co';

  /// Supabase 匿名公鑰
  /// 設置時請使用真實的 anon key
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRwcWdyd29xYWx3Zm9kYmxjdHFtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM3ODY5MDEsImV4cCI6MjA4OTM2MjkwMX0.LmHYN5taxI-IXZDF-zjU-RHeuPQmJm1ksmwByglaf8k';

  /// RevenueCat API 金鑰（可選，用於訂閱管理）
  /// 設置 enableRevenueCat=true 時使用
  static const String revenuecatApiKey = 'mock_rc_key_placeholder';

  /// OpenAI API 金鑰（可選，用於 AI 功能）
  /// 設置 enableAiApi=true 時使用
  static const String openaiApiKey = 'mock_openai_key_placeholder';

  /// 應用環境: 'dev' (開發) | 'staging' (測試) | 'prod' (生產)
  static const String appEnv = 'dev';

  /// 啟用 AI API 功能 (true/false)
  /// 為 false 時使用 mock 回覆
  static const bool enableAiApi = false;

  /// 啟用 RevenueCat 訂閱 (true/false)
  /// 為 false 時使用 mock 訂閱系統
  static const bool enableRevenueCat = false;

  /// 啟用語音辨識 API (true/false)
  /// 為 false 時使用 mock 辨識結果
  static const bool enableSpeechToText = false;

  /// Mock 模式：當所有 AI 相關功能均被禁用時，應用進入模擬模式
  /// 此時所有外部 API 呼叫都將使用模擬回傳值
  static bool get mockMode =>
      !enableAiApi && !enableRevenueCat && !enableSpeechToText;

  /// 是否為開發環境
  static bool get isDevelopment => appEnv == 'dev';

  /// 是否為測試環境
  static bool get isStaging => appEnv == 'staging';

  /// 是否為生產環境
  static bool get isProduction => appEnv == 'prod';
}
