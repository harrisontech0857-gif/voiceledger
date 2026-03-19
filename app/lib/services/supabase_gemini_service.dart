import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'ai_service.dart';

/// 透過 Supabase Edge Function 呼叫 Gemini AI（正式版用）
/// API Key 安全地存在 Supabase 後端，使用者不需要知道
class SupabaseGeminiService implements AiServiceBase {
  final SupabaseClient _client;
  final Logger _logger = Logger();

  SupabaseGeminiService(this._client);

  /// 呼叫 Edge Function 的統一入口
  Future<Map<String, dynamic>> _callEdgeFunction(
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _client.functions.invoke('gemini-ai', body: body);

      if (response.status != 200) {
        _logger.e('Edge Function error: ${response.status}');
        throw Exception('AI 服務暫時不可用 (${response.status})');
      }

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>;
        }
        throw Exception(data['error'] ?? '未知錯誤');
      }

      throw Exception('回應格式錯誤');
    } catch (e) {
      _logger.e('Edge Function call failed: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> extractTransactionDetails(
    String transcript,
  ) async {
    try {
      final result = await _callEdgeFunction({
        'action': 'parse',
        'text': transcript,
      });

      // Edge Function 回傳 { transactions: [...], summary, feedback }
      final transactions = result['transactions'] as List<dynamic>?;
      if (transactions != null && transactions.isNotEmpty) {
        final first = transactions[0] as Map<String, dynamic>;
        return {
          'amount': first['amount'] ?? 0,
          'category': _mapCategory(first['category']?.toString() ?? '其他'),
          'description': first['description'] ?? transcript,
          'currency': 'TWD',
          'all_transactions': transactions, // 如果有多筆
          'feedback': result['feedback'] ?? '',
        };
      }

      return {
        'amount': 0,
        'category': '其他',
        'description': transcript,
        'currency': 'TWD',
      };
    } catch (e) {
      _logger.e('extractTransactionDetails error: $e');
      return {
        'amount': 0,
        'category': '其他',
        'description': transcript,
        'currency': 'TWD',
      };
    }
  }

  @override
  Future<String> analyzeTransaction(String description) async {
    try {
      final result = await _callEdgeFunction({
        'action': 'analyze',
        'text': description,
      });
      return result['response']?.toString() ?? '已記錄此筆交易。';
    } catch (e) {
      return '已記錄此筆交易。';
    }
  }

  @override
  Future<String> getDailyQuote() async {
    try {
      final result = await _callEdgeFunction({'action': 'quote'});
      return result['quote']?.toString() ?? '每天存一點，未來多很多。';
    } catch (e) {
      return '每天存一點，未來多很多。';
    }
  }

  @override
  Future<ChatMessage> sendMessage(
    String content,
    List<ChatMessage> conversationHistory,
  ) async {
    try {
      final history = conversationHistory.map((msg) {
        return {'role': msg.isUser ? 'user' : 'model', 'content': msg.content};
      }).toList();

      final result = await _callEdgeFunction({
        'action': 'chat',
        'text': content,
        'conversationHistory': history,
      });

      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: result['reply']?.toString() ?? '抱歉，我暫時無法回應。',
        isUser: false,
        timestamp: DateTime.now(),
        suggestion: result['suggestion']?.toString(),
      );
    } catch (e) {
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '連線失敗，請確認網路連線。',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }
  }

  @override
  Future<Map<String, dynamic>> analyzeSpendingPatterns(
    List<Map<String, dynamic>> transactions,
  ) async {
    return {'top_category': '餐飲', 'trend': 'stable', 'suggestion': '持續記帳是好習慣'};
  }

  @override
  Future<String> generateJournalEntry(
    List<Map<String, dynamic>> dailyTransactions,
  ) async {
    return '今天的記帳已完成。';
  }

  @override
  Future<String> getFinancialAdvice(Map<String, dynamic> spendingData) async {
    try {
      final result = await _callEdgeFunction({
        'action': 'chat',
        'text': '根據我的消費數據 $spendingData，給我理財建議',
      });
      return result['reply']?.toString() ?? '建議持續記帳，保持良好消費習慣。';
    } catch (e) {
      return '建議持續記帳，保持良好消費習慣。';
    }
  }

  /// 將中文類別對應回 app 內部類別
  String _mapCategory(String category) {
    const map = {
      '餐飲': '餐飲',
      'food': '餐飲',
      'dining_out': '餐飲',
      '交通': '交通',
      'transport': '交通',
      '購物': '購物',
      'shopping': '購物',
      '娛樂': '娛樂',
      'entertainment': '娛樂',
      '日用': '日用',
      'utilities': '日用',
      '健康': '健康',
      'health': '健康',
      'medical': '健康',
      '教育': '教育',
      'education': '教育',
      '投資': '投資',
      'investment': '投資',
      '薪資': '薪資',
      'salary': '薪資',
    };
    return map[category] ?? '其他';
  }
}
