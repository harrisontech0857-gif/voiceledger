import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../main.dart' show kMockMode, kGeminiApiKey;
import 'gemini_ai_service.dart';
import 'supabase_gemini_service.dart';

/// AI 服務優先順序：
/// 1. Supabase Edge Function + Gemini（正式版，API key 在後端）
/// 2. Client 端直接呼叫 Gemini（開發測試用，需手動輸入 API key）
/// 3. Mock 模式（無網路，假資料）
final aiServiceProvider = Provider<AiServiceBase>((ref) {
  // 正式模式：已登入 Supabase → 透過 Edge Function 呼叫 Gemini
  if (!kMockMode) {
    try {
      final client = Supabase.instance.client;
      if (client.auth.currentSession != null) {
        return SupabaseGeminiService(client);
      }
    } catch (_) {
      // Supabase 未初始化，繼續嘗試下一個
    }
  }

  // 開發測試：有 Gemini API key → client 端直呼
  if (kGeminiApiKey.isNotEmpty) {
    return GeminiAiService(apiKey: kGeminiApiKey);
  }

  // 最後：Mock 模式
  return MockAiService();
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
      final messages =
          conversationHistory
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
    '分享生活是感情的第一步，你已經在路上了！',
    '理解彼此就像種樹，越早開始越好。',
    '記錄生活是了解自己的第一步，你已經在路上了！',
    '不要為了小事而忽略了大愛的機會。',
    '每天分享一點，一年就更親近了。',
    '投資感情，是最好的投資。',
  ];

  static const _mockResponses = {
    '日記': '這週你寫了 5 篇日記，心情以開心為主。和伴侶的互動很頻繁，繼續保持！',
    '寵物': '本月已寫 12 篇日記，寵物成長到 Lv.3 了！繼續加油！',
    '建議': '本週情緒偏正面',
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
      'top_category': '日常',
      'trend': 'positive',
      'suggestion': '本週情緒偏正面，互動頻繁',
    };
  }

  @override
  Future<String> generateJournalEntry(
    List<Map<String, dynamic>> dailyTransactions,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return '今天寫了 2 篇日記，情緒偏向平靜。寵物很開心你有記錄！';
  }

  @override
  Future<Map<String, dynamic>> extractTransactionDetails(
    String transcript,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // 從文字中提取金額
    final amountMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(transcript);
    final amount =
        amountMatch != null
            ? double.tryParse(amountMatch.group(1)!) ?? 0.0
            : 0.0;

    // 根據關鍵字判斷分類
    final category = _detectCategory(transcript);

    // 生成描述（移除金額數字，保留語意）
    final description = transcript.isNotEmpty ? transcript : '未命名消費';

    return {
      'amount': amount.round(),
      'category': category,
      'description': description,
      'currency': 'TWD',
      'feedback': _generateFeedback(category, amount),
    };
  }

  /// 根據關鍵字智慧判斷分類
  static String _detectCategory(String text) {
    final t = text.toLowerCase();

    const categoryKeywords = <String, List<String>>{
      '餐飲': [
        '吃',
        '飯',
        '餐',
        '食',
        '便當',
        '麵',
        '咖啡',
        '奶茶',
        '早餐',
        '午餐',
        '晚餐',
        '宵夜',
        '小吃',
        '餐廳',
        '火鍋',
        '壽司',
        '飲料',
        '雞排',
        '牛排',
        '漢堡',
        'pizza',
        '甜點',
        '蛋糕',
        '茶',
      ],
      '交通': [
        '車',
        '捷運',
        '公車',
        '計程車',
        '油',
        '停車',
        '高鐵',
        '台鐵',
        'uber',
        '加油',
        '機票',
        '火車',
        'youbike',
        '騎',
      ],
      '購物': [
        '買',
        '購',
        '網購',
        '衣服',
        '鞋',
        '包',
        '淘寶',
        '蝦皮',
        '商品',
        '百貨',
        '手機',
        '電腦',
        '3C',
        '禮物',
      ],
      '娛樂': [
        '電影',
        '遊戲',
        '唱歌',
        'ktv',
        '旅遊',
        '門票',
        'netflix',
        'spotify',
        '演唱會',
        '展覽',
        '玩',
      ],
      '日用': [
        '超市',
        '便利商店',
        '衛生紙',
        '洗衣',
        '電費',
        '水費',
        '網路費',
        '瓦斯',
        '房租',
        '管理費',
        '日用品',
        '全聯',
        '家樂福',
      ],
      '健康': ['醫', '藥', '看診', '掛號', '健身', '牙', '診所', '醫院', '保健', '維他命'],
      '教育': ['書', '課', '學費', '補習', '培訓', '文具', '考試', '教材'],
      '投資': ['投資', '股票', '基金', '利息', '定存', '保險'],
      '薪資': ['薪水', '薪資', '工資', '獎金', '收入', '稿費', '兼職'],
    };

    for (final entry in categoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (t.contains(keyword)) {
          return entry.key;
        }
      }
    }

    return '其他';
  }

  /// 根據分類生成回饋語
  static String _generateFeedback(String category, double amount) {
    if (amount == 0) return '沒有偵測到金額，請確認後再保存';
    if (amount > 1000) return '寫了好長的日記呢，辛苦了！';
    if (amount > 500) return '中等花費，記錄下來很棒！';
    return '小額消費也不放過，好習慣！';
  }
}
