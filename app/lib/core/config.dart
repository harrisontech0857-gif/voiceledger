import 'env.dart';

/// 應用程式設定
///
/// 使用 Env 類中定義的環境變數
class AppConfig {
  AppConfig._();

  /// Supabase 項目 URL
  static String get supabaseUrl => Env.supabaseUrl;

  /// Supabase 匿名公鑰
  static String get supabaseAnonKey => Env.supabaseAnonKey;

  /// 啟用 AI API 功能
  static bool get enableAiApi => Env.enableAiApi == 'true';

  /// 啟用語音辨識 API
  static bool get enableSpeechToText => Env.enableSpeechToText == 'true';

  /// Mock 模式：當 Supabase 未設定時
  static bool get isMockMode =>
      supabaseUrl.isEmpty || supabaseUrl.contains('xxx');
}
