import 'package:flutter_test/flutter_test.dart';
import 'package:voiceledger/models/user_profile.dart';

void main() {
  group('UserProfile Model', () {
    late UserProfile profile;

    setUp(() {
      profile = UserProfile(
        id: 'user-001',
        email: 'test@example.com',
        displayName: '測試用戶',
        createdAt: DateTime(2026, 1, 1),
      );
    });

    group('constructor defaults', () {
      test('預設值正確', () {
        expect(profile.totalIncome, 0);
        expect(profile.totalExpense, 0);
        expect(profile.isPremium, false);
        expect(profile.locale, 'zh_TW');
        expect(profile.themeMode, 'light');
        expect(profile.notificationsEnabled, true);
        expect(profile.locationTrackingEnabled, true);
        expect(profile.voiceInputEnabled, true);
        expect(profile.voiceEntries, 0);
        expect(profile.metadata, isEmpty);
      });

      test('必填欄位正確', () {
        expect(profile.id, 'user-001');
        expect(profile.email, 'test@example.com');
        expect(profile.displayName, '測試用戶');
      });

      test('可選欄位預設為 null', () {
        expect(profile.avatarUrl, isNull);
        expect(profile.bio, isNull);
        expect(profile.updatedAt, isNull);
        expect(profile.premiumExpiresAt, isNull);
        expect(profile.premiumProvider, isNull);
        expect(profile.lastVoiceEntryAt, isNull);
      });
    });

    group('fromJson', () {
      test('snake_case JSON 正確解析', () {
        final json = {
          'id': 'u-1',
          'email': 'a@b.com',
          'display_name': 'User A',
          'created_at': '2026-01-01T00:00:00Z',
          'total_income': 50000.0,
          'total_expense': 30000.0,
          'is_premium': true,
          'locale': 'en_US',
          'daily_budget': 500.0,
          'voice_entries': 42,
        };
        final p = UserProfile.fromJson(json);
        expect(p.id, 'u-1');
        expect(p.displayName, 'User A');
        expect(p.totalIncome, 50000.0);
        expect(p.totalExpense, 30000.0);
        expect(p.isPremium, true);
        expect(p.voiceEntries, 42);
      });

      test('camelCase JSON 也能解析', () {
        final json = {
          'id': 'u-2',
          'email': 'b@c.com',
          'displayName': 'User B',
          'createdAt': '2026-02-01T00:00:00Z',
          'totalIncome': 10000.0,
        };
        final p = UserProfile.fromJson(json);
        expect(p.id, 'u-2');
        expect(p.displayName, 'User B');
        expect(p.totalIncome, 10000.0);
      });

      test('缺失欄位使用預設值', () {
        final json = {
          'id': 'u-3',
          'email': 'c@d.com',
          'created_at': '2026-01-01T00:00:00Z',
        };
        final p = UserProfile.fromJson(json);
        expect(p.displayName, '');
        expect(p.isPremium, false);
        expect(p.dailyBudget, 5);
      });
    });

    group('toJson', () {
      test('序列化包含所有欄位', () {
        final json = profile.toJson();
        expect(json['id'], 'user-001');
        expect(json['email'], 'test@example.com');
        expect(json['display_name'], '測試用戶');
        expect(json['is_premium'], false);
        expect(json['locale'], 'zh_TW');
      });

      test('toJson → fromJson 往返一致', () {
        final json = profile.toJson();
        final restored = UserProfile.fromJson(json);
        expect(restored.id, profile.id);
        expect(restored.email, profile.email);
        expect(restored.displayName, profile.displayName);
        expect(restored.isPremium, profile.isPremium);
      });
    });

    group('copyWith', () {
      test('覆寫單一欄位', () {
        final copy = profile.copyWith(displayName: '新名字');
        expect(copy.displayName, '新名字');
        expect(copy.email, profile.email);
      });

      test('覆寫多個欄位', () {
        final copy = profile.copyWith(
          isPremium: true,
          totalIncome: 100000,
          voiceEntries: 50,
        );
        expect(copy.isPremium, true);
        expect(copy.totalIncome, 100000);
        expect(copy.voiceEntries, 50);
      });
    });
  });
}
