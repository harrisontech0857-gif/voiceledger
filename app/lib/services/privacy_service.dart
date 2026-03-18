import 'package:supabase_flutter/supabase_flutter.dart';

/// 隱私管理服務
/// 負責用戶隱私設定、同意管理和數據導出/刪除請求
class PrivacyService {
  static final PrivacyService _instance = PrivacyService._internal();

  factory PrivacyService() {
    return _instance;
  }

  PrivacyService._internal();

  final _supabase = Supabase.instance.client;

  /// 獲取用戶的隱私同意記錄
  Future<Map<String, dynamic>?> getPrivacyConsent() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('用戶未登錄');

      final response = await _supabase
          .from('privacy_consents')
          .select()
          .eq('user_id', userId)
          .single();

      return response;
    } catch (e) {
      print('獲取隱私同意失敗：$e');
      return null;
    }
  }

  /// 更新隱私同意
  Future<void> updatePrivacyConsent({
    bool? termsOfServiceAgreed,
    bool? privacyPolicyAgreed,
    bool? dataProcessingAgreed,
    bool? locationTrackingAgreed,
    bool? photoAnalysisAgreed,
    bool? pushNotificationsAgreed,
    int? locationHistoryRetentionDays,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('用戶未登錄');

      final updateData = <String, dynamic>{
        'last_modified_at': DateTime.now().toIso8601String(),
      };

      if (termsOfServiceAgreed != null) {
        updateData['terms_of_service_agreed'] = termsOfServiceAgreed;
      }
      if (privacyPolicyAgreed != null) {
        updateData['privacy_policy_agreed'] = privacyPolicyAgreed;
      }
      if (dataProcessingAgreed != null) {
        updateData['data_processing_agreed'] = dataProcessingAgreed;
      }
      if (locationTrackingAgreed != null) {
        updateData['location_tracking_agreed'] = locationTrackingAgreed;
      }
      if (photoAnalysisAgreed != null) {
        updateData['photo_analysis_agreed'] = photoAnalysisAgreed;
      }
      if (pushNotificationsAgreed != null) {
        updateData['push_notifications_agreed'] = pushNotificationsAgreed;
      }
      if (locationHistoryRetentionDays != null) {
        updateData['location_history_retention_days'] =
            locationHistoryRetentionDays;
      }

      await _supabase
          .from('privacy_consents')
          .update(updateData)
          .eq('user_id', userId);
    } catch (e) {
      print('更新隱私同意失敗：$e');
      rethrow;
    }
  }

  /// 提交首次同意
  Future<void> submitConsent({
    required bool termsOfServiceAgreed,
    required bool privacyPolicyAgreed,
    required bool dataProcessingAgreed,
    bool locationTrackingAgreed = false,
    bool photoAnalysisAgreed = false,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('用戶未登錄');

      // 先嘗試獲取現有記錄
      final existing = await getPrivacyConsent();

      if (existing != null) {
        // 更新現有記錄
        await updatePrivacyConsent(
          termsOfServiceAgreed: termsOfServiceAgreed,
          privacyPolicyAgreed: privacyPolicyAgreed,
          dataProcessingAgreed: dataProcessingAgreed,
          locationTrackingAgreed: locationTrackingAgreed,
          photoAnalysisAgreed: photoAnalysisAgreed,
        );
      } else {
        // 創建新記錄
        await _supabase.from('privacy_consents').insert({
          'user_id': userId,
          'terms_of_service_agreed': termsOfServiceAgreed,
          'privacy_policy_agreed': privacyPolicyAgreed,
          'data_processing_agreed': dataProcessingAgreed,
          'location_tracking_agreed': locationTrackingAgreed,
          'photo_analysis_agreed': photoAnalysisAgreed,
          'consent_version': '1.0',
          'agreed_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('提交同意失敗：$e');
      rethrow;
    }
  }

  /// 請求數據導出 (GDPR 資料可攜權)
  Future<String?> requestDataExport({
    bool includeTransactions = true,
    bool includePersonalData = true,
    bool includeAiInteractions = true,
    bool includeBehavioralData = true,
    String format = 'json', // 'json', 'csv', 'pdf'
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('用戶未登錄');

      final response = await _supabase
          .from('data_export_requests')
          .insert({
            'user_id': userId,
            'request_type': 'full_export',
            'format': format,
            'status': 'pending',
            'include_transactions': includeTransactions,
            'include_personal_data': includePersonalData,
            'include_ai_interactions': includeAiInteractions,
            'include_behavioral_data': includeBehavioralData,
          })
          .select()
          .single();

      return response['id'];
    } catch (e) {
      print('請求數據導出失敗：$e');
      rethrow;
    }
  }

  /// 檢查數據導出請求狀態
  Future<Map<String, dynamic>?> checkDataExportStatus(String requestId) async {
    try {
      final response = await _supabase
          .from('data_export_requests')
          .select()
          .eq('id', requestId)
          .single();

      return response;
    } catch (e) {
      print('檢查數據導出狀態失敗：$e');
      return null;
    }
  }

  /// 請求帳戶刪除 (GDPR 被遺忘權)
  Future<String?> requestAccountDeletion({String? reason}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('用戶未登錄');

      // 生成確認令牌
      final confirmationToken =
          'delete_${userId}_${DateTime.now().millisecondsSinceEpoch}';

      final response = await _supabase
          .from('account_deletion_requests')
          .insert({
            'user_id': userId,
            'status': 'pending',
            'reason': reason,
            'confirmation_token': confirmationToken,
            'scheduled_deletion_at':
                DateTime.now().add(const Duration(days: 30)).toIso8601String(),
          })
          .select()
          .single();

      // TODO: 發送確認電郵到用戶郵箱
      // 郵件應包含確認鏈接和取消刪除選項

      return response['id'];
    } catch (e) {
      print('請求帳戶刪除失敗：$e');
      rethrow;
    }
  }

  /// 確認帳戶刪除請求
  Future<void> confirmAccountDeletion(String confirmationToken) async {
    try {
      await _supabase.from('account_deletion_requests').update({
        'status': 'confirmed',
        'confirmed_at': DateTime.now().toIso8601String(),
      }).eq('confirmation_token', confirmationToken);
    } catch (e) {
      print('確認帳戶刪除失敗：$e');
      rethrow;
    }
  }

  /// 取消帳戶刪除請求
  Future<void> cancelAccountDeletion() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('用戶未登錄');

      await _supabase
          .from('account_deletion_requests')
          .update({'status': 'cancelled'})
          .eq('user_id', userId)
          .eq('status', 'pending');
    } catch (e) {
      print('取消帳戶刪除失敗：$e');
      rethrow;
    }
  }

  /// 記錄數據處理活動（用於審計）
  Future<void> logDataProcessing({
    required String
        operationType, // 'read', 'create', 'update', 'delete', 'export', 'share'
    required String
        resourceType, // 'transaction', 'profile', 'location', 'photo'
    String? resourceId,
    String? description,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return; // 非登入用戶不記錄

      await _supabase.from('data_processing_logs').insert({
        'user_id': userId,
        'operation_type': operationType,
        'resource_type': resourceType,
        'resource_id': resourceId,
        'description': description,
        'ip_address': ipAddress,
        'user_agent': userAgent,
      });
    } catch (e) {
      print('記錄數據處理活動失敗：$e');
      // 不應中斷主要流程，只記錄日誌
    }
  }

  /// 獲取審計日誌（僅用戶自己的）
  Future<List<Map<String, dynamic>>> getAuditLogs({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('用戶未登錄');

      final response = await _supabase
          .from('data_processing_logs')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('獲取審計日誌失敗：$e');
      return [];
    }
  }

  /// 檢查位置數據的自動刪除狀態
  Future<void> cleanupLocationData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // 獲取用戶的位置保留設定
      final consent = await getPrivacyConsent();
      if (consent == null) return;

      final retentionDays = consent['location_history_retention_days'] ?? 30;
      final cutoffDate = DateTime.now()
          .subtract(Duration(days: retentionDays))
          .toIso8601String();

      // 刪除過期的位置數據
      await _supabase
          .from('geofence_logs')
          .delete()
          .eq('user_id', userId)
          .lt('entry_time', cutoffDate);

      print('已清潔過期的位置數據');
    } catch (e) {
      print('清潔位置數據失敗：$e');
    }
  }

  /// 獲取隱私統計信息
  Future<Map<String, dynamic>?> getPrivacyStats() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('用戶未登錄');

      // 獲取用戶的各種數據統計
      final transactions = await _supabase
          .from('transactions')
          .select('id')
          .eq('user_id', userId);

      final locationLogs = await _supabase
          .from('geofence_logs')
          .select('id')
          .eq('user_id', userId);

      final photoLogs =
          await _supabase.from('photo_logs').select('id').eq('user_id', userId);

      return {
        'transactions_count': (transactions as List).length,
        'location_logs_count': (locationLogs as List).length,
        'photo_logs_count': (photoLogs as List).length,
        'total_data_points': (transactions as List).length +
            (locationLogs as List).length +
            (photoLogs as List).length,
      };
    } catch (e) {
      print('獲取隱私統計失敗：$e');
      return null;
    }
  }
}
