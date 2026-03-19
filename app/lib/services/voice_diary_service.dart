import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import '../main.dart' show kMockMode;

/// AI 語音日記分析結果
class VoiceDiaryAnalysis {
  final String mood;
  final String moodEmoji;
  final List<String> tags;
  final String diary;
  final String summary;
  final String originalTranscript;

  const VoiceDiaryAnalysis({
    required this.mood,
    required this.moodEmoji,
    required this.tags,
    required this.diary,
    required this.summary,
    required this.originalTranscript,
  });

  factory VoiceDiaryAnalysis.fromJson(
    Map<String, dynamic> json,
    String transcript,
  ) => VoiceDiaryAnalysis(
    mood: json['mood'] as String? ?? 'calm',
    moodEmoji: json['moodEmoji'] as String? ?? '😌',
    tags:
        (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        ['日常'],
    diary: json['diary'] as String? ?? transcript,
    summary: json['summary'] as String? ?? '',
    originalTranscript: transcript,
  );
}

/// 語音日記服務介面
abstract class VoiceDiaryServiceBase {
  Future<VoiceDiaryAnalysis> analyze(String transcript);
  Future<void> saveDiaryEntry(VoiceDiaryAnalysis analysis);
}

/// 真實服務 — 呼叫 voice-diary Edge Function
class VoiceDiaryService implements VoiceDiaryServiceBase {
  final SupabaseClient _client;

  VoiceDiaryService(this._client);

  @override
  Future<VoiceDiaryAnalysis> analyze(String transcript) async {
    try {
      final response = await _client.functions.invoke(
        'voice-diary',
        body: {'transcript': transcript},
        headers: {'Authorization': 'Bearer ${_client.supabaseKey}'},
      );

      // response.data 可能是 String 或已解析的 Map
      Map<String, dynamic> body;
      if (response.data is String) {
        body = jsonDecode(response.data as String) as Map<String, dynamic>;
      } else if (response.data is Map) {
        body = response.data as Map<String, dynamic>;
      } else {
        debugPrint('⚠️ voice-diary 回傳格式異常: ${response.data.runtimeType}');
        return _fallback(transcript);
      }

      if (body['success'] == true && body['data'] != null) {
        return VoiceDiaryAnalysis.fromJson(
          body['data'] as Map<String, dynamic>,
          transcript,
        );
      }

      // 有 error 時記錄
      if (body['error'] != null) {
        debugPrint('⚠️ voice-diary Edge Function 錯誤: ${body['error']}');
      }
      return _fallback(transcript);
    } catch (e) {
      debugPrint('⚠️ voice-diary 呼叫失敗: $e');
      return _fallback(transcript);
    }
  }

  @override
  Future<void> saveDiaryEntry(VoiceDiaryAnalysis analysis) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('⚠️ 無法儲存日記：使用者未登入');
      return;
    }

    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    try {
      // 先嘗試查詢今天是否已有日記
      final existing =
          await _client
              .from('life_diaries')
              .select('id')
              .eq('user_id', userId)
              .eq('diary_date', dateStr)
              .maybeSingle();

      if (existing != null) {
        // 已有 → 追加內容
        final existingContent =
            await _client
                .from('life_diaries')
                .select('content')
                .eq('id', existing['id'])
                .single();
        final oldContent = existingContent['content'] as String? ?? '';
        await _client
            .from('life_diaries')
            .update({
              'content': '$oldContent\n\n${analysis.diary}',
              'mood': analysis.mood,
              'highlight': analysis.summary,
              'personal_note': analysis.originalTranscript,
            })
            .eq('id', existing['id']);
      } else {
        // 沒有 → 新建
        await _client.from('life_diaries').insert({
          'user_id': userId,
          'diary_date': dateStr,
          'content': analysis.diary,
          'mood': analysis.mood,
          'highlight': analysis.summary,
          'personal_note': analysis.originalTranscript,
        });
      }
    } catch (e) {
      debugPrint('⚠️ 儲存日記失敗: $e');
    }
  }

  VoiceDiaryAnalysis _fallback(String transcript) => VoiceDiaryAnalysis(
    mood: 'calm',
    moodEmoji: '😌',
    tags: ['日常'],
    diary: transcript.isNotEmpty ? '今天，$transcript。' : '平靜的一天。',
    summary:
        transcript.length > 10 ? '${transcript.substring(0, 10)}⋯' : transcript,
    originalTranscript: transcript,
  );
}

/// Mock 服務
class MockVoiceDiaryService implements VoiceDiaryServiceBase {
  @override
  Future<VoiceDiaryAnalysis> analyze(String transcript) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return VoiceDiaryAnalysis(
      mood: 'happy',
      moodEmoji: '😊',
      tags: ['日常', '生活'],
      diary: '今天是平凡卻美好的一天。$transcript',
      summary:
          transcript.length > 10
              ? '${transcript.substring(0, 10)}⋯'
              : transcript,
      originalTranscript: transcript,
    );
  }

  @override
  Future<void> saveDiaryEntry(VoiceDiaryAnalysis analysis) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }
}

/// Provider
final voiceDiaryServiceProvider = Provider<VoiceDiaryServiceBase>((ref) {
  if (kMockMode) return MockVoiceDiaryService();
  return VoiceDiaryService(Supabase.instance.client);
});
