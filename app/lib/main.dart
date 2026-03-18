import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/env.dart';
import 'core/config.dart';
import 'core/app_router.dart';
import 'core/theme.dart';

/// 全域 mock 模式旗標
bool kMockMode = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 判斷是否進入 mock 模式（缺少 Supabase 設定時自動啟用）
  if (AppConfig.isMockMode || Env.supabaseAnonKey.isEmpty) {
    kMockMode = true;
    debugPrint('⚡ 語記 — Mock 模式啟動（無需後端）');
  } else {
    try {
      await Supabase.initialize(
        url: Env.supabaseUrl,
        anonKey: Env.supabaseAnonKey,
      );
    } catch (e) {
      kMockMode = true;
      debugPrint('⚠️ Supabase 初始化失敗，切換至 Mock 模式: $e');
    }
  }

  runApp(const ProviderScope(child: VoiceLedgerApp()));
}

/// 主應用程式
class VoiceLedgerApp extends ConsumerWidget {
  const VoiceLedgerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: '語記 - AI 財務秘書',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
