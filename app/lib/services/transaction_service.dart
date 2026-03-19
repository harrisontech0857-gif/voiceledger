import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart' show kMockMode;
import '../models/transaction.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

final transactionServiceProvider = Provider<TransactionServiceBase>((ref) {
  if (kMockMode) return MockTransactionService();
  final client = Supabase.instance.client;
  return TransactionService(client);
});

/// 交易服務介面
abstract class TransactionServiceBase {
  Future<List<Transaction>> getTransactions({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<Transaction> addTransaction(Transaction transaction);
  Future<void> updateTransaction(Transaction transaction);
  Future<void> deleteTransaction(String id);
  Future<Map<String, double>> getMonthlySummary(DateTime month);
  Future<Map<String, double>> getCategorySummary(DateTime month);
}

/// 交易 CRUD 操作服務（Supabase 版）
class TransactionService implements TransactionServiceBase {
  final SupabaseClient _client;

  const TransactionService(this._client);

  @override
  Future<List<Transaction>> getTransactions({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _client.from('transactions').select();

      if (userId != null && userId.isNotEmpty) {
        query = query.eq('user_id', userId);
      }
      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final data = await query.order('created_at', ascending: false);
      return (data as List<dynamic>)
          .map((e) => Transaction.fromSupabase(e as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      _log.e('取得交易記錄失敗', error: e, stackTrace: stack);
      rethrow;
    }
  }

  @override
  Future<Transaction> addTransaction(Transaction transaction) async {
    try {
      final result =
          await _client
              .from('transactions')
              .insert(transaction.toSupabase())
              .select()
              .single();
      return Transaction.fromSupabase(result);
    } catch (e, stack) {
      _log.e('新增交易失敗', error: e, stackTrace: stack);
      rethrow;
    }
  }

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    try {
      await _client
          .from('transactions')
          .update(transaction.toSupabase())
          .eq('id', transaction.id);
    } catch (e, stack) {
      _log.e('更新交易失敗: ${transaction.id}', error: e, stackTrace: stack);
      rethrow;
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    if (id.isEmpty) {
      throw ArgumentError('交易 ID 不可為空');
    }
    try {
      await _client.from('transactions').delete().eq('id', id);
    } catch (e, stack) {
      _log.e('刪除交易失敗: $id', error: e, stackTrace: stack);
      rethrow;
    }
  }

  @override
  Future<Map<String, double>> getMonthlySummary(DateTime month) async {
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0);
    final transactions = await getTransactions(
      startDate: startDate,
      endDate: endDate,
    );

    double income = 0;
    double expense = 0;
    for (final tx in transactions) {
      if (tx.type == TransactionType.income) {
        income += tx.amount;
      } else {
        expense += tx.amount;
      }
    }
    return {'income': income, 'expense': expense, 'balance': income - expense};
  }

  @override
  Future<Map<String, double>> getCategorySummary(DateTime month) async {
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0);
    final transactions = await getTransactions(
      startDate: startDate,
      endDate: endDate,
    );

    final summary = <String, double>{};
    for (final tx in transactions) {
      final key = tx.category.displayName;
      summary[key] = (summary[key] ?? 0) + tx.amount;
    }
    return summary;
  }
}

/// Mock 版交易服務 — 提供假資料用於 UI 測試
class MockTransactionService implements TransactionServiceBase {
  final List<Transaction> _mockData = _generateMockTransactions();

  @override
  Future<List<Transaction>> getTransactions({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockData.where((tx) {
      if (startDate != null && tx.createdAt.isBefore(startDate)) return false;
      if (endDate != null && tx.createdAt.isAfter(endDate)) return false;
      return true;
    }).toList();
  }

  @override
  Future<Transaction> addTransaction(Transaction transaction) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _mockData.insert(0, transaction);
    return transaction;
  }

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _mockData.indexWhere((t) => t.id == transaction.id);
    if (idx >= 0) _mockData[idx] = transaction;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _mockData.removeWhere((t) => t.id == id);
  }

  @override
  Future<Map<String, double>> getMonthlySummary(DateTime month) async {
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0);
    final transactions = await getTransactions(
      startDate: startDate,
      endDate: endDate,
    );

    double income = 0;
    double expense = 0;
    for (final tx in transactions) {
      if (tx.type == TransactionType.income) {
        income += tx.amount;
      } else {
        expense += tx.amount;
      }
    }
    return {'income': income, 'expense': expense, 'balance': income - expense};
  }

  @override
  Future<Map<String, double>> getCategorySummary(DateTime month) async {
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0);
    final transactions = await getTransactions(
      startDate: startDate,
      endDate: endDate,
    );

    final summary = <String, double>{};
    for (final tx in transactions) {
      final key = tx.category.displayName;
      summary[key] = (summary[key] ?? 0) + tx.amount;
    }
    return summary;
  }

  static List<Transaction> _generateMockTransactions() {
    final now = DateTime.now();
    return [
      Transaction(
        id: 'mock-1',
        userId: 'mock-user-001',
        type: TransactionType.expense,
        amount: 180,
        currency: 'TWD',
        category: TransactionCategory.food,
        description: '牛肉麵',
        notes: '中午跟同事去吃的',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      Transaction(
        id: 'mock-2',
        userId: 'mock-user-001',
        type: TransactionType.expense,
        amount: 35,
        currency: 'TWD',
        category: TransactionCategory.transport,
        description: '捷運板南線',
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      Transaction(
        id: 'mock-3',
        userId: 'mock-user-001',
        type: TransactionType.expense,
        amount: 250,
        currency: 'TWD',
        category: TransactionCategory.shopping,
        description: 'Uniqlo T恤',
        createdAt: now.subtract(const Duration(hours: 8)),
      ),
      Transaction(
        id: 'mock-4',
        userId: 'mock-user-001',
        type: TransactionType.income,
        amount: 48000,
        currency: 'TWD',
        category: TransactionCategory.salary,
        description: '三月份薪資',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      Transaction(
        id: 'mock-5',
        userId: 'mock-user-001',
        type: TransactionType.expense,
        amount: 1290,
        currency: 'TWD',
        category: TransactionCategory.entertainment,
        description: 'Nintendo eShop',
        notes: '薩爾達傳說 DLC',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Transaction(
        id: 'mock-6',
        userId: 'mock-user-001',
        type: TransactionType.expense,
        amount: 12000,
        currency: 'TWD',
        category: TransactionCategory.utilities,
        description: '三月房租',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      Transaction(
        id: 'mock-7',
        userId: 'mock-user-001',
        type: TransactionType.expense,
        amount: 390,
        currency: 'TWD',
        category: TransactionCategory.entertainment,
        description: 'Netflix 月費',
        createdAt: now.subtract(const Duration(days: 7)),
      ),
      Transaction(
        id: 'mock-8',
        userId: 'mock-user-001',
        type: TransactionType.expense,
        amount: 85,
        currency: 'TWD',
        category: TransactionCategory.food,
        description: '全家便當',
        createdAt: now.subtract(const Duration(days: 1, hours: 4)),
      ),
      Transaction(
        id: 'mock-9',
        userId: 'mock-user-001',
        type: TransactionType.expense,
        amount: 680,
        currency: 'TWD',
        category: TransactionCategory.education,
        description: 'Udemy 課程',
        notes: 'Flutter 進階開發',
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      Transaction(
        id: 'mock-10',
        userId: 'mock-user-001',
        type: TransactionType.expense,
        amount: 150,
        currency: 'TWD',
        category: TransactionCategory.food,
        description: '星巴克拿鐵',
        createdAt: now.subtract(const Duration(hours: 26)),
      ),
    ];
  }
}

// Providers for transaction data
final userTransactionsProvider = FutureProvider.family<
  List<Transaction>,
  ({String userId, DateTime? startDate, DateTime? endDate})
>((ref, params) async {
  final service = ref.watch(transactionServiceProvider);
  return service.getTransactions(
    userId: params.userId,
    startDate: params.startDate,
    endDate: params.endDate,
  );
});

final monthlySummaryProvider =
    FutureProvider.family<Map<String, double>, DateTime>((ref, month) async {
      final service = ref.watch(transactionServiceProvider);
      return service.getMonthlySummary(month);
    });

final categorySummaryProvider =
    FutureProvider.family<Map<String, double>, DateTime>((ref, month) async {
      final service = ref.watch(transactionServiceProvider);
      return service.getCategorySummary(month);
    });
