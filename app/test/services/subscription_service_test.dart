import 'package:flutter_test/flutter_test.dart';
import 'package:voiceledger/services/subscription_service.dart';

void main() {
  group('SubscriptionService', () {
    late SubscriptionService service;

    setUp(() {
      service = SubscriptionService();
    });

    group('tier constants', () {
      test('四個層級常數存在', () {
        expect(SubscriptionService.tierFree, 'free');
        expect(SubscriptionService.tierPremium, 'premium');
        expect(SubscriptionService.tierPro, 'pro');
        expect(SubscriptionService.tierFamily, 'family');
      });
    });

    group('getTierFeatures', () {
      test('free 層級有基本功能', () {
        final features = service.getTierFeatures('free');
        expect(features['voiceInput'], true);
        expect(features['manualEntry'], true);
        expect(features['basicAnalytics'], true);
        expect(features['maxTransactionsPerMonth'], 100);
        expect(features['aiFeaturesEnabled'], false);
      });

      test('premium 層級解鎖 AI', () {
        final features = service.getTierFeatures('premium');
        expect(features['aiCategorization'], true);
        expect(features['advancedAnalytics'], true);
        expect(features['passiveTracking'], true);
        expect(features['maxTransactionsPerMonth'], 1000);
        expect(features['aiFeaturesEnabled'], true);
      });

      test('pro 層級解鎖照片分析和 API', () {
        final features = service.getTierFeatures('pro');
        expect(features['photoAnalysis'], true);
        expect(features['apiAccess'], true);
        expect(features['maxTransactionsPerMonth'], isNull); // unlimited
        expect(features['aiFeaturesEnabled'], true);
      });

      test('family 層級支援家庭共享', () {
        final features = service.getTierFeatures('family');
        expect(features['familySharing'], true);
        expect(features['maxFamilyMembers'], 6);
      });

      test('無效層級回傳 free 功能', () {
        final features = service.getTierFeatures('invalid');
        expect(features['voiceInput'], true);
        expect(features['aiFeaturesEnabled'], false);
      });
    });

    group('getTierPricing', () {
      test('free 層級價格為 0', () {
        final pricing = service.getTierPricing('free');
        expect(pricing['monthlyPrice'], 0);
        expect(pricing['yearlyPrice'], 0);
        expect(pricing['currency'], 'TWD');
      });

      test('premium 月費 NT\$99', () {
        final pricing = service.getTierPricing('premium');
        expect(pricing['monthlyPrice'], 99);
        expect(pricing['yearlyPrice'], 999);
      });

      test('pro 月費 NT\$199', () {
        final pricing = service.getTierPricing('pro');
        expect(pricing['monthlyPrice'], 199);
        expect(pricing['yearlyPrice'], 1999);
      });

      test('family 月費 NT\$299', () {
        final pricing = service.getTierPricing('family');
        expect(pricing['monthlyPrice'], 299);
        expect(pricing['yearlyPrice'], 2999);
      });

      test('無效層級回傳 free 價格', () {
        final pricing = service.getTierPricing('invalid');
        expect(pricing['monthlyPrice'], 0);
      });

      test('年費比月費便宜（月費x12 > 年費）', () {
        for (final tier in ['premium', 'pro', 'family']) {
          final pricing = service.getTierPricing(tier);
          final monthly = pricing['monthlyPrice'] as int;
          final yearly = pricing['yearlyPrice'] as int;
          expect(yearly < monthly * 12, true, reason: '$tier 年費應比月費便宜');
        }
      });
    });
  });
}
