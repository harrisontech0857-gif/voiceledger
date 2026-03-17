import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'SUPABASE_URL', obfuscate: true)
  static const String supabaseUrl = _Env.supabaseUrl;

  @EnviedField(varName: 'SUPABASE_ANON_KEY', obfuscate: true)
  static const String supabaseAnonKey = _Env.supabaseAnonKey;

  @EnviedField(varName: 'REVENUECAT_API_KEY', obfuscate: true)
  static const String revenuecatApiKey = _Env.revenuecatApiKey;

  @EnviedField(varName: 'OPENAI_API_KEY', obfuscate: true)
  static const String openaiApiKey = _Env.openaiApiKey;

  @EnviedField(varName: 'APP_ENV', defaultValue: 'dev')
  static const String appEnv = _Env.appEnv;
}
