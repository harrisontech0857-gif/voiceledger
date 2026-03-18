import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  static const _keyDailyReminder = 'daily_reminder_enabled';
  static const _keyReminderHour = 'reminder_hour';
  static const _keyBudgetAlert = 'budget_alert_enabled';
  static const _defaultReminderHour = 20;

  /// 檢查每日記帳提醒是否啟用
  Future<bool> isDailyReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDailyReminder) ?? false;
  }

  /// 設定每日記帳提醒
  /// [enabled] 是否啟用提醒
  /// [hour] 提醒時間（24小時制，0-23），預設為 20 點
  Future<void> setDailyReminder(bool enabled,
      {int hour = _defaultReminderHour}) async {
    if (hour < 0 || hour > 23) {
      throw ArgumentError('hour must be between 0 and 23');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDailyReminder, enabled);
    if (enabled) {
      await prefs.setInt(_keyReminderHour, hour);
    }
  }

  /// 檢查預算超支提醒是否啟用
  Future<bool> isBudgetAlertEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBudgetAlert) ?? false;
  }

  /// 設定預算超支提醒
  /// [enabled] 是否啟用提醒
  Future<void> setBudgetAlert(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBudgetAlert, enabled);
  }

  /// 取得記帳提醒時間
  Future<int> getReminderHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyReminderHour) ?? _defaultReminderHour;
  }
}
