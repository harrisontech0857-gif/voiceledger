import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import '../main.dart' show kMockMode;

/// 日記資料模型
class DiaryEntry {
  final String content;
  final String mood;
  final String highlight;
  final double totalExpense;
  final double totalIncome;
  final int transactionCount;
  final String? personalNote;

  const DiaryEntry({
    required this.content,
    this.mood = 'balanced',
    this.highlight = '',
    this.totalExpense = 0,
    this.totalIncome = 0,
    this.transactionCount = 0,
    this.personalNote,
  });

  factory DiaryEntry.fromJson(Map<String, dynamic> json) => DiaryEntry(
    content: json['content'] as String? ?? '',
    mood: json['mood'] as String? ?? 'balanced',
    highlight: json['highlight'] as String? ?? '',
    totalExpense: (json['total_expense'] as num?)?.toDouble() ?? 0,
    totalIncome: (json['total_income'] as num?)?.toDouble() ?? 0,
    transactionCount: json['transaction_count'] as int? ?? 0,
    personalNote: json['personal_note'] as String?,
  );
}

/// 日記服務介面
abstract class DiaryServiceBase {
  Future<DiaryEntry?> getDiary(DateTime date);
  Future<DiaryEntry> generateDiary(DateTime date);
}

/// 真實 Supabase 日記服務
class DiaryService implements DiaryServiceBase {
  final SupabaseClient _client;

  DiaryService(this._client);

  @override
  Future<DiaryEntry?> getDiary(DateTime date) async {
    try {
      final dateStr = _formatDate(date);
      final response = await _client.functions.invoke(
        'life-diary',
        method: HttpMethod.get,
        queryParameters: {'date': dateStr},
      );

      final body = jsonDecode(response.data as String) as Map<String, dynamic>;
      if (body['success'] == true && body['data'] != null) {
        return DiaryEntry.fromJson(body['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<DiaryEntry> generateDiary(DateTime date) async {
    try {
      final dateStr = _formatDate(date);
      final response = await _client.functions.invoke(
        'life-diary',
        body: {'date': dateStr},
      );

      final body = jsonDecode(response.data as String) as Map<String, dynamic>;
      if (body['success'] == true && body['data'] != null) {
        return DiaryEntry.fromJson(body['data'] as Map<String, dynamic>);
      }
      return DiaryEntry(content: '今天暫無日記', mood: 'peaceful');
    } catch (e) {
      return DiaryEntry(content: '日記生成失敗：$e', mood: 'peaceful');
    }
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

/// Mock 日記服務
class MockDiaryService implements DiaryServiceBase {
  @override
  Future<DiaryEntry?> getDiary(DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return null; // 模擬無已存日記
  }

  @override
  Future<DiaryEntry> generateDiary(DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final weekdays = ['日', '一', '二', '三', '四', '五', '六'];
    final wd = weekdays[date.weekday % 7];
    return DiaryEntry(
      content:
          '${date.month}月${date.day}日（週$wd）\n\n'
          '平穩的一天，日子就該這樣細水長流。\n\n'
          '好好休息，明天繼續加油！',
      mood: 'balanced',
      highlight: '日常消費',
      totalExpense: 350,
      totalIncome: 0,
      transactionCount: 3,
    );
  }
}

/// Provider
final diaryServiceProvider = Provider<DiaryServiceBase>((ref) {
  if (kMockMode) return MockDiaryService();
  return DiaryService(Supabase.instance.client);
});
