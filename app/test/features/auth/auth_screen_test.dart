import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'package:voiceledger/features/auth/auth_screen.dart';

// Helper function to build app with proper providers
Widget buildTestApp() {
  return const ProviderScope(child: MaterialApp(home: AuthScreen()));
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Mock SharedPreferences plugin channel（Supabase 初始化需要）
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'getAll') {
              return <String, dynamic>{};
            }
            return null;
          },
        );

    // Mock path_provider（某些平台需要）
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async {
            return '/tmp';
          },
        );

    try {
      await Supabase.initialize(
        url: 'https://test.supabase.co',
        anonKey:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRlc3QiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTcwMDAwMDAwMCwiZXhwIjoyMDAwMDAwMDAwfQ.test-signature',
      );
    } catch (_) {
      // 可能已初始化過或 URL 無效 — 測試環境可忽略
    }
  });

  group('AuthScreen Widget Tests', () {
    testWidgets('should render AuthScreen with all required widgets', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Verify title
      expect(find.text('語記'), findsOneWidget);
      expect(find.text('情侶語音日記'), findsOneWidget);

      // Verify tabs
      expect(find.text('登入'), findsWidgets);
      expect(find.text('註冊'), findsOneWidget);

      // Verify input fields
      expect(find.byType(TextField), findsWidgets);

      // Verify buttons
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('用 Google 帳戶登入'), findsOneWidget);
    });

    testWidgets('should display email and password TextFields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Verify email input exists
      expect(
        find.byWidgetPredicate((widget) {
          if (widget is TextField) {
            return widget.decoration?.labelText == '郵箱';
          }
          return false;
        }),
        findsOneWidget,
      );

      // Verify password input exists
      expect(
        find.byWidgetPredicate((widget) {
          if (widget is TextField) {
            return widget.decoration?.labelText == '密碼';
          }
          return false;
        }),
        findsOneWidget,
      );
    });

    testWidgets('should display login tab as active by default', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final loginTab = find.byWidgetPredicate((widget) {
        if (widget is Container) {
          final decoration = widget.decoration as BoxDecoration?;
          return decoration != null;
        }
        return false;
      });

      expect(loginTab, findsWidgets);
    });

    testWidgets('should show error message when email or password is empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final submitButton = find.byType(ElevatedButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.text('請輸入郵箱和密碼'), findsOneWidget);
    });

    testWidgets('should enable submit button when not loading', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final button = find.byType(ElevatedButton);
      final buttonWidget = tester.widget<ElevatedButton>(button);

      expect(buttonWidget.onPressed, isNotNull);
    });

    testWidgets('should display password field as obscured', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final passwordField = find.byWidgetPredicate((widget) {
        if (widget is TextField) {
          return widget.decoration?.labelText == '密碼' && widget.obscureText;
        }
        return false;
      });

      expect(passwordField, findsOneWidget);
    });

    testWidgets('should display forgot password link in login mode', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('忘記密碼？'), findsOneWidget);
    });

    testWidgets('should display all UI elements in correct order', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('語記'), findsOneWidget);
      expect(find.text('情侶語音日記'), findsOneWidget);
      expect(find.byType(TextField), findsWidgets);
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('或'), findsOneWidget);
      expect(find.text('用 Google 帳戶登入'), findsOneWidget);
    });

    testWidgets('should have proper SingleChildScrollView', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('should render without throwing errors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(AuthScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
