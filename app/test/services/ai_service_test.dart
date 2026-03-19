import 'package:flutter_test/flutter_test.dart';
import 'package:voiceledger/services/ai_service.dart';

void main() {
  group('MockAiService', () {
    late MockAiService service;

    setUp(() {
      service = MockAiService();
    });

    group('analyzeTransaction', () {
      test('回傳非空字串', () async {
        final result = await service.analyzeTransaction('中午吃便當花了80元');
        expect(result.isNotEmpty, true);
      });

      test('回傳包含輸入描述', () async {
        final result = await service.analyzeTransaction('搭捷運去上班');
        expect(result, contains('搭捷運去上班'));
      });
    });

    group('getDailyQuote', () {
      test('回傳非空字串', () async {
        final quote = await service.getDailyQuote();
        expect(quote.isNotEmpty, true);
      });

      test('多次呼叫不會拋錯', () async {
        for (var i = 0; i < 10; i++) {
          final quote = await service.getDailyQuote();
          expect(quote.isNotEmpty, true);
        }
      });
    });

    group('getFinancialAdvice', () {
      test('回傳包含建議的字串', () async {
        final advice = await service.getFinancialAdvice({
          'food': 5000,
          'transport': 2000,
          'entertainment': 3000,
        });
        expect(advice.isNotEmpty, true);
      });
    });

    group('sendMessage', () {
      test('回傳 ChatMessage 物件', () async {
        final response = await service.sendMessage('我這個月花太多了', []);
        expect(response, isA<ChatMessage>());
        expect(response.content.isNotEmpty, true);
        expect(response.isUser, false);
      });

      test('帳單問題觸發回應', () async {
        final response = await service.sendMessage('花了多少', []);
        expect(response.content, contains('NT\$'));
      });
    });

    group('extractTransactionDetails', () {
      test('回傳結構化交易資料', () async {
        final result = await service.extractTransactionDetails('午餐花了80元');
        expect(result, containsPair('amount', isNotNull));
        expect(result, containsPair('category', isNotNull));
        expect(result, containsPair('description', isNotNull));
      });

      test('正確提取金額', () async {
        final result = await service.extractTransactionDetails('買咖啡花了120元');
        expect(result['amount'], 120.0);
      });
    });

    group('analyzeSpendingPatterns', () {
      test('回傳分析結果', () async {
        final transactions = <Map<String, dynamic>>[
          {'amount': 500.0, 'category': 'food', 'description': '晚餐'},
          {'amount': 100.0, 'category': 'transport', 'description': '捷運'},
        ];
        final result = await service.analyzeSpendingPatterns(transactions);
        expect(result, isNotNull);
        expect(result, containsPair('top_category', isNotNull));
      });
    });

    group('generateJournalEntry', () {
      test('回傳日記文字', () async {
        final transactions = <Map<String, dynamic>>[
          {'amount': 200.0, 'category': 'food', 'description': '午餐便當'},
        ];
        final entry = await service.generateJournalEntry(transactions);
        expect(entry.isNotEmpty, true);
      });
    });
  });
}
