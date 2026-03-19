import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voiceledger/services/usage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock SharedPreferences
  final Map<String, dynamic> storage = {};

  setUp(() {
    storage.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (MethodCall methodCall) async {
            switch (methodCall.method) {
              case 'getAll':
                return Map<String, dynamic>.from(storage);
              case 'setString':
                final args = methodCall.arguments as Map;
                storage['flutter.${args['key']}'] = args['value'];
                return true;
              case 'setInt':
                final args = methodCall.arguments as Map;
                storage['flutter.${args['key']}'] = args['value'];
                return true;
              default:
                return null;
            }
          },
        );
  });

  group('UsageService Tests', () {
    late UsageService service;

    setUp(() {
      service = UsageService();
    });

    test('should start with zero usage', () async {
      final voice = await service.getVoiceUsage();
      expect(voice, equals(0));
    });

    test('canUseVoice should return true when under limit', () async {
      final canUse = await service.canUseVoice();
      expect(canUse, isTrue);
    });

    test('canUseVoice always true for premium', () async {
      final canUse = await service.canUseVoice(isPremium: true);
      expect(canUse, isTrue);
    });

    test('recordVoiceUsage should increment count', () async {
      final count1 = await service.recordVoiceUsage();
      final count2 = await service.recordVoiceUsage();
      expect(count1, equals(1));
      expect(count2, equals(2));
    });

    test('getRemainingQuota shows correct values', () async {
      // 使用全新 service 確保 state 乾淨
      final freshService = UsageService();
      // 先取得初始值
      final initialVoice = await freshService.getVoiceUsage();
      await freshService.recordVoiceUsage();
      await freshService.recordChatUsage();
      final quota = await freshService.getRemainingQuota();
      // 語音使用了 initialVoice+1 次
      expect(
        quota['voice'],
        equals(UsageService.freeVoiceLimit - initialVoice - 1),
      );
      expect(quota['chat'], lessThanOrEqualTo(UsageService.freeChatLimit));
      expect(quota['diary'], equals(UsageService.freeDiaryLimit));
    });

    test('getRemainingQuota returns -1 for premium', () async {
      final quota = await service.getRemainingQuota(isPremium: true);
      expect(quota['voice'], equals(-1));
      expect(quota['chat'], equals(-1));
      expect(quota['diary'], equals(-1));
    });

    test('limits are correct', () {
      expect(UsageService.freeVoiceLimit, equals(30));
      expect(UsageService.freeChatLimit, equals(10));
      expect(UsageService.freeDiaryLimit, equals(5));
    });
  });
}
