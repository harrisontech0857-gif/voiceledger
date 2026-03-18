import 'package:flutter_test/flutter_test.dart';
import 'package:voiceledger/services/ai_service.dart';
import 'package:voiceledger/models/transaction.dart';

void main() {
  group('MockAiService', () {
    late MockAiService service;

    setUp(() {
      service = MockAiService();
    });

    group('analyzeTransaction', () {
      test('食物相關描述回傳 food 類別', () async {
        final result = await service.analyzeTransaction('中午吃便當花了80元');
        expect(result['category'], 'food');
      });

      test('交通相關描述回傳 transport 類別', () async {
        final result = await service.analyzeTransaction('搭捷運去上班');
        expect(result['category'], 'transport');
      });

      test('娛樂相關描述回傳 entertainment 類別', () async {
        final result = await service.analyzeTransaction('看電影花了350');
        expect(result['category'], 'entertainment');
      });

      test('購物相關描述回傳 shopping 類別', () async {
        final result = await service.analyzeTransaction('買衣服花了1200');
        expect(result['category'], 'shopping');
      });

      test('無法分類時回傳 other', () async {
        final result = await service.analyzeTransaction('雜費支出');
        expect(result['category'], 'other');
      });

      test('回傳值包含必要欄位', () async {
        final result = await service.analyzeTransaction('午餐');
        expect(result, containsPair('category', isNotNull));
        expect(result, containsPair('confidence', isNotNull));
        expect(result, containsPair('suggestion', isNotNull));
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
      test('回傳非空回應', () async {
        final response = await service.sendMessage(
          '我這個月花太多了',
          [],
        );
        expect(response.isNotEmpty, true);
      });

      test('帳戶問題觸發特定回應', () async {
        final response = await service.sendMessage(
          '我的帳單怎麼看',
          [],
        );
        expect(response.isNotEmpty, true);
      });
    });

    group('extractTransactionDetails', () {
      test('回傳結構化交易資料', () async {
        final result = await service.extractTransactionDetails('午餐花了80元');
        expect(result, containsPair('amount', isNotNull));
        expect(result, containsPair('category', isNotNull));
        expect(result, containsPair('description', isNotNull));
      });
    });

    group('analyzeSpendingPatterns', () {
      test('回傳分析結果', () async {
        final transactions = [
          Transaction(
            id: '1',
            userId: 'u1',
            amount: 500,
            type: TransactionType.expense,
            category: TransactionCategory.food,
            createdAt: DateTime.now(),
            description: '晚餐',
          ),
          Transaction(
            id: '2',
            userId: 'u1',
            amount: 100,
            type: TransactionType.expense,
            category: TransactionCategory.transport,
            createdAt: DateTime.now(),
            description: '捷運',
          ),
        ];
        final result = await service.analyzeSpendingPatterns(transactions);
        expect(result, isNotNull);
      });
    });

    group('generateJournalEntry', () {
      test('回傳日記文字', () async {
        final transactions = [
          Transaction(
            id: '1',
            userId: 'u1',
            amount: 200,
            type: TransactionType.expense,
            category: TransactionCategory.food,
            createdAt: DateTime.now(),
            description: '午餐便當',
          ),
        ];
        final entry = await service.generateJournalEntry(transactions);
        expect(entry.isNotEmpty, true);
      });
    });
  });
}
