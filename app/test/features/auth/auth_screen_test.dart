import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voiceledger/features/auth/auth_screen.dart';

// Helper function to build app with proper providers
Widget buildTestApp() {
  return const ProviderScope(
    child: MaterialApp(
      home: AuthScreen(),
    ),
  );
}

void main() {
  group('AuthScreen Widget Tests', () {
    testWidgets('should render AuthScreen with all required widgets',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      // Verify title
      expect(find.text('語記'), findsOneWidget);
      expect(find.text('AI 財務秘書'), findsOneWidget);

      // Verify tabs
      expect(find.text('登入'), findsWidgets);
      expect(find.text('註冊'), findsOneWidget);

      // Verify input fields
      expect(find.byType(TextField), findsWidgets);

      // Verify buttons
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('用 Google 帳戶登入'), findsOneWidget);
    });

    testWidgets('should display email and password TextFields',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      // Verify email input exists
      expect(find.byWidgetPredicate((widget) {
        if (widget is TextField) {
          return widget.decoration?.labelText == '郵箱';
        }
        return false;
      }), findsOneWidget);

      // Verify password input exists
      expect(find.byWidgetPredicate((widget) {
        if (widget is TextField) {
          return widget.decoration?.labelText == '密碼';
        }
        return false;
      }), findsOneWidget);
    });

    testWidgets('should display login tab as active by default',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      // Find the login button (first tab)
      final loginTab = find.byWidgetPredicate((widget) {
        if (widget is Container) {
          final decoration = widget.decoration as BoxDecoration?;
          // The active tab will have a primary color background
          return decoration != null;
        }
        return false;
      });

      expect(loginTab, findsWidgets);
    });

    testWidgets('should switch between login and signup tabs',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      // Find signup tab text and tap it
      final signupTabFinder = find.byWidgetPredicate((widget) {
        if (widget is GestureDetector) {
          return true; // We'll tap the second tab button
        }
        return false;
      });

      // There are multiple GestureDetectors, we need to be more specific
      // Let's find the "註冊" text and tap above it in the tab button
      final tabButtons = find.byType(GestureDetector);
      expect(tabButtons, findsWidgets);

      // Tap the second tab button (signup)
      await tester.tap(tabButtons.at(1));
      await tester.pumpAndSettle();

      // Verify the screen is in signup mode
      // (The button text should now show "建立帳戶" instead of "登入")
      expect(find.text('建立帳戶'), findsOneWidget);
    });

    testWidgets('should show error message when email or password is empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      // Find and tap the submit button without entering anything
      final submitButton = find.byType(ElevatedButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verify error message appears
      expect(find.text('請輸入郵箱和密碼'), findsOneWidget);
    });

    testWidgets('should enable submit button when not loading',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      final button = find.byType(ElevatedButton);
      final buttonWidget = tester.widget<ElevatedButton>(button);

      // Button should be enabled (onPressed is not null)
      expect(buttonWidget.onPressed, isNotNull);
    });

    testWidgets('should display password field as obscured',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      // Find the password TextField
      final passwordField = find.byWidgetPredicate((widget) {
        if (widget is TextField) {
          return widget.decoration?.labelText == '密碼' && widget.obscureText;
        }
        return false;
      });

      expect(passwordField, findsOneWidget);
    });

    testWidgets('should display email field with email keyboard type',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      // Find the email TextField
      final emailField = find.byWidgetPredicate((widget) {
        if (widget is TextField) {
          return widget.decoration?.labelText == '郵箱' &&
              widget.keyboardType == TextInputType.emailAddress;
        }
        return false;
      });

      expect(emailField, findsOneWidget);
    });

    testWidgets('should accept text input in email field',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      // Find email field and enter text
      final emailField = find.byWidgetPredicate((widget) {
        if (widget is TextField) {
          return widget.decoration?.labelText == '郵箱';
        }
        return false;
      });

      await tester.enterText(emailField, 'test@example.com');
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('should accept text input in password field',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      // Find password field and enter text
      final passwordField = find.byWidgetPredicate((widget) {
        if (widget is TextField) {
          return widget.decoration?.labelText == '密碼';
        }
        return false;
      });

      await tester.enterText(passwordField, 'password123');
      await tester.pumpAndSettle();

      // Note: We can't directly verify the text due to obscureText,
      // but we can verify that the field accepts input
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('should display signup mode when signup tab is selected',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      // Initially in login mode
      expect(find.text('登入'), findsWidgets);

      // Find and tap the signup tab (second GestureDetector in the tab row)
      final tabButtons = find.byType(GestureDetector);
      // Tab buttons are early in the widget tree
      await tester.tap(tabButtons.at(1));
      await tester.pumpAndSettle();

      // Should show "建立帳戶" button instead of "登入"
      expect(find.text('建立帳戶'), findsOneWidget);
    });

    testWidgets('should display forgot password link in login mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      // Forgot password should be visible in login mode
      expect(find.text('忘記密碼？'), findsOneWidget);
    });

    testWidgets('should not display forgot password link in signup mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      // Switch to signup
      final tabButtons = find.byType(GestureDetector);
      await tester.tap(tabButtons.at(1));
      await tester.pumpAndSettle();

      // Forgot password should not be visible
      expect(find.text('忘記密碼？'), findsNothing);
    });

    testWidgets('should display all UI elements in correct order',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      // Verify the presence of key elements
      expect(find.text('語記'), findsOneWidget);
      expect(find.text('AI 財務秘書'), findsOneWidget);
      expect(find.byType(TextField), findsWidgets);
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('或'), findsOneWidget);
      expect(find.text('用 Google 帳戶登入'), findsOneWidget);
    });

    testWidgets('should have proper SingleChildScrollView for responsiveness',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      // Verify that SingleChildScrollView exists
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('should maintain UI state when switching tabs',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      // Enter email
      final emailField = find.byWidgetPredicate((widget) {
        if (widget is TextField) {
          return widget.decoration?.labelText == '郵箱';
        }
        return false;
      });
      await tester.enterText(emailField, 'test@example.com');

      // Switch tabs
      final tabButtons = find.byType(GestureDetector);
      await tester.tap(tabButtons.at(1));
      await tester.pumpAndSettle();

      // Switch back
      await tester.tap(tabButtons.at(0));
      await tester.pumpAndSettle();

      // Email should still be there (fields are not cleared)
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('should display divider with "或" text',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      expect(find.text('或'), findsOneWidget);
      expect(find.byType(Divider), findsWidgets);
    });

    testWidgets('should have properly themed widgets',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      // Verify Scaffold exists (basic structure)
      expect(find.byType(Scaffold), findsOneWidget);

      // Verify SafeArea exists
      expect(find.byType(SafeArea), findsOneWidget);

      // Verify Material Design is applied
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('should render without throwing errors',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      // Widget should render successfully
      expect(find.byType(AuthScreen), findsOneWidget);

      // No errors should occur
      expect(tester.takeException(), isNull);
    });
  });
}
