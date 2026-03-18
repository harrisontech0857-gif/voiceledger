import 'package:flutter_test/flutter_test.dart';
import 'package:voiceledger/models/transaction.dart';
import 'package:voiceledger/services/transaction_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;

// Mock implementation of SupabaseClient
class MockSupabaseClient implements SupabaseClient {
  Map<String, dynamic> _storage = {};
  int _nextId = 1;

  @override
  PostgrestQueryBuilder from(String table) {
    return MockPostgrestQueryBuilder(table, _storage, _nextId);
  }

  // Required overrides (not used in tests)
  @override
  RealtimeClient get realtime => throw UnimplementedError();

  @override
  SupabaseAuthClient get auth => throw UnimplementedError();

  @override
  StorageClient get storage => throw UnimplementedError();

  @override
  FunctionClient get functions => throw UnimplementedError();

  @override
  String get url => '';

  @override
  String get anonKey => '';
}

class MockPostgrestQueryBuilder implements PostgrestQueryBuilder {
  final String _table;
  final Map<String, dynamic> _storage;
  int _nextId;
  String? _whereField;
  String? _whereValue;
  String? _orderField;
  bool _orderAscending = false;
  String? _gteField;
  String? _gteValue;
  String? _lteField;
  String? _lteValue;
  String? _eqField;
  String? _eqValue;

  MockPostgrestQueryBuilder(this._table, this._storage, this._nextId);

  @override
  PostgrestQueryBuilder select([String columns = '*']) {
    return this;
  }

  @override
  PostgrestQueryBuilder order(String column,
      {bool ascending = true, ReferencedTable? referencedTable}) {
    _orderField = column;
    _orderAscending = ascending;
    return this;
  }

  @override
  PostgrestQueryBuilder eq(String column, Object value) {
    _eqField = column;
    _eqValue = value.toString();
    return this;
  }

  @override
  PostgrestQueryBuilder gte(String column, Object value) {
    _gteField = column;
    _gteValue = value.toString();
    return this;
  }

  @override
  PostgrestQueryBuilder lte(String column, Object value) {
    _lteField = column;
    _lteValue = value.toString();
    return this;
  }

  @override
  PostgrestQueryBuilder insert(dynamic values,
      {bool ignoreDuplicates = false}) {
    final data = values as Map<String, dynamic>;
    data['id'] = 'tx_${_nextId++}';
    _storage[data['id']] = data;
    return this;
  }

  @override
  PostgrestQueryBuilder update(Map<String, dynamic> values) {
    if (_eqField != null && _eqValue != null) {
      final id = _eqValue;
      if (_storage.containsKey(id)) {
        _storage[id]!.addAll(values);
      }
    }
    return this;
  }

  @override
  PostgrestQueryBuilder delete() {
    if (_eqField != null && _eqValue != null) {
      _storage.remove(_eqValue);
    }
    return this;
  }

  @override
  Future<dynamic> single() async {
    return _buildResult().first;
  }

  @override
  Future<List<dynamic>> call() async {
    return _buildResult();
  }

  List<dynamic> _buildResult() {
    var result = _storage.values.toList();

    // Filter by GT/LTE dates
    if (_gteField == 'created_at' && _gteValue != null) {
      final gteDate = DateTime.parse(_gteValue!);
      result = result
          .where((item) =>
              DateTime.parse(item['created_at'] as String).isAfter(gteDate) ||
              DateTime.parse(item['created_at'] as String)
                  .isAtSameMomentAs(gteDate))
          .toList();
    }

    if (_lteField == 'created_at' && _lteValue != null) {
      final lteDate = DateTime.parse(_lteValue!);
      result = result
          .where((item) => DateTime.parse(item['created_at'] as String)
              .isBefore(lteDate.add(const Duration(days: 1))))
          .toList();
    }

    // Sort
    if (_orderField != null) {
      result.sort((a, b) {
        if (_orderField == 'created_at') {
          final aDate = DateTime.parse(a['created_at'] as String);
          final bDate = DateTime.parse(b['created_at'] as String);
          return _orderAscending ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
        }
        return 0;
      });
    }

    return result;
  }

  // Not implemented methods
  @override
  PostgrestQueryBuilder neq(String column, Object value) =>
      throw UnimplementedError();

  @override
  PostgrestQueryBuilder lt(String column, Object value) =>
      throw UnimplementedError();

  @override
  PostgrestQueryBuilder lte(String column, Object value) => this;

  @override
  PostgrestQueryBuilder gt(String column, Object value) =>
      throw UnimplementedError();

  @override
  PostgrestQueryBuilder gte(String column, Object value) => this;

  @override
  PostgrestQueryBuilder in_(String column, List values) =>
      throw UnimplementedError();

  @override
  PostgrestQueryBuilder contains(String column, dynamic value) =>
      throw UnimplementedError();

  @override
  PostgrestQueryBuilder containedBy(String column, dynamic value) =>
      throw UnimplementedError();

  @override
  PostgrestQueryBuilder rangeLt(String column, dynamic range) =>
      throw UnimplementedError();

  @override
  PostgrestQueryBuilder rangeLte(String column, dynamic range) =>
      throw UnimplementedError();

  @override
  PostgrestQueryBuilder rangeGt(String column, dynamic range) =>
      throw UnimplementedError();

  @override
  PostgrestQueryBuilder rangeGte(String column, dynamic range) =>
      throw UnimplementedError();

  @override
  PostgrestQueryBuilder rangeAdjacent(String column, dynamic range) =>
      throw UnimplementedError();

  @override
  PostgrestQueryBuilder overlaps(String column, dynamic value) =>
      throw UnimplementedError();

  @override
  PostgrestQueryBuilder textSearch(String column, String query,
          {TextSearchType? type, bool? useWebsearch}) =>
      throw UnimplementedError();

  @override
  PostgrestQueryBuilder match(Map<String, dynamic> query) =>
      throw UnimplementedError();

  @override
  PostgrestQueryBuilder not(String column, String operator, dynamic value) =>
      throw UnimplementedError();

  @override
  PostgrestQueryBuilder filter(String column, String operator, dynamic value) =>
      throw UnimplementedError();

  @override
  PostgrestQueryBuilder or(String filters, {QueryOperator? referencedTable}) =>
      throw UnimplementedError();

  @override
  PostgrestQueryBuilder limit(int count, {ReferencedTable? referencedTable}) =>
      throw UnimplementedError();

  @override
  PostgrestQueryBuilder offset(int offset, {ReferencedTable? referencedTable}) =>
      throw UnimplementedError();

  @override
  PostgrestQueryBuilder range(int from, int to,
          {ReferencedTable? referencedTable}) =>
      throw UnimplementedError();

  @override
  PostgrestQueryBuilder single() => this;

  @override
  PostgrestQueryBuilder maybeSingle() => throw UnimplementedError();

  @override
  PostgrestQueryBuilder csv() => throw UnimplementedError();

  @override
  PostgrestQueryBuilder geom(String column, String bounding_box) =>
      throw UnimplementedError();

  @override
  PostgrestQueryBuilder returns(String types) => throw UnimplementedError();

  @override
  Future explain(
          {bool? analyzeOption, String? verbose, String? settings}) =>
      throw UnimplementedError();

  @override
  PostgrestQueryBuilder explain({bool? analyze, String? verbose, String? settings}) {
    throw UnimplementedError();
  }
}

void main() {
  group('TransactionService Tests', () {
    late TransactionService service;
    late MockSupabaseClient mockClient;

    setUp(() {
      mockClient = MockSupabaseClient();
      service = TransactionService(mockClient);
    });

    group('addTransaction', () {
      test('should add a transaction and return it with an ID', () async {
        const transaction = Transaction(
          id: 'temp_id',
          userId: 'user_001',
          amount: 100.0,
          type: TransactionType.expense,
          category: TransactionCategory.food,
          createdAt: DateTime(2024, 3, 18, 10, 0),
          description: '午餐',
        );

        final result = await service.addTransaction(transaction);

        expect(result.userId, equals('user_001'));
        expect(result.amount, equals(100.0));
        expect(result.category, equals(TransactionCategory.food));
        expect(result.id, isNotEmpty);
      });

      test('should preserve all transaction fields when adding', () async {
        const transaction = Transaction(
          id: 'temp_id',
          userId: 'user_002',
          amount: 250.50,
          type: TransactionType.expense,
          category: TransactionCategory.shopping,
          createdAt: DateTime(2024, 3, 18, 14, 30),
          description: '購物',
          notes: '衣服',
          isRecurring: true,
          recurringFrequency: 'monthly',
        );

        final result = await service.addTransaction(transaction);

        expect(result.amount, equals(250.50));
        expect(result.notes, equals('衣服'));
        expect(result.isRecurring, equals(true));
        expect(result.recurringFrequency, equals('monthly'));
      });
    });

    group('getTransactions', () {
      setUp(() async {
        // Add test transactions
        await service.addTransaction(
          const Transaction(
            id: 'temp_1',
            userId: 'user_001',
            amount: 100.0,
            type: TransactionType.expense,
            category: TransactionCategory.food,
            createdAt: DateTime(2024, 3, 15, 10, 0),
            description: '午餐',
          ),
        );

        await service.addTransaction(
          const Transaction(
            id: 'temp_2',
            userId: 'user_001',
            amount: 150.0,
            type: TransactionType.expense,
            category: TransactionCategory.transport,
            createdAt: DateTime(2024, 3, 16, 11, 0),
            description: '計程車',
          ),
        );

        await service.addTransaction(
          const Transaction(
            id: 'temp_3',
            userId: 'user_002',
            amount: 200.0,
            type: TransactionType.income,
            category: TransactionCategory.salary,
            createdAt: DateTime(2024, 3, 17, 9, 0),
            description: '薪水',
          ),
        );
      });

      test('should retrieve all transactions', () async {
        final result = await service.getTransactions();

        expect(result.length, greaterThanOrEqualTo(3));
      });

      test('should filter transactions by userId', () async {
        final result = await service.getTransactions(userId: 'user_001');

        expect(result.length, equals(2));
        expect(result.every((tx) => tx.userId == 'user_001'), isTrue);
      });

      test('should filter transactions by date range', () async {
        final startDate = DateTime(2024, 3, 16, 0, 0);
        final endDate = DateTime(2024, 3, 17, 23, 59);

        final result = await service.getTransactions(
          startDate: startDate,
          endDate: endDate,
        );

        expect(result.isNotEmpty, isTrue);
      });

      test('should return transactions sorted by created_at descending', () async {
        final result = await service.getTransactions();

        for (var i = 0; i < result.length - 1; i++) {
          expect(
            result[i].createdAt.isAfter(result[i + 1].createdAt),
            isTrue,
            reason:
                'Transactions should be sorted by created_at in descending order',
          );
        }
      });

      test('should combine userId and date filters', () async {
        final startDate = DateTime(2024, 3, 15, 0, 0);
        final endDate = DateTime(2024, 3, 16, 23, 59);

        final result = await service.getTransactions(
          userId: 'user_001',
          startDate: startDate,
          endDate: endDate,
        );

        expect(result.every((tx) => tx.userId == 'user_001'), isTrue);
      });
    });

    group('updateTransaction', () {
      test('should update a transaction', () async {
        // Add a transaction
        final added = await service.addTransaction(
          const Transaction(
            id: 'temp_id',
            userId: 'user_001',
            amount: 100.0,
            type: TransactionType.expense,
            category: TransactionCategory.food,
            createdAt: DateTime(2024, 3, 18, 10, 0),
            description: '午餐',
          ),
        );

        // Update it
        final updated = added.copyWith(amount: 150.0, notes: '新筆記');
        await service.updateTransaction(updated);

        // Verify update
        final result = await service.getTransactions();
        final found = result.firstWhere((tx) => tx.id == added.id);

        expect(found.amount, equals(150.0));
        expect(found.notes, equals('新筆記'));
      });
    });

    group('deleteTransaction', () {
      test('should delete a transaction', () async {
        // Add a transaction
        final added = await service.addTransaction(
          const Transaction(
            id: 'temp_id',
            userId: 'user_001',
            amount: 100.0,
            type: TransactionType.expense,
            category: TransactionCategory.food,
            createdAt: DateTime(2024, 3, 18, 10, 0),
            description: '午餐',
          ),
        );

        final txIdToDelete = added.id;

        // Delete it
        await service.deleteTransaction(txIdToDelete);

        // Verify deletion
        final result = await service.getTransactions();
        final found = result.where((tx) => tx.id == txIdToDelete).toList();

        expect(found.isEmpty, isTrue);
      });
    });

    group('getMonthlySummary', () {
      setUp(() async {
        // Add transactions for March 2024
        await service.addTransaction(
          const Transaction(
            id: 'temp_1',
            userId: 'user_001',
            amount: 100.0,
            type: TransactionType.expense,
            category: TransactionCategory.food,
            createdAt: DateTime(2024, 3, 15, 10, 0),
            description: '午餐',
          ),
        );

        await service.addTransaction(
          const Transaction(
            id: 'temp_2',
            userId: 'user_001',
            amount: 200.0,
            type: TransactionType.income,
            category: TransactionCategory.salary,
            createdAt: DateTime(2024, 3, 10, 9, 0),
            description: '薪水',
          ),
        );

        await service.addTransaction(
          const Transaction(
            id: 'temp_3',
            userId: 'user_001',
            amount: 50.0,
            type: TransactionType.expense,
            category: TransactionCategory.transport,
            createdAt: DateTime(2024, 3, 20, 11, 0),
            description: '計程車',
          ),
        );
      });

      test('should calculate monthly summary correctly', () async {
        final summary = await service.getMonthlySummary(
          const DateTime(2024, 3),
        );

        expect(summary['income'], equals(200.0));
        expect(summary['expense'], equals(150.0));
        expect(summary['balance'], equals(50.0));
      });

      test('should handle months with no transactions', () async {
        final summary = await service.getMonthlySummary(
          const DateTime(2024, 4),
        );

        expect(summary['income'], equals(0.0));
        expect(summary['expense'], equals(0.0));
        expect(summary['balance'], equals(0.0));
      });
    });

    group('getCategorySummary', () {
      setUp(() async {
        // Add transactions for different categories
        await service.addTransaction(
          const Transaction(
            id: 'temp_1',
            userId: 'user_001',
            amount: 100.0,
            type: TransactionType.expense,
            category: TransactionCategory.food,
            createdAt: DateTime(2024, 3, 15, 10, 0),
            description: '午餐',
          ),
        );

        await service.addTransaction(
          const Transaction(
            id: 'temp_2',
            userId: 'user_001',
            amount: 50.0,
            type: TransactionType.expense,
            category: TransactionCategory.food,
            createdAt: DateTime(2024, 3, 16, 11, 0),
            description: '早餐',
          ),
        );

        await service.addTransaction(
          const Transaction(
            id: 'temp_3',
            userId: 'user_001',
            amount: 200.0,
            type: TransactionType.expense,
            category: TransactionCategory.transport,
            createdAt: DateTime(2024, 3, 17, 9, 0),
            description: '計程車',
          ),
        );
      });

      test('should calculate category summary correctly', () async {
        final summary = await service.getCategorySummary(
          const DateTime(2024, 3),
        );

        expect(summary['餐飲'], equals(150.0));
        expect(summary['交通'], equals(200.0));
      });

      test('should group transactions by category', () async {
        final summary = await service.getCategorySummary(
          const DateTime(2024, 3),
        );

        expect(summary.keys.length, equals(2));
        expect(summary.containsKey('餐飲'), isTrue);
        expect(summary.containsKey('交通'), isTrue);
      });

      test('should return empty map for months with no transactions', () async {
        final summary = await service.getCategorySummary(
          const DateTime(2024, 4),
        );

        expect(summary.isEmpty, isTrue);
      });
    });
  });
}
