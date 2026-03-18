import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  final Logger _logger = Logger();

  factory SubscriptionService() {
    return _instance;
  }

  SubscriptionService._internal();

  static const String tierFree = 'free';
  static const String tierPremium = 'premium';
  static const String tierPro = 'pro';
  static const String tierFamily = 'family';

  Future<String> getCurrentTier() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('currentTier') ?? tierFree;
    } catch (e) {
      _logger.e('Error getting current tier: $e');
      return tierFree;
    }
  }

  Future<void> setCurrentTier(String tier) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentTier', tier);
    } catch (e) {
      _logger.e('Error setting current tier: $e');
      rethrow;
    }
  }

  Map<String, dynamic> getTierFeatures(String tier) {
    const features = {
      tierFree: {
        'voiceInput': true,
        'manualEntry': true,
        'basicAnalytics': true,
        'maxTransactionsPerMonth': 100,
        'aiFeaturesEnabled': false,
      },
      tierPremium: {
        'voiceInput': true,
        'manualEntry': true,
        'aiCategorization': true,
        'advancedAnalytics': true,
        'passiveTracking': true,
        'maxTransactionsPerMonth': 1000,
        'aiFeaturesEnabled': true,
      },
      tierPro: {
        'voiceInput': true,
        'manualEntry': true,
        'aiCategorization': true,
        'advancedAnalytics': true,
        'passiveTracking': true,
        'photoAnalysis': true,
        'apiAccess': true,
        'maxTransactionsPerMonth': null,
        'aiFeaturesEnabled': true,
      },
      tierFamily: {
        'voiceInput': true,
        'manualEntry': true,
        'aiCategorization': true,
        'advancedAnalytics': true,
        'passiveTracking': true,
        'photoAnalysis': true,
        'familySharing': true,
        'maxTransactionsPerMonth': null,
        'maxFamilyMembers': 6,
        'aiFeaturesEnabled': true,
      },
    };

    return features[tier] ?? features[tierFree] ?? {};
  }

  Map<String, dynamic> getTierPricing(String tier) {
    const pricing = {
      tierFree: {'monthlyPrice': 0, 'yearlyPrice': 0, 'currency': 'TWD'},
      tierPremium: {
        'monthlyPrice': 99,
        'yearlyPrice': 999,
        'currency': 'TWD',
      },
      tierPro: {
        'monthlyPrice': 199,
        'yearlyPrice': 1999,
        'currency': 'TWD',
      },
      tierFamily: {
        'monthlyPrice': 299,
        'yearlyPrice': 2999,
        'currency': 'TWD',
      },
    };

    return pricing[tier] ?? pricing[tierFree] ?? {};
  }

  Future<bool> hasFeature(String featureName) async {
    try {
      final tier = await getCurrentTier();
      final features = getTierFeatures(tier);
      return features[featureName] ?? false;
    } catch (e) {
      _logger.e('Error checking feature: $e');
      return false;
    }
  }
}
