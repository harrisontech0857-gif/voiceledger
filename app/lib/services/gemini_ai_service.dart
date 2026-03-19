import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:logger/logger.dart';
import 'ai_service.dart';

/// Gemini AI 服務 — 使用 Google Generative AI SDK（免費額度）
class GeminiAiService implements AiServiceBase {
  final GenerativeModel _model;
  final Logger _logger = Logger();
  ChatSession? _chatSession;

  GeminiAiService({required String apiKey})
    : _model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey,
        systemInstruction: Content.text(
          '你是「語記」App 的 AI 財務秘書，專門協助使用者記帳和理財。'
          '請用繁體中文回答，語氣友善親切，回覆簡潔不超過 100 字。'
          '你的功能：分析交易、提供理財建議、每日金句、記帳輔助。'
          '幣別預設為新台幣（NT\$）。',
        ),
      );

  @override
  Future<String> analyzeTransaction(String description) async {
    try {
      final response = await _model.generateContent([
        Content.text(
          '使用者說了這句話來記帳：「$description」\n'
          '請簡短回覆（30字內），確認你理解了這筆交易，並給一句鼓勵或理財小提示。',
        ),
      ]);
      return response.text ?? '已記錄此筆交易。';
    } catch (e) {
      _logger.e('Gemini analyzeTransaction error: $e');
      return '已記錄此筆交易。';
    }
  }

  @override
  Future<String> getFinancialAdvice(Map<String, dynamic> spendingData) async {
    try {
      final response = await _model.generateContent([
        Content.text(
          '以下是使用者的消費數據：$spendingData\n'
          '請提供 3 條簡短的理財建議（每條不超過 20 字）。',
        ),
      ]);
      return response.text ?? '建議持續記帳，保持良好的消費習慣。';
    } catch (e) {
      _logger.e('Gemini getFinancialAdvice error: $e');
      return '建議持續記帳，保持良好的消費習慣。';
    }
  }

  @override
  Future<String> getDailyQuote() async {
    try {
      final response = await _model.generateContent([
        Content.text(
          '請給我一句原創的理財勵志金句（繁體中文，20字以內），'
          '風格可以幽默、溫暖或睿智。不要加引號。',
        ),
      ]);
      return response.text?.trim() ?? '每天存一點，未來多很多。';
    } catch (e) {
      _logger.e('Gemini getDailyQuote error: $e');
      return '每天存一點，未來多很多。';
    }
  }

  @override
  Future<ChatMessage> sendMessage(
    String content,
    List<ChatMessage> conversationHistory,
  ) async {
    try {
      // 建立或重用 chat session
      _chatSession ??= _model.startChat(
        history: conversationHistory.map((msg) {
          return Content(msg.isUser ? 'user' : 'model', [
            TextPart(msg.content),
          ]);
        }).toList(),
      );

      final response = await _chatSession!.sendMessage(Content.text(content));

      final text = response.text ?? '抱歉，我暫時無法回應。';

      // 根據回覆內容生成建議
      String? suggestion;
      if (content.contains('支出') || content.contains('花')) {
        suggestion = '查看本月統計報告';
      } else if (content.contains('預算') || content.contains('存錢')) {
        suggestion = '設定每月儲蓄目標';
      } else {
        suggestion = '試試問「這個月花了多少」';
      }

      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: text,
        isUser: false,
        timestamp: DateTime.now(),
        suggestion: suggestion,
      );
    } catch (e) {
      _logger.e('Gemini sendMessage error: $e');
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content:
            '連線失敗：${e.toString().length > 50 ? e.toString().substring(0, 50) : e}',
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
      final response = await _model.generateContent([
        Content.text(
          '分析以下交易記錄的消費模式：$transactions\n'
          '回覆 JSON 格式：{"top_category":"類別名","trend":"increasing/decreasing/stable","suggestion":"一句建議"}',
        ),
      ]);
      // 簡單回傳預設值，避免解析錯誤
      return {
        'top_category': '餐飲',
        'trend': 'stable',
        'suggestion': response.text ?? '持續記帳是好習慣',
      };
    } catch (e) {
      return {'top_category': '餐飲', 'trend': 'stable', 'suggestion': '持續記帳'};
    }
  }

  @override
  Future<String> generateJournalEntry(
    List<Map<String, dynamic>> dailyTransactions,
  ) async {
    try {
      final response = await _model.generateContent([
        Content.text('根據以下今日交易記錄，寫一段 50 字以內的日記摘要：$dailyTransactions'),
      ]);
      return response.text ?? '今天的記帳已完成。';
    } catch (e) {
      return '今天的記帳已完成。';
    }
  }

  @override
  Future<Map<String, dynamic>> extractTransactionDetails(
    String transcript,
  ) async {
    try {
      final response = await _model.generateContent([
        Content.text(
          '從以下語音辨識文字中提取交易資訊：「$transcript」\n'
          '回覆格式（只回覆 JSON，不要其他文字）：\n'
          '{"amount": 數字, "category": "餐飲/交通/購物/娛樂/日用/健康/教育/投資/薪資/其他", "description": "簡短描述", "currency": "TWD"}',
        ),
      ]);

      final text = response.text?.trim() ?? '';

      // 嘗試解析 JSON
      try {
        // 移除可能的 markdown 包裹
        final jsonStr = text
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final decoded = Uri.decodeFull(jsonStr);
        // 用簡單的方式解析
        if (decoded.contains('"amount"')) {
          // 提取數字
          final amountMatch = RegExp(
            r'"amount"\s*:\s*(\d+)',
          ).firstMatch(decoded);
          final categoryMatch = RegExp(
            r'"category"\s*:\s*"([^"]+)"',
          ).firstMatch(decoded);
          final descMatch = RegExp(
            r'"description"\s*:\s*"([^"]+)"',
          ).firstMatch(decoded);

          return {
            'amount': int.tryParse(amountMatch?.group(1) ?? '0') ?? 0,
            'category': categoryMatch?.group(1) ?? '其他',
            'description': descMatch?.group(1) ?? transcript,
            'currency': 'TWD',
          };
        }
      } catch (_) {
        // 解析失敗，使用預設值
      }

      return {
        'amount': 0,
        'category': '其他',
        'description': transcript,
        'currency': 'TWD',
      };
    } catch (e) {
      _logger.e('Gemini extractTransactionDetails error: $e');
      return {
        'amount': 0,
        'category': '其他',
        'description': transcript,
        'currency': 'TWD',
      };
    }
  }
}
