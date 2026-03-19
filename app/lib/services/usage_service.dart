import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 免費額度管理服務
///
/// Free tier 限制：
/// - 語音記帳：每月 30 次
/// - AI 秘書對話：每月 10 次
/// - AI 日記生成：每月 5 次
class UsageService {
  static const int freeVoiceLimit = 30;
  static const int freeChatLimit = 10;
  static const int freeDiaryLimit = 5;

  static const String _keyVoiceCount = 'usage_voice_count';
  static const String _keyChatCount = 'usage_chat_count';
  static const String _keyDiaryCount = 'usage_diary_count';
  static const String _keyResetMonth = 'usage_reset_month';

  /// 檢查並重設月度計數（跨月自動歸零）
  Future<void> _ensureMonthlyReset() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month}';
    final savedMonth = prefs.getString(_keyResetMonth) ?? '';

    if (savedMonth != currentMonth) {
      await prefs.setInt(_keyVoiceCount, 0);
      await prefs.setInt(_keyChatCount, 0);
      await prefs.setInt(_keyDiaryCount, 0);
      await prefs.setString(_keyResetMonth, currentMonth);
    }
  }

  /// 取得本月語音記帳使用次數
  Future<int> getVoiceUsage() async {
    await _ensureMonthlyReset();
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyVoiceCount) ?? 0;
  }

  /// 取得本月 AI 對話使用次數
  Future<int> getChatUsage() async {
    await _ensureMonthlyReset();
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyChatCount) ?? 0;
  }

  /// 取得本月日記生成使用次數
  Future<int> getDiaryUsage() async {
    await _ensureMonthlyReset();
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyDiaryCount) ?? 0;
  }

  /// 語音記帳是否還有免費額度
  Future<bool> canUseVoice({bool isPremium = false}) async {
    if (isPremium) return true;
    final count = await getVoiceUsage();
    return count < freeVoiceLimit;
  }

  /// AI 對話是否還有免費額度
  Future<bool> canUseChat({bool isPremium = false}) async {
    if (isPremium) return true;
    final count = await getChatUsage();
    return count < freeChatLimit;
  }

  /// AI 日記是否還有免費額度
  Future<bool> canUseDiary({bool isPremium = false}) async {
    if (isPremium) return true;
    final count = await getDiaryUsage();
    return count < freeDiaryLimit;
  }

  /// 記錄一次語音使用
  Future<int> recordVoiceUsage() async {
    await _ensureMonthlyReset();
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_keyVoiceCount) ?? 0) + 1;
    await prefs.setInt(_keyVoiceCount, count);
    return count;
  }

  /// 記錄一次 AI 對話使用
  Future<int> recordChatUsage() async {
    await _ensureMonthlyReset();
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_keyChatCount) ?? 0) + 1;
    await prefs.setInt(_keyChatCount, count);
    return count;
  }

  /// 記錄一次日記生成使用
  Future<int> recordDiaryUsage() async {
    await _ensureMonthlyReset();
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_keyDiaryCount) ?? 0) + 1;
    await prefs.setInt(_keyDiaryCount, count);
    return count;
  }

  /// 取得剩餘額度摘要
  Future<Map<String, int>> getRemainingQuota({bool isPremium = false}) async {
    if (isPremium) {
      return {'voice': -1, 'chat': -1, 'diary': -1}; // -1 表示無限
    }
    final voice = await getVoiceUsage();
    final chat = await getChatUsage();
    final diary = await getDiaryUsage();
    return {
      'voice': freeVoiceLimit - voice,
      'chat': freeChatLimit - chat,
      'diary': freeDiaryLimit - diary,
    };
  }
}

/// Provider
final usageServiceProvider = Provider<UsageService>((ref) => UsageService());
