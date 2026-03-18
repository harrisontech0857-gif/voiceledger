import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pet.dart';

/// 寵物狀態管理 — Riverpod StateNotifier
///
/// 資料持久化用 SharedPreferences（本地），
/// 未來可擴充同步到 Supabase。

const _petStorageKey = 'voiceledger_pet';

class PetNotifier extends StateNotifier<PetModel> {
  PetNotifier() : super(PetModel.create()) {
    _loadFromStorage();
  }

  /// 從本地讀取寵物資料
  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_petStorageKey);
    if (json != null) {
      try {
        state = PetModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
      } catch (_) {
        // 解析失敗就用預設
      }
    }
    // 載入後更新心情
    _updateMood();
  }

  /// 儲存到本地
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_petStorageKey, jsonEncode(state.toJson()));
  }

  /// 根據最後記帳時間更新心情
  void _updateMood() {
    if (state.lastFedAt == null) {
      state = state.copyWith(mood: PetMood.neutral);
      return;
    }

    final hoursSinceLastFed =
        DateTime.now().difference(state.lastFedAt!).inHours;

    PetMood newMood;
    if (hoursSinceLastFed > 48) {
      newMood = PetMood.sleepy;
    } else if (hoursSinceLastFed > 24) {
      newMood = PetMood.hungry;
    } else {
      // 今天有記帳，看 streak 決定開心程度
      newMood = state.streak >= 3 ? PetMood.happy : PetMood.neutral;
    }

    if (newMood != state.mood) {
      state = state.copyWith(mood: newMood);
      _save();
    }
  }

  /// 餵食（記帳時呼叫）— 核心互動
  ///
  /// [amount] 記帳金額（用來決定回饋語）
  /// [underBudget] 是否低於每日預算
  ///
  /// 回傳寵物的反饋語句
  String feed({required int amount, bool underBudget = false}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 計算 streak
    int newStreak = state.streak;
    if (state.lastFedAt != null) {
      final lastFedDay = DateTime(
        state.lastFedAt!.year,
        state.lastFedAt!.month,
        state.lastFedAt!.day,
      );
      final diff = today.difference(lastFedDay).inDays;
      if (diff == 1) {
        newStreak += 1; // 連續天 +1
      } else if (diff > 1) {
        newStreak = 1; // 斷了，重來
      }
      // diff == 0: 同一天再記帳，streak 不變
    } else {
      newStreak = 1; // 第一次記帳
    }

    // 計算 exp
    int expGain = 10; // 基礎
    expGain += newStreak * 2; // streak bonus
    if (underBudget) expGain += 5; // 省錢獎勵

    final oldStage = state.stage;

    state = state.copyWith(
      exp: state.exp + expGain,
      streak: newStreak,
      lastFedAt: now,
      totalEntries: state.totalEntries + 1,
      level: (state.exp + expGain) ~/ 100 + 1,
      mood: newStreak >= 3 ? PetMood.happy : PetMood.neutral,
    );

    _save();

    // 檢查是否進化
    if (state.stage != oldStage) {
      return '🎉 恭喜！${state.name}進化成「${state.stageName}」了！'
          '\n${state.feedbackOnEntry(amount)}';
    }

    return state.feedbackOnEntry(amount);
  }

  /// 改名
  void rename(String newName) {
    state = state.copyWith(name: newName);
    _save();
  }

  /// 手動刷新心情（App 回到前台時呼叫）
  void refreshMood() => _updateMood();

  // ── Debug 專用（開發測試，正式版移除）──────────────

  /// 直接設定經驗值來切換階段
  void debugSetExp(int exp) {
    state = state.copyWith(exp: exp);
    _save();
  }

  /// 直接設定心情
  void debugSetMood(PetMood mood) {
    state = state.copyWith(mood: mood);
    _save();
  }

  /// 快速切換到指定階段（設定對應最低經驗值）
  void debugSetStage(PetStage stage) {
    final exp = switch (stage) {
      PetStage.egg => 0,
      PetStage.baby => 50,
      PetStage.teen => 200,
      PetStage.adult => 500,
      PetStage.master => 1000,
    };
    state = state.copyWith(exp: exp);
    _save();
  }
}

/// Riverpod Provider
final petProvider = StateNotifierProvider<PetNotifier, PetModel>((ref) {
  return PetNotifier();
});
