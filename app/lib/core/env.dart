import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  /// Supabase 項目 URL
  /// 例: https://dpqgrwoqalwfodblctqm.supabase.co
  @EnviedField(varName: 'SUPABASE_URL', obfuscate: true)
  static const String supabaseUrl = _Env.supabaseUrl;

  /// Supabase 匿名公鑰
  /// 設置時請使用真實的 anon key
  @EnviedField(varName: 'SUPABASE_ANON_KEY', obfuscate: true)
  static const String supabaseAnonKey = _Env.supabaseAnonKey;

  /// RevenueCat API 金鑰（可選，用於訂閱管理）
  /// 設置 ENABLE_REVENUECAT=true 時使用
  @EnviedField(varName: 'REVENUECAT_API_KEY', obfuscate: true)
  static const String revenuecatApiKey = _Env.revenuecatApiKey;

  /// OpenAI API 金鑰（可選，用於 AI 功能）
  /// 設置 ENABLE_AI_API=true 時使用
  @EnviedField(varName: 'OPENAI_API_KEY', obfuscate: true)
  static const String openaiApiKey = _Env.openaiApiKey;

  /// 應用環境: 'dev' (開發) | 'staging' (測試) | 'prod' (生產)
  @EnviedField(varName: 'APP_ENV', defaultValue: 'dev')
  static const String appEnv = _Env.appEnv;

  /// 啟用 AI API 功能 (true/false)
  /// 為 false 時使用 mock 回覆
  @EnviedField(varName: 'ENABLE_AI_API', defaultValue: 'false')
  static const String enableAiApi = _Env.enableAiApi;

  /// 啟用 RevenueCat 訂閱 (true/false)
  /// 為 false 時使用 mock 訂閱系統
  @EnviedField(varName: 'ENABLE_REVENUECAT', defaultValue: 'false')
  static const String enableRevenueCat = _Env.enableRevenueCat;

  /// 啟用語音辨識 API (true/false)
  /// 為 false 時使用 mock 辨識結果
  @EnviedField(varName: 'ENABLE_SPEECH_TO_TEXT', defaultValue: 'false')
  static const String enableSpeechToText = _Env.enableSpeechToText;
}
