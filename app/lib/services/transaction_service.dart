import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction.dart';

final transactionServiceProvider = Provider<TransactionService>((ref) {
  final client = Supabase.instance.client;
  return TransactionService(client);
});

/// 交易 CRUD 操作服務
class TransactionService {
  final SupabaseClient _client;

  const TransactionService(this._client);

  /// 取得使用者的所有交易
  Future<List<Transaction>> getTransactions({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _client.from('transactions').select();

      if (userId != null) {
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
    } catch (e) {
      rethrow;
    }
  }

  /// 新增交易
  Future<Transaction> addTransaction(Transaction transaction) async {
    try {
      final result = await _client
          .from('transactions')
          .insert(transaction.toSupabase())
          .select()
          .single();

      return Transaction.fromSupabase(result);
    } catch (e) {
      rethrow;
    }
  }

  /// 更新交易
  Future<void> updateTransaction(Transaction transaction) async {
    try {
      await _client
          .from('transactions')
          .update(transaction.toSupabase())
          .eq('id', transaction.id);
    } catch (e) {
      rethrow;
    }
  }

  /// 刪除交易
  Future<void> deleteTransaction(String id) async {
    try {
      await _client.from('transactions').delete().eq('id', id);
    } catch (e) {
      rethrow;
    }
  }

  /// 取得月份摘要
  Future<Map<String, double>> getMonthlySummary(DateTime month) async {
    try {
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

      return {
        'income': income,
        'expense': expense,
        'balance': income - expense,
      };
    } catch (e) {
      rethrow;
    }
  }

  /// 按類別取得摘要
  Future<Map<String, double>> getCategorySummary(DateTime month) async {
    try {
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
    } catch (e) {
      rethrow;
    }
  }
}

// Providers for transaction data
final userTransactionsProvider = FutureProvider.family<List<Transaction>,
    ({String userId, DateTime? startDate, DateTime? endDate})>((
  ref,
  params,
) async {
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
