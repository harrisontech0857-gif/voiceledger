/// 驗證 Transaction.toJson() 包含 is_synced 欄位的迴歸測試
import 'package:flutter_test/flutter_test.dart';
import 'package:voiceledger/models/transaction.dart';

void main() {
  group('Transaction.toJson() is_synced 迴歸測試', () {
    test('toJson 應包含 is_synced 欄位', () {
      final tx = Transaction(
        id: 'regression-1',
        userId: 'user-1',
        amount: 100,
        type: TransactionType.expense,
        category: TransactionCategory.food,
        createdAt: DateTime(2026, 3, 19),
        description: '測試',
        isSynced: true,
      );

      final json = tx.toJson();

      // 這個測試確保 is_synced 不會被遺漏
      expect(
        json.containsKey('is_synced'),
        isTrue,
        reason: 'toJson() 必須包含 is_synced 欄位',
      );
      expect(json['is_synced'], isTrue);
    });

    test('預設 isSynced 為 false', () {
      final tx = Transaction(
        id: 'regression-2',
        userId: 'user-2',
        amount: 50,
        type: TransactionType.expense,
        category: TransactionCategory.food,
        createdAt: DateTime(2026, 3, 19),
        description: '測試',
      );

      final json = tx.toJson();
      expect(json['is_synced'], isFalse);
    });

    test('toJson → fromJson 往返應保留 isSynced', () {
      final original = Transaction(
        id: 'roundtrip-1',
        userId: 'user-1',
        amount: 200,
        type: TransactionType.income,
        category: TransactionCategory.salary,
        createdAt: DateTime(2026, 3, 19),
        description: '薪水',
        isSynced: true,
      );

      final json = original.toJson();
      final restored = Transaction.fromJson(json);

      expect(restored.isSynced, equals(original.isSynced));
      expect(restored.amount, equals(original.amount));
      expect(restored.description, equals(original.description));
    });
  });
}
