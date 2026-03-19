import 'dart:math';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import '../main.dart' show kMockMode;

/// 配對資料
class CoupleInfo {
  final String id;
  final String userA;
  final String? userB;
  final String inviteCode;
  final String petName;
  final int petExp;
  final String petMood;
  final String? lastFedBy;
  final String? feedTurn;
  final String status;

  const CoupleInfo({
    required this.id,
    required this.userA,
    this.userB,
    required this.inviteCode,
    this.petName = '小財',
    this.petExp = 0,
    this.petMood = 'neutral',
    this.lastFedBy,
    this.feedTurn,
    this.status = 'pending',
  });

  bool get isActive => status == 'active' && userB != null;
  bool get isPending => status == 'pending';

  factory CoupleInfo.fromJson(Map<String, dynamic> json) => CoupleInfo(
    id: json['id'] as String,
    userA: json['user_a'] as String,
    userB: json['user_b'] as String?,
    inviteCode: json['invite_code'] as String,
    petName: json['pet_name'] as String? ?? '小財',
    petExp: json['pet_exp'] as int? ?? 0,
    petMood: json['pet_mood'] as String? ?? 'neutral',
    lastFedBy: json['last_fed_by'] as String?,
    feedTurn: json['feed_turn'] as String?,
    status: json['status'] as String? ?? 'pending',
  );
}

/// 配對服務
class CoupleService {
  final SupabaseClient _client;

  CoupleService(this._client);

  String get _userId => _client.auth.currentUser!.id;

  /// 產生 6 位邀請碼並建立配對
  Future<CoupleInfo> createInvite({String petName = '小財'}) async {
    final code = _generateCode();
    final result =
        await _client
            .from('couples')
            .insert({
              'user_a': _userId,
              'invite_code': code,
              'pet_name': petName,
              'feed_turn': _userId, // 建立者先餵
              'status': 'pending',
            })
            .select()
            .single();

    // 更新 user_profiles
    await _client
        .from('user_profiles')
        .update({'couple_id': result['id']})
        .eq('id', _userId);

    return CoupleInfo.fromJson(result);
  }

  /// 輸入邀請碼完成配對
  Future<CoupleInfo> acceptInvite(String code) async {
    final trimmed = code.trim().toUpperCase();

    // 查找邀請碼
    final couple =
        await _client
            .from('couples')
            .select()
            .eq('invite_code', trimmed)
            .eq('status', 'pending')
            .maybeSingle();

    if (couple == null) {
      throw Exception('邀請碼無效或已被使用');
    }

    if (couple['user_a'] == _userId) {
      throw Exception('不能和自己配對');
    }

    // 完成配對
    final result =
        await _client
            .from('couples')
            .update({
              'user_b': _userId,
              'status': 'active',
              'feed_turn': _userId, // 被邀請者先餵
            })
            .eq('id', couple['id'])
            .select()
            .single();

    // 更新雙方 user_profiles
    await _client
        .from('user_profiles')
        .update({'couple_id': result['id']})
        .eq('id', _userId);

    return CoupleInfo.fromJson(result);
  }

  /// 取得目前的配對資訊
  Future<CoupleInfo?> getCurrentCouple() async {
    try {
      final data =
          await _client
              .from('couples')
              .select()
              .or('user_a.eq.$_userId,user_b.eq.$_userId')
              .neq('status', 'dissolved')
              .maybeSingle();

      if (data == null) return null;
      return CoupleInfo.fromJson(data);
    } catch (e) {
      debugPrint('取得配對資訊失敗: $e');
      return null;
    }
  }

  /// 取得伴侶的顯示名稱
  Future<String?> getPartnerName() async {
    final couple = await getCurrentCouple();
    if (couple == null || !couple.isActive) return null;

    final partnerId = couple.userA == _userId ? couple.userB : couple.userA;
    if (partnerId == null) return null;

    final profile =
        await _client
            .from('user_profiles')
            .select('display_name')
            .eq('id', partnerId)
            .maybeSingle();

    return profile?['display_name'] as String?;
  }

  /// 餵食寵物（輪流機制）
  Future<String> feedPet() async {
    final couple = await getCurrentCouple();
    if (couple == null || !couple.isActive) {
      return '還沒配對，快邀請伴侶一起養寵物吧！';
    }

    // 檢查是不是輪到自己
    if (couple.feedTurn != null && couple.feedTurn != _userId) {
      final partnerName = await getPartnerName() ?? '對方';
      return '現在輪到 $partnerName 餵食喔～等對方寫日記吧！';
    }

    // 餵食：加經驗 + 換輪到對方
    final partnerId = couple.userA == _userId ? couple.userB : couple.userA;
    final newExp = couple.petExp + 10;

    await _client
        .from('couples')
        .update({
          'pet_exp': newExp,
          'last_fed_by': _userId,
          'last_fed_at': DateTime.now().toIso8601String(),
          'feed_turn': partnerId, // 換對方
          'pet_mood': 'happy',
        })
        .eq('id', couple.id);

    return '寵物吃飽了！輪到對方餵食囉 🐱';
  }

  /// 解除配對
  Future<void> dissolveCouple() async {
    final couple = await getCurrentCouple();
    if (couple == null) return;

    await _client
        .from('couples')
        .update({'status': 'dissolved'})
        .eq('id', couple.id);

    // 清除雙方 couple_id
    await _client
        .from('user_profiles')
        .update({'couple_id': null})
        .eq('couple_id', couple.id);
  }

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }
}

/// Provider
final coupleServiceProvider = Provider<CoupleService?>((ref) {
  if (kMockMode) return null;
  return CoupleService(Supabase.instance.client);
});

/// 目前配對狀態
final currentCoupleProvider = FutureProvider<CoupleInfo?>((ref) async {
  final service = ref.watch(coupleServiceProvider);
  if (service == null) return null;
  return service.getCurrentCouple();
});
