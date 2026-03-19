/// 環境變數配置
///
/// 使用 --dart-define 或 .env 設定值
/// 例: flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co
class Env {
  Env._();

  /// Supabase 項目 URL
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://dpqgrwoqalwfodblctqm.supabase.co',
  );

  /// Supabase 匿名公鑰
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRwcWdyd29xYWx3Zm9kYmxjdHFtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM3ODY5MDEsImV4cCI6MjA4OTM2MjkwMX0.LmHYN5taxI-IXZDF-zjU-RHeuPQmJm1ksmwByglaf8k',
  );

  /// RevenueCat API 金鑰（可選）
  static const String revenuecatApiKey = String.fromEnvironment(
    'REVENUECAT_API_KEY',
    defaultValue: '',
  );

  /// OpenAI API 金鑰（可選）
  static const String openaiApiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '',
  );

  /// 應用環境: 'dev' | 'staging' | 'prod'
  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  /// 啟用 AI API 功能
  static const String enableAiApi = String.fromEnvironment(
    'ENABLE_AI_API',
    defaultValue: 'false',
  );

  /// 啟用 RevenueCat 訂閱
  static const String enableRevenueCat = String.fromEnvironment(
    'ENABLE_REVENUECAT',
    defaultValue: 'false',
  );

  /// 啟用語音辨識 API
  static const String enableSpeechToText = String.fromEnvironment(
    'ENABLE_SPEECH_TO_TEXT',
    defaultValue: 'false',
  );

  /// 是否為開發模式
  static bool get isDev => appEnv == 'dev';

  /// 是否啟用 AI
  static bool get isAiEnabled => enableAiApi == 'true';

  /// 是否啟用訂閱
  static bool get isSubscriptionEnabled => enableRevenueCat == 'true';

  /// 是否啟用語音辨識
  static bool get isSpeechEnabled => enableSpeechToText == 'true';
}
