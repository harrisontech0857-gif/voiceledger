import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 金句服務
class QuoteService {
  static const String _key = 'saved_quotes';

  /// 取得已保存的金句列表
  Future<List<String>> getSavedQuotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_key);
      if (jsonStr == null) return [];
      final List<dynamic> decoded = jsonDecode(jsonStr) as List<dynamic>;
      return decoded.cast<String>();
    } catch (_) {
      return [];
    }
  }

  /// 保存金句
  Future<void> saveQuote(String quote) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final quotes = await getSavedQuotes();
      if (!quotes.contains(quote)) {
        quotes.add(quote);
        await prefs.setString(_key, jsonEncode(quotes));
      }
    } catch (_) {
      // 保存失敗，忽略
    }
  }

  /// 移除金句
  Future<void> removeQuote(String quote) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final quotes = await getSavedQuotes();
      quotes.remove(quote);
      await prefs.setString(_key, jsonEncode(quotes));
    } catch (_) {
      // 移除失敗，忽略
    }
  }

  /// 檢查金句是否已保存
  Future<bool> isQuoteSaved(String quote) async {
    try {
      final quotes = await getSavedQuotes();
      return quotes.contains(quote);
    } catch (_) {
      return false;
    }
  }
}

/// Provider
final quoteServiceProvider = Provider<QuoteService>((ref) {
  return QuoteService();
});
