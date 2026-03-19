import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/env.dart';
import 'core/config.dart';
import 'core/app_router.dart';
import 'core/theme.dart';

/// 全域 mock 模式旗標
bool kMockMode = false;

/// Gemini API Key（設定後自動啟用 Gemini AI 模式）
/// 免費取得：https://aistudio.google.com/apikey
String kGeminiApiKey = const String.fromEnvironment(
  'GEMINI_API_KEY',
  defaultValue: '',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化中文日期格式
  await initializeDateFormatting('zh_TW', null);

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

/// Web 桌面端響應式外框 — 限制最大寬度並置中，模擬手機尺寸
class _ResponsiveFrame extends StatelessWidget {
  final Widget child;
  const _ResponsiveFrame({required this.child});

  static const double _maxMobileWidth = 430;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // 手機寬度內不加外框
    if (screenWidth <= _maxMobileWidth + 40) {
      return child;
    }

    // 桌面寬度：加陰影外框 + 背景
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: Center(
        child: Container(
          width: _maxMobileWidth,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(30),
                blurRadius: 24,
                spreadRadius: 0,
              ),
            ],
            borderRadius: BorderRadius.circular(0),
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
      ),
    );
  }
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
        // 統一文字大小
        final mq = MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(1.0));
        return MediaQuery(
          data: mq,
          // Web 桌面端：限制最大寬度，模擬手機體驗
          child: _ResponsiveFrame(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}
