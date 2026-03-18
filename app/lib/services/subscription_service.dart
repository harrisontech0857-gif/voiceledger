import 'package:supabase_flutter/supabase_flutter.dart';

/// 訂閱管理服務
/// 負責管理應用訂閱，支持 RevenueCat 集成或 mock 模式
class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();

  factory SubscriptionService() {
    return _instance;
  }

  SubscriptionService._internal();

  final _supabase = Supabase.instance.client;

  // 訂閱層級
  static const String TIER_FREE = 'free';
  static const String TIER_PREMIUM = 'premium';
  static const String TIER_PRO = 'pro';
  static const String TIER_FAMILY = 'family';

  /// 獲取用戶的訂閱狀態
  Future<Map<String, dynamic>?> getUserSubscription() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('用戶未登錄');

      final response = await _supabase
          .from('user_subscriptions')
          .select(
            'id, plan_id, status, started_at, trial_ends_at, renews_at, cancelled_at, expires_at',
          )
          .eq('user_id', userId)
          .order('started_at', ascending: false)
          .limit(1);

      if ((response as List).isEmpty) {
        // 用戶沒有訂閱，返回默認免費版
        return {
          'plan_id': null,
          'tier': TIER_FREE,
          'status': 'active',
          'started_at': DateTime.now().toIso8601String(),
        };
      }

      final subscription = response[0];

      // 獲取計劃詳情
      final planResponse = await _supabase
          .from('subscription_plans')
          .select()
          .eq('id', subscription['plan_id'])
          .single();

      return {
        ...subscription,
        'plan': planResponse,
        'tier': planResponse['tier'],
      };
    } catch (e) {
      print('獲取訂閱狀態失敗：$e');
      return null;
    }
  }

  /// 獲取所有可用的訂閱方案
  Future<List<Map<String, dynamic>>> getSubscriptionPlans() async {
    try {
      final response = await _supabase
          .from('subscription_plans')
          .select()
          .eq('is_active', true)
          .order('price', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('獲取訂閱方案失敗：$e');
      return [];
    }
  }

  /// 檢查用戶是否具有特定功能
  Future<bool> hasFeature(String featureName) async {
    try {
      final subscription = await getUserSubscription();
      if (subscription == null) return false;

      final tier = subscription['tier'] as String?;
      final plan = subscription['plan'] as Map<String, dynamic>?;

      if (tier == TIER_FREE) {
        // 免費版功能
        return [
          'voice_input',
          'manual_entry',
          'basic_analytics',
        ].contains(featureName);
      }

      if (plan == null) return false;

      final features = plan['features'] as Map<String, dynamic>?;
      return features?.containsKey(featureName) ?? false;
    } catch (e) {
      print('檢查功能失敗：$e');
      return false;
    }
  }

  /// 開始免費試用
  Future<void> startFreeTrial({
    required String planId,
    int trialDays = 14,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('用戶未登錄');

      final trialEndsAt = DateTime.now()
          .add(Duration(days: trialDays))
          .toIso8601String();

      await _supabase.from('user_subscriptions').insert({
        'user_id': userId,
        'plan_id': planId,
        'status': 'trial',
        'started_at': DateTime.now().toIso8601String(),
        'trial_ends_at': trialEndsAt,
      });
    } catch (e) {
      print('開始免費試用失敗：$e');
      rethrow;
    }
  }

  /// 升級訂閱（Mock 版本）
  Future<void> upgradeSubscription({
    required String planId,
    String paymentMethod = 'mock', // 實際版本會使用 RevenueCat
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('用戶未登錄');

      // 檢查用戶是否已有訂閱
      final existing = await _supabase
          .from('user_subscriptions')
          .select('id')
          .eq('user_id', userId)
          .eq('status', 'active');

      if ((existing as List).isNotEmpty) {
        // 更新現有訂閱
        await _supabase
            .from('user_subscriptions')
            .update({
              'plan_id': planId,
              'status': 'active',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId)
            .eq('status', 'active');
      } else {
        // 創建新訂閱
        await _supabase.from('user_subscriptions').insert({
          'user_id': userId,
          'plan_id': planId,
          'status': 'active',
          'started_at': DateTime.now().toIso8601String(),
          'payment_method': paymentMethod,
          'auto_renew': true,
        });
      }

      // 記錄計費記錄
      await _recordBillingRecord(userId, planId);
    } catch (e) {
      print('升級訂閱失敗：$e');
      rethrow;
    }
  }

  /// 記錄計費記錄
  Future<void> _recordBillingRecord(String userId, String planId) async {
    try {
      // 獲取計劃信息以獲取金額
      final plan = await _supabase
          .from('subscription_plans')
          .select('price, billing_cycle')
          .eq('id', planId)
          .single();

      await _supabase.from('billing_records').insert({
        'user_id': userId,
        'amount': plan['price'] ?? 0,
        'currency': 'TWD',
        'status': 'paid',
        'billing_date': DateTime.now().toIso8601String(),
        'description': 'Subscription upgrade to ${plan['billing_cycle']}',
      });
    } catch (e) {
      print('記錄計費記錄失敗：$e');
    }
  }

  /// 取消訂閱
  Future<void> cancelSubscription() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('用戶未登錄');

      await _supabase
          .from('user_subscriptions')
          .update({
            'status': 'cancelled',
            'cancelled_at': DateTime.now().toIso8601String(),
            'auto_renew': false,
          })
          .eq('user_id', userId)
          .eq('status', 'active');
    } catch (e) {
      print('取消訂閱失敗：$e');
      rethrow;
    }
  }

  /// 暫停訂閱
  Future<void> pauseSubscription() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('用戶未登錄');

      await _supabase
          .from('user_subscriptions')
          .update({
            'status': 'paused',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('status', 'active');
    } catch (e) {
      print('暫停訂閱失敗：$e');
      rethrow;
    }
  }

  /// 恢復訂閱
  Future<void> resumeSubscription() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('用戶未登錄');

      await _supabase
          .from('user_subscriptions')
          .update({
            'status': 'active',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('status', 'paused');
    } catch (e) {
      print('恢復訂閱失敗：$e');
      rethrow;
    }
  }

  /// 獲取訂閱特性
  Map<String, dynamic> getSubscriptionFeatures(String tier) {
    const features = {
      TIER_FREE: {
        'voice_input': true,
        'manual_entry': true,
        'basic_analytics': true,
        'max_transactions_per_month': 100,
        'max_family_members': 1,
        'ai_features_enabled': false,
      },
      TIER_PREMIUM: {
        'voice_input': true,
        'manual_entry': true,
        'ai_categorization': true,
        'advanced_analytics': true,
        'passive_tracking': true,
        'max_transactions_per_month': 1000,
        'max_family_members': 1,
        'ai_features_enabled': true,
      },
      TIER_PRO: {
        'voice_input': true,
        'manual_entry': true,
        'ai_categorization': true,
        'advanced_analytics': true,
        'passive_tracking': true,
        'photo_analysis': true,
        'api_access': true,
        'max_transactions_per_month': null, // 無限制
        'max_family_members': 1,
        'ai_features_enabled': true,
      },
      TIER_FAMILY: {
        'voice_input': true,
        'manual_entry': true,
        'ai_categorization': true,
        'advanced_analytics': true,
        'passive_tracking': true,
        'photo_analysis': true,
        'family_sharing': true,
        'max_transactions_per_month': null, // 無限制
        'max_family_members': 6,
        'ai_features_enabled': true,
      },
    };

    return features[tier] ?? features[TIER_FREE] ?? {};
  }

  /// 獲取訂閱定價
  Map<String, dynamic> getSubscriptionPricing(String tier) {
    const pricing = {
      TIER_FREE: {'monthly_price': 0, 'yearly_price': 0, 'currency': 'TWD'},
      TIER_PREMIUM: {
        'monthly_price': 99,
        'yearly_price': 999,
        'currency': 'TWD',
      },
      TIER_PRO: {'monthly_price': 199, 'yearly_price': 1999, 'currency': 'TWD'},
      TIER_FAMILY: {
        'monthly_price': 299,
        'yearly_price': 2999,
        'currency': 'TWD',
      },
    };

    return pricing[tier] ?? pricing[TIER_FREE] ?? {};
  }

  /// 檢查是否超過使用限制
  Future<bool> hasExceededTransactionLimit() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final subscription = await getUserSubscription();
      if (subscription == null) return false;

      final features = getSubscriptionFeatures(subscription['tier']);
      final limit = features['max_transactions_per_month'] as int?;

      if (limit == null) return false; // 無限制

      // 計算本月交易數
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1).toIso8601String();
      final monthEnd = DateTime(now.year, now.month + 1, 1).toIso8601String();

      final response = await _supabase
          .from('transactions')
          .select('id')
          .eq('user_id', userId)
          .gte('created_at', monthStart)
          .lt('created_at', monthEnd);

      return (response as List).length >= limit;
    } catch (e) {
      print('檢查交易限制失敗：$e');
      return false;
    }
  }
}
