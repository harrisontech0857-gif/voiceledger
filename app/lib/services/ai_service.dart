import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

final aiServiceProvider = Provider<AiService>((ref) {
  final client = Supabase.instance.client;
  return AiService(client);
});

final aiResponseProvider = FutureProvider.family<String, String>((ref, prompt) async {
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

class AiService {
  final SupabaseClient _supabaseClient;
  final Logger _logger = Logger();

  AiService(this._supabaseClient);

  /// Analyze a transaction description and extract details
  Future<String> analyzeTransaction(String description) async {
    try {
      final response = await _supabaseClient.functions.invoke(
        'analyze-transaction',
        body: {
          'description': description,
        },
      );

      if (response.status == 200) {
        final result = response.data as Map<String, dynamic>;
        return result['response'] as String? ?? '';
      } else {
        _logger.w('Failed to analyze transaction: ${response.status}');
        return '';
      }
    } catch (e) {
      _logger.e('Error analyzing transaction: $e');
      return '';
    }
  }

  /// Get AI financial advice based on user's spending
  Future<String> getFinancialAdvice(Map<String, dynamic> spendingData) async {
    try {
      final response = await _supabaseClient.functions.invoke(
        'get-financial-advice',
        body: {
          'spending_data': spendingData,
        },
      );

      if (response.status == 200) {
        final result = response.data as Map<String, dynamic>;
        return result['advice'] as String? ?? '';
      } else {
        _logger.w('Failed to get financial advice: ${response.status}');
        return '';
      }
    } catch (e) {
      _logger.e('Error getting financial advice: $e');
      return '';
    }
  }

  /// Get daily motivational quote
  Future<String> getDailyQuote() async {
    try {
      final response = await _supabaseClient.functions.invoke(
        'get-daily-quote',
      );

      if (response.status == 200) {
        final result = response.data as Map<String, dynamic>;
        return result['quote'] as String? ?? '';
      } else {
        _logger.w('Failed to get daily quote: ${response.status}');
        return '';
      }
    } catch (e) {
      _logger.e('Error getting daily quote: $e');
      return '';
    }
  }

  /// Send a message to AI secretary and get response
  Future<ChatMessage> sendMessage(
    String content,
    List<ChatMessage> conversationHistory,
  ) async {
    try {
      final messages = conversationHistory
          .map((msg) => {
                'role': msg.isUser ? 'user' : 'assistant',
                'content': msg.content,
              })
          .toList();

      messages.add({
        'role': 'user',
        'content': content,
      });

      final response = await _supabaseClient.functions.invoke(
        'chat-with-secretary',
        body: {
          'messages': messages,
        },
      );

      if (response.status == 200) {
        final result = response.data as Map<String, dynamic>;
        final aiResponse = result['message'] as String? ?? '';
        final suggestion = result['suggestion'] as String?;

        return ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: aiResponse,
          isUser: false,
          timestamp: DateTime.now(),
          suggestion: suggestion,
        );
      } else {
        _logger.w('Failed to send message: ${response.status}');
        return ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: '抱歉，我暫時無法回應。請稍後再試。',
          isUser: false,
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      _logger.e('Error sending message: $e');
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '發生錯誤，請檢查您的網絡連接。',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Analyze spending patterns
  Future<Map<String, dynamic>> analyzeSpendingPatterns(
    List<Map<String, dynamic>> transactions,
  ) async {
    try {
      final response = await _supabaseClient.functions.invoke(
        'analyze-spending',
        body: {
          'transactions': transactions,
        },
      );

      if (response.status == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        _logger.w('Failed to analyze spending: ${response.status}');
        return {};
      }
    } catch (e) {
      _logger.e('Error analyzing spending: $e');
      return {};
    }
  }

  /// Generate a journal entry based on the day's transactions
  Future<String> generateJournalEntry(
    List<Map<String, dynamic>> dailyTransactions,
  ) async {
    try {
      final response = await _supabaseClient.functions.invoke(
        'generate-journal',
        body: {
          'transactions': dailyTransactions,
        },
      );

      if (response.status == 200) {
        final result = response.data as Map<String, dynamic>;
        return result['entry'] as String? ?? '';
      } else {
        _logger.w('Failed to generate journal entry: ${response.status}');
        return '';
      }
    } catch (e) {
      _logger.e('Error generating journal entry: $e');
      return '';
    }
  }

  /// Extract transaction details from voice transcript
  Future<Map<String, dynamic>> extractTransactionDetails(
    String transcript,
  ) async {
    try {
      final response = await _supabaseClient.functions.invoke(
        'extract-transaction',
        body: {
          'transcript': transcript,
        },
      );

      if (response.status == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        _logger.w('Failed to extract transaction: ${response.status}');
        return {};
      }
    } catch (e) {
      _logger.e('Error extracting transaction details: $e');
      return {};
    }
  }
}
