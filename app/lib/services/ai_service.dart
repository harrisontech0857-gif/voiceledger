import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../main.dart' show kMockMode;

final aiServiceProvider = Provider<AiServiceBase>((ref) {
  if (kMockMode) return MockAiService();
  final client = Supabase.instance.client;
  return AiService(client);
});

final aiResponseProvider = FutureProvider.family<String, String>((
  ref,
  prompt,
) async {
  final aiService = ref.watch(aiServiceProvider);
  return aiService.analyzeTransaction(prompt);
});

final dailyQuoteProvider = FutureProvider<String>((ref) async {
  final aiService = ref.watch(aiServiceProvider);
  return aiService.getDailyQuote();
});

final chatMessageProvider = StateProvider<List<ChatMessage>>((ref) {
  return [];
});

/// 聊天訊息
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? suggestion;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.suggestion,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'suggestion': suggestion,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      isUser: json['isUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      suggestion: json['suggestion'] as String?,
    );
  }
}

/// AI 服務介面
abstract class AiServiceBase {
  Future<String> analyzeTransaction(String description);
  Future<String> getFinancialAdvice(Map<String, dynamic> spendingData);
  Future<String> getDailyQuote();
  Future<ChatMessage> sendMessage(
    String content,
    List<ChatMessage> conversationHistory,
  );
  Future<Map<String, dynamic>> analyzeSpendingPatterns(
    List<Map<String, dynamic>> transactions,
  );
  Future<String> generateJournalEntry(
    List<Map<String, dynamic>> dailyTransactions,
  );
  Future<Map<String, dynamic>> extractTransactionDetails(String transcript);
}

/// AI 服務 - 使用 Supabase Edge Functions
class AiService implements AiServiceBase {
  final SupabaseClient _supabaseClient;
  final Logger _logger = Logger();

  AiService(this._supabaseClient);

  @override
  Future<String> analyzeTransaction(String description) async {
    try {
      final response = await _supabaseClient.functions.invoke(
        'analyze-transaction',
        body: {'description': description},
      );
      if (response.status == 200) {
        final result = response.data as Map<String, dynamic>;
        return result['response'] as String? ?? '';
      }
      _logger.w('Failed to analyze transaction: ${response.status}');
      return '';
    } catch (e) {
      _logger.e('Error analyzing transaction: $e');
      return '';
    }
  }

  @override
  Future<String> getFinancialAdvice(Map<String, dynamic> spendingData) async {
    try {
      final response = await _supabaseClient.functions.invoke(
        'get-financial-advice',
        body: {'spending_data': spendingData},
      );
      if (response.status == 200) {
        final result = response.data as Map<String, dynamic>;
        return result['advice'] as String? ?? '';
      }
      return '';
    } catch (e) {
      _logger.e('Error getting financial advice: $e');
      return '';
    }
  }

  @override
  Future<String> getDailyQuote() async {
    try {
      final response = await _supabaseClient.functions.invoke(
        'get-daily-quote',
      );
      if (response.status == 200) {
        final result = response.data as Map<String, dynamic>;
        return result['quote'] as String? ?? '';
      }
      return '';
    } catch (e) {
      _logger.e('Error getting daily quote: $e');
      return '';
    }
  }

  @override
  Future<ChatMessage> sendMessage(
    String content,
    List<ChatMessage> conversationHistory,
  ) async {
    try {
      final messages = conversationHistory
          .map(
            (msg) => {
              'role': msg.isUser ? 'user' : 'assistant',
              'content': msg.content,
            },
          )
          .toList();
      messages.add({'role': 'user', 'content': content});

      final response = await _supabaseClient.functions.invoke(
        'chat-with-secretary',
        body: {'messages': messages},
      );

      if (response.status == 200) {
        final result = response.data as Map<String, dynamic>;
        return ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: result['message'] as String? ?? '',
          isUser: false,
          timestamp: DateTime.now(),
          suggestion: result['suggestion'] as String?,
        );
      }
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '抱歉，我暫時無法回應。請稍後再試。',
        isUser: false,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '發生錯誤，請檢查您的網絡連接。',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }
  }

  @override
  Future<Map<String, dynamic>> analyzeSpendingPatterns(
    List<Map<String, dynamic>> transactions,
  ) async {
    try {
      final response = await _supabaseClient.functions.invoke(
        'analyze-spending',
        body: {'transactions': transactions},
      );
      if (response.status == 200) return response.data as Map<String, dynamic>;
      return {};
    } catch (e) {
      return {};
    }
  }

  @override
  Future<String> generateJournalEntry(
    List<Map<String, dynamic>> dailyTransactions,
  ) async {
    try {
      final response = await _supabaseClient.functions.invoke(
        'generate-journal',
        body: {'transactions': dailyTransactions},
      );
      if (response.status == 200) {
        final result = response.data as Map<String, dynamic>;
        return result['entry'] as String? ?? '';
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  @override
  Future<Map<String, dynamic>> extractTransactionDetails(
    String transcript,
  ) async {
    try {
      final response = await _supabaseClient.functions.invoke(
        'extract-transaction',
        body: {'transcript': transcript},
      );
      if (response.status == 200) return response.data as Map<String, dynamic>;
      return {};
    } catch (e) {
      return {};
    }
  }
}

/// Mock AI 服務 — 提供預設回應用於 UI 測試
class MockAiService implements AiServiceBase {
  static final _random = Random();

  static const _quotes = [
    '省錢不是捨不得花，而是花在值得的地方。',
    '理財就像種樹，越早開始越好。',
    '記帳是理財的第一步，你已經在路上了！',
    '不要為了省小錢而忽略了賺大錢的機會。',
    '每天存一點，一年就是一大筆。',
    '投資自己，是最好的投資。',
  ];

  static const _mockResponses = {
    '花了多少': '本月餐飲支出共 NT\$5,348，佔總支出 35%。相比上月增加了 12%。建議控制在 30% 以內。',
    '預算': '已為你設定月度預算。目前已使用 NT\$10,280 (68.5%)，剩餘 NT\$4,720 可用。',
    '建議':
        '根據你的消費習慣，建議：\n1. 減少外食 2-3 次/週\n2. 設定每日消費上限 NT\$500\n3. 每月固定儲蓄 20% 薪資',
  };

  @override
  Future<String> analyzeTransaction(String description) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return '已辨識：$description → 餐飲類 NT\$180';
  }

  @override
  Future<String> getFinancialAdvice(Map<String, dynamic> spendingData) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return '本月消費控制得不錯！繼續保持，預計可以達到儲蓄目標。';
  }

  @override
  Future<String> getDailyQuote() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _quotes[_random.nextInt(_quotes.length)];
  }

  @override
  Future<ChatMessage> sendMessage(
    String content,
    List<ChatMessage> conversationHistory,
  ) async {
    await Future.delayed(const Duration(milliseconds: 800));

    String response = '我是語記 AI 秘書（Demo 模式）。你問了「$content」。';

    for (final key in _mockResponses.keys) {
      if (content.contains(key)) {
        response = _mockResponses[key]!;
        break;
      }
    }

    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: response,
      isUser: false,
      timestamp: DateTime.now(),
      suggestion: '試試問「這個月花了多少」或「給我理財建議」',
    );
  }

  @override
  Future<Map<String, dynamic>> analyzeSpendingPatterns(
    List<Map<String, dynamic>> transactions,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'top_category': '餐飲',
      'trend': 'increasing',
      'suggestion': '餐飲支出有上升趨勢',
    };
  }

  @override
  Future<String> generateJournalEntry(
    List<Map<String, dynamic>> dailyTransactions,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return '今天共消費 3 筆，合計 NT\$465。最大支出為牛肉麵 NT\$180。整體控制在預算內，做得不錯！';
  }

  @override
  Future<Map<String, dynamic>> extractTransactionDetails(
    String transcript,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'amount': 180,
      'category': 'food',
      'description': transcript,
      'currency': 'TWD',
    };
  }
}
