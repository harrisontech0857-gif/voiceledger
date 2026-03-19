import 'package:flutter_test/flutter_test.dart';
import 'package:voiceledger/models/transaction.dart';
import 'package:voiceledger/services/transaction_service.dart';

void main() {
  group('MockTransactionService Tests', () {
    late MockTransactionService service;

    setUp(() {
      service = MockTransactionService();
    });

    group('getTransactions', () {
      test('should return a list of transactions', () async {
        final transactions = await service.getTransactions();
        expect(transactions, isA<List<Transaction>>());
        expect(transactions.isNotEmpty, isTrue);
      });

      test('should filter by startDate', () async {
        final now = DateTime.now();
        final startDate = now.subtract(const Duration(days: 2));
        final transactions = await service.getTransactions(
          startDate: startDate,
        );
        for (final tx in transactions) {
          expect(
            tx.createdAt.isAfter(startDate) || tx.createdAt == startDate,
            isTrue,
          );
        }
      });

      test('should filter by endDate', () async {
        final now = DateTime.now();
        final endDate = now.subtract(const Duration(days: 3));
        final transactions = await service.getTransactions(endDate: endDate);
        for (final tx in transactions) {
          expect(
            tx.createdAt.isBefore(endDate) || tx.createdAt == endDate,
            isTrue,
          );
        }
      });

      test('should filter by date range', () async {
        final now = DateTime.now();
        final startDate = now.subtract(const Duration(days: 5));
        final endDate = now.subtract(const Duration(days: 1));
        final transactions = await service.getTransactions(
          startDate: startDate,
          endDate: endDate,
        );
        for (final tx in transactions) {
          expect(
            tx.createdAt.isAfter(startDate) || tx.createdAt == startDate,
            isTrue,
          );
          expect(
            tx.createdAt.isBefore(endDate) || tx.createdAt == endDate,
            isTrue,
          );
        }
      });
    });

    group('addTransaction', () {
      test('should add a transaction and return it', () async {
        final tx = Transaction(
          id: 'test-new',
          userId: 'mock-user-001',
          amount: 500,
          type: TransactionType.expense,
          category: TransactionCategory.entertainment,
          createdAt: DateTime.now(),
          description: '測試新增',
        );

        final result = await service.addTransaction(tx);
        expect(result.id, equals('test-new'));
        expect(result.description, equals('測試新增'));

        // Verify it was actually added
        final all = await service.getTransactions();
        expect(all.any((t) => t.id == 'test-new'), isTrue);
      });
    });

    group('updateTransaction', () {
      test('should update an existing transaction', () async {
        final all = await service.getTransactions();
        final original = all.first;
        final updated = original.copyWith(description: '已更新描述');

        await service.updateTransaction(updated);

        final afterUpdate = await service.getTransactions();
        final found = afterUpdate.firstWhere((t) => t.id == original.id);
        expect(found.description, equals('已更新描述'));
      });
    });

    group('deleteTransaction', () {
      test('should remove a transaction', () async {
        final allBefore = await service.getTransactions();
        final countBefore = allBefore.length;
        final toDelete = allBefore.first;

        await service.deleteTransaction(toDelete.id);

        final allAfter = await service.getTransactions();
        expect(allAfter.length, equals(countBefore - 1));
        expect(allAfter.any((t) => t.id == toDelete.id), isFalse);
      });
    });

    group('getMonthlySummary', () {
      test('should return income, expense, and balance', () async {
        final summary = await service.getMonthlySummary(DateTime.now());
        expect(summary, contains('income'));
        expect(summary, contains('expense'));
        expect(summary, contains('balance'));
        expect(
          summary['balance'],
          equals(summary['income']! - summary['expense']!),
        );
      });

      test('should not return negative income or expense', () async {
        final summary = await service.getMonthlySummary(DateTime.now());
        expect(summary['income']!, greaterThanOrEqualTo(0));
        expect(summary['expense']!, greaterThanOrEqualTo(0));
      });
    });

    group('getCategorySummary', () {
      test('should return a map of category totals', () async {
        final summary = await service.getCategorySummary(DateTime.now());
        expect(summary, isA<Map<String, double>>());
        // All values should be positive
        for (final value in summary.values) {
          expect(value, greaterThan(0));
        }
      });
    });
  });

  group('Transaction toJson isSynced fix', () {
    test('toJson should include is_synced field', () {
      final tx = Transaction(
        id: 'tx-1',
        userId: 'user-1',
        amount: 100,
        type: TransactionType.expense,
        category: TransactionCategory.food,
        createdAt: DateTime(2026, 3, 18),
        description: '測試',
        isSynced: true,
      );

      final json = tx.toJson();
      expect(json.containsKey('is_synced'), isTrue);
      expect(json['is_synced'], isTrue);
    });

    test('toJson default isSynced should be false', () {
      final tx = Transaction(
        id: 'tx-2',
        userId: 'user-2',
        amount: 50,
        type: TransactionType.expense,
        category: TransactionCategory.food,
        createdAt: DateTime(2026, 3, 18),
        description: '測試',
      );

      final json = tx.toJson();
      expect(json['is_synced'], isFalse);
    });
  });
}
