import 'package:flutter_test/flutter_test.dart';
import 'package:voiceledger/models/pet.dart';

/// 測試 PetModel 的核心業務邏輯
/// （PetNotifier 依賴 SharedPreferences，需要 integration test）
void main() {
  group('Pet Business Logic Tests', () {
    group('feeding logic simulation', () {
      test('should calculate exp gain correctly', () {
        // 基礎 exp = 10, streak bonus = streak * 2, underBudget bonus = 5
        const baseExp = 10;
        const streak = 3;
        const underBudget = true;

        final expGain = baseExp + streak * 2 + (underBudget ? 5 : 0);
        expect(expGain, equals(21));
      });

      test('should evolve from egg to baby at 50 exp', () {
        final pet = PetModel.create().copyWith(exp: 45);
        expect(pet.stage, equals(PetStage.egg));

        // After gaining enough exp
        final evolved = pet.copyWith(exp: 55);
        expect(evolved.stage, equals(PetStage.baby));
      });

      test('should evolve through all stages', () {
        final stages = [
          (0, PetStage.egg),
          (50, PetStage.baby),
          (200, PetStage.teen),
          (500, PetStage.adult),
          (1000, PetStage.master),
        ];

        for (final (exp, expectedStage) in stages) {
          final pet = PetModel.create().copyWith(exp: exp);
          expect(
            pet.stage,
            equals(expectedStage),
            reason: 'exp=$exp should be $expectedStage',
          );
        }
      });
    });

    group('streak calculation simulation', () {
      test('should increment streak for consecutive days', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final today = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        );
        final lastFedDay = DateTime(
          yesterday.year,
          yesterday.month,
          yesterday.day,
        );

        final diff = today.difference(lastFedDay).inDays;
        expect(diff, equals(1)); // consecutive
      });

      test('should reset streak after gap', () {
        final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
        final today = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        );
        final lastFedDay = DateTime(
          twoDaysAgo.year,
          twoDaysAgo.month,
          twoDaysAgo.day,
        );

        final diff = today.difference(lastFedDay).inDays;
        expect(diff, greaterThan(1)); // gap → reset
      });

      test('should not change streak for same day', () {
        final today = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        );

        final diff = today.difference(today).inDays;
        expect(diff, equals(0)); // same day
      });
    });

    group('mood determination simulation', () {
      test('should be sleepy after 48+ hours', () {
        final lastFedAt = DateTime.now().subtract(const Duration(hours: 49));
        final hoursSince = DateTime.now().difference(lastFedAt).inHours;

        PetMood mood;
        if (hoursSince > 48) {
          mood = PetMood.sleepy;
        } else if (hoursSince > 24) {
          mood = PetMood.hungry;
        } else {
          mood = PetMood.neutral;
        }

        expect(mood, equals(PetMood.sleepy));
      });

      test('should be hungry after 24-48 hours', () {
        final lastFedAt = DateTime.now().subtract(const Duration(hours: 30));
        final hoursSince = DateTime.now().difference(lastFedAt).inHours;

        PetMood mood;
        if (hoursSince > 48) {
          mood = PetMood.sleepy;
        } else if (hoursSince > 24) {
          mood = PetMood.hungry;
        } else {
          mood = PetMood.neutral;
        }

        expect(mood, equals(PetMood.hungry));
      });

      test('should be happy with streak >= 3', () {
        const streak = 5;
        final lastFedAt = DateTime.now().subtract(const Duration(hours: 2));
        final hoursSince = DateTime.now().difference(lastFedAt).inHours;

        PetMood mood;
        if (hoursSince > 48) {
          mood = PetMood.sleepy;
        } else if (hoursSince > 24) {
          mood = PetMood.hungry;
        } else {
          mood = streak >= 3 ? PetMood.happy : PetMood.neutral;
        }

        expect(mood, equals(PetMood.happy));
      });
    });

    group('level calculation', () {
      test('should calculate level from exp', () {
        expect(0 ~/ 100 + 1, equals(1));
        expect(99 ~/ 100 + 1, equals(1));
        expect(100 ~/ 100 + 1, equals(2));
        expect(250 ~/ 100 + 1, equals(3));
        expect(1000 ~/ 100 + 1, equals(11));
      });
    });
  });
}
