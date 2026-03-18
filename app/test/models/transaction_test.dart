import 'package:flutter_test/flutter_test.dart';
import 'package:voiceledger/models/transaction.dart';

void main() {
  group('Transaction Model Tests', () {
    group('fromJson', () {
      test('should create Transaction from JSON with all fields', () {
        final json = {
          'id': 'tx_123',
          'user_id': 'user_456',
          'amount': 100.50,
          'type': 'expense',
          'category': 'food',
          'created_at': '2024-03-18T10:30:00Z',
          'description': '午餐',
          'notes': '在餐廳吃飯',
          'voice_transcript': '花一百塊買午餐',
          'photo_url': 'https://example.com/photo.jpg',
          'latitude': 25.0330,
          'longitude': 121.5654,
          'location_name': '台北市',
          'is_recurring': false,
          'recurring_frequency': null,
          'is_synced': true,
        };

        final transaction = Transaction.fromJson(json);

        expect(transaction.id, equals('tx_123'));
        expect(transaction.userId, equals('user_456'));
        expect(transaction.amount, equals(100.50));
        expect(transaction.type, equals(TransactionType.expense));
        expect(transaction.category, equals(TransactionCategory.food));
        expect(transaction.description, equals('午餐'));
        expect(transaction.notes, equals('在餐廳吃飯'));
        expect(transaction.voiceTranscript, equals('花一百塊買午餐'));
        expect(transaction.photoUrl, equals('https://example.com/photo.jpg'));
        expect(transaction.latitude, equals(25.0330));
        expect(transaction.longitude, equals(121.5654));
        expect(transaction.locationName, equals('台北市'));
        expect(transaction.isRecurring, equals(false));
        expect(transaction.isSynced, equals(true));
      });

      test('should handle snake_case field names from Supabase', () {
        final json = {
          'id': 'tx_001',
          'user_id': 'user_001',
          'amount': 50.0,
          'type': 'income',
          'category': 'salary',
          'created_at': '2024-03-18T09:00:00Z',
          'description': '薪水',
          'voice_transcript': null,
          'photo_url': null,
          'latitude': null,
          'longitude': null,
          'location_name': null,
          'is_recurring': true,
          'recurring_frequency': 'monthly',
          'is_synced': false,
        };

        final transaction = Transaction.fromJson(json);

        expect(transaction.type, equals(TransactionType.income));
        expect(transaction.category, equals(TransactionCategory.salary));
        expect(transaction.isRecurring, equals(true));
        expect(transaction.recurringFrequency, equals('monthly'));
        expect(transaction.voiceTranscript, isNull);
      });

      test('should provide defaults for missing optional fields', () {
        final json = {
          'id': 'tx_002',
          'user_id': 'user_002',
          'amount': 200.0,
          'type': 'expense',
          'category': 'shopping',
          'created_at': '2024-03-18T12:00:00Z',
          'description': '購物',
        };

        final transaction = Transaction.fromJson(json);

        expect(transaction.notes, isNull);
        expect(transaction.voiceTranscript, isNull);
        expect(transaction.photoUrl, isNull);
        expect(transaction.latitude, isNull);
        expect(transaction.longitude, isNull);
        expect(transaction.locationName, isNull);
        expect(transaction.isRecurring, equals(false));
        expect(transaction.isSynced, equals(false));
      });

      test('should handle camelCase field names (fallback)', () {
        final json = {
          'id': 'tx_003',
          'userId': 'user_003',
          'amount': 75.0,
          'type': 'expense',
          'category': 'transport',
          'createdAt': '2024-03-18T14:00:00Z',
          'description': '計程車',
          'photoUrl': 'https://example.com/taxi.jpg',
          'voiceTranscript': '坐計程車',
          'is_synced': true,
        };

        final transaction = Transaction.fromJson(json);

        expect(transaction.userId, equals('user_003'));
        expect(transaction.createdAt.year, equals(2024));
        expect(transaction.photoUrl, equals('https://example.com/taxi.jpg'));
      });

      test('should default to TransactionType.expense for unknown type', () {
        final json = {
          'id': 'tx_004',
          'user_id': 'user_004',
          'amount': 100.0,
          'type': 'unknown_type',
          'category': 'food',
          'created_at': '2024-03-18T15:00:00Z',
          'description': 'test',
        };

        final transaction = Transaction.fromJson(json);

        expect(transaction.type, equals(TransactionType.expense));
      });

      test('should default to TransactionCategory.other for unknown category', () {
        final json = {
          'id': 'tx_005',
          'user_id': 'user_005',
          'amount': 100.0,
          'type': 'expense',
          'category': 'unknown_category',
          'created_at': '2024-03-18T15:00:00Z',
          'description': 'test',
        };

        final transaction = Transaction.fromJson(json);

        expect(transaction.category, equals(TransactionCategory.other));
      });
    });

    group('toJson', () {
      test('should convert Transaction to JSON with all fields', () {
        final transaction = Transaction(
          id: 'tx_123',
          userId: 'user_456',
          amount: 100.50,
          type: TransactionType.expense,
          category: TransactionCategory.food,
          createdAt: DateTime(2024, 3, 18, 10, 30),
          description: '午餐',
          notes: '在餐廳吃飯',
          voiceTranscript: '花一百塊買午餐',
          photoUrl: 'https://example.com/photo.jpg',
          latitude: 25.0330,
          longitude: 121.5654,
          locationName: '台北市',
          isRecurring: true,
          recurringFrequency: 'monthly',
          isSynced: true,
        );

        final json = transaction.toJson();

        expect(json['id'], equals('tx_123'));
        expect(json['user_id'], equals('user_456'));
        expect(json['amount'], equals(100.50));
        expect(json['type'], equals('expense'));
        expect(json['category'], equals('food'));
        expect(json['description'], equals('午餐'));
        expect(json['notes'], equals('在餐廳吃飯'));
        expect(json['voice_transcript'], equals('花一百塊買午餐'));
        expect(json['photo_url'], equals('https://example.com/photo.jpg'));
        expect(json['latitude'], equals(25.0330));
        expect(json['longitude'], equals(121.5654));
        expect(json['location_name'], equals('台北市'));
        expect(json['is_recurring'], equals(true));
        expect(json['recurring_frequency'], equals('monthly'));
      });

      test('should handle null optional fields', () {
        final transaction = Transaction(
          id: 'tx_001',
          userId: 'user_001',
          amount: 50.0,
          type: TransactionType.income,
          category: TransactionCategory.salary,
          createdAt: DateTime(2024, 3, 18, 9, 0),
          description: '薪水',
        );

        final json = transaction.toJson();

        expect(json['notes'], isNull);
        expect(json['voice_transcript'], isNull);
        expect(json['photo_url'], isNull);
        expect(json['latitude'], isNull);
        expect(json['longitude'], isNull);
        expect(json['location_name'], isNull);
        expect(json['recurring_frequency'], isNull);
      });

      test('should correctly serialize enum values', () {
        final transaction = Transaction(
          id: 'tx_002',
          userId: 'user_002',
          amount: 200.0,
          type: TransactionType.expense,
          category: TransactionCategory.shopping,
          createdAt: DateTime(2024, 3, 18, 12, 0),
          description: '購物',
        );

        final json = transaction.toJson();

        expect(json['type'], equals('expense'));
        expect(json['category'], equals('shopping'));
      });
    });

    group('copyWith', () {
      final baseTransaction = Transaction(
        id: 'tx_001',
        userId: 'user_001',
        amount: 100.0,
        type: TransactionType.expense,
        category: TransactionCategory.food,
        createdAt: DateTime(2024, 3, 18, 10, 0),
        description: '午餐',
        notes: '美味',
      );

      test('should copy all fields unchanged when called with no arguments', () {
        final copied = baseTransaction.copyWith();

        expect(copied.id, equals(baseTransaction.id));
        expect(copied.userId, equals(baseTransaction.userId));
        expect(copied.amount, equals(baseTransaction.amount));
        expect(copied.type, equals(baseTransaction.type));
        expect(copied.category, equals(baseTransaction.category));
        expect(copied.createdAt, equals(baseTransaction.createdAt));
        expect(copied.description, equals(baseTransaction.description));
        expect(copied.notes, equals(baseTransaction.notes));
      });

      test('should update amount field', () {
        final copied = baseTransaction.copyWith(amount: 150.0);

        expect(copied.amount, equals(150.0));
        expect(copied.id, equals(baseTransaction.id));
        expect(copied.description, equals(baseTransaction.description));
      });

      test('should update category field', () {
        final copied = baseTransaction.copyWith(
          category: TransactionCategory.shopping,
        );

        expect(copied.category, equals(TransactionCategory.shopping));
        expect(copied.type, equals(baseTransaction.type));
        expect(copied.amount, equals(baseTransaction.amount));
      });

      test('should update type field', () {
        final copied = baseTransaction.copyWith(
          type: TransactionType.income,
        );

        expect(copied.type, equals(TransactionType.income));
        expect(copied.category, equals(baseTransaction.category));
      });

      test('should update notes field', () {
        final copied = baseTransaction.copyWith(notes: '非常美味');

        expect(copied.notes, equals('非常美味'));
        expect(copied.description, equals(baseTransaction.description));
      });

      test('should preserve optional fields when passing null', () {
        // 注意：copyWith 中 null 參數表示「保持原值」，不是「設為 null」
        final copied = baseTransaction.copyWith(notes: null);

        expect(copied.notes, equals('美味')); // 保持原值
        expect(copied.id, equals(baseTransaction.id));
      });

      test('should update multiple fields at once', () {
        final copied = baseTransaction.copyWith(
          amount: 200.0,
          category: TransactionCategory.entertainment,
          notes: '新筆記',
          isSynced: true,
        );

        expect(copied.amount, equals(200.0));
        expect(copied.category, equals(TransactionCategory.entertainment));
        expect(copied.notes, equals('新筆記'));
        expect(copied.isSynced, equals(true));
        expect(copied.description, equals(baseTransaction.description));
      });

      test('should return a new instance', () {
        final copied = baseTransaction.copyWith(amount: 150.0);

        expect(identical(copied, baseTransaction), isFalse);
      });
    });

    group('fromSupabase and toSupabase', () {
      test('fromSupabase should set isSynced to true', () {
        final json = {
          'id': 'tx_001',
          'user_id': 'user_001',
          'amount': 100.0,
          'type': 'expense',
          'category': 'food',
          'created_at': '2024-03-18T10:00:00Z',
          'description': '午餐',
        };

        final transaction = Transaction.fromSupabase(json);

        expect(transaction.isSynced, equals(true));
        expect(transaction.description, equals('午餐'));
      });

      test('toSupabase should produce valid JSON for database', () {
        final transaction = Transaction(
          id: 'tx_001',
          userId: 'user_001',
          amount: 100.0,
          type: TransactionType.expense,
          category: TransactionCategory.food,
          createdAt: DateTime(2024, 3, 18, 10, 0),
          description: '午餐',
        );

        final json = transaction.toSupabase();

        expect(json['id'], equals('tx_001'));
        expect(json['user_id'], equals('user_001'));
        expect(json['type'], equals('expense'));
        expect(json['category'], equals('food'));
      });
    });

    group('TransactionCategory extension', () {
      test('displayName should return correct Chinese names', () {
        expect(TransactionCategory.food.displayName, equals('餐飲'));
        expect(TransactionCategory.transport.displayName, equals('交通'));
        expect(TransactionCategory.entertainment.displayName, equals('娛樂'));
        expect(TransactionCategory.shopping.displayName, equals('購物'));
        expect(TransactionCategory.utilities.displayName, equals('日用'));
        expect(TransactionCategory.health.displayName, equals('健康'));
        expect(TransactionCategory.education.displayName, equals('教育'));
        expect(TransactionCategory.investment.displayName, equals('投資'));
        expect(TransactionCategory.salary.displayName, equals('薪資'));
        expect(TransactionCategory.other.displayName, equals('其他'));
      });

      test('icon should return correct emoji', () {
        expect(TransactionCategory.food.icon, equals('🍜'));
        expect(TransactionCategory.transport.icon, equals('🚗'));
        expect(TransactionCategory.entertainment.icon, equals('🎮'));
        expect(TransactionCategory.shopping.icon, equals('🛍️'));
        expect(TransactionCategory.utilities.icon, equals('🏠'));
        expect(TransactionCategory.health.icon, equals('⚕️'));
        expect(TransactionCategory.education.icon, equals('📚'));
        expect(TransactionCategory.investment.icon, equals('📈'));
        expect(TransactionCategory.salary.icon, equals('💰'));
        expect(TransactionCategory.other.icon, equals('📝'));
      });
    });

    group('Transaction constructor', () {
      test('should create Transaction with required parameters', () {
        final transaction = Transaction(
          id: 'tx_001',
          userId: 'user_001',
          amount: 100.0,
          type: TransactionType.expense,
          category: TransactionCategory.food,
          createdAt: DateTime(2024, 3, 18, 10, 0),
          description: '午餐',
        );

        expect(transaction.id, equals('tx_001'));
        expect(transaction.isRecurring, equals(false));
        expect(transaction.isSynced, equals(false));
      });

      test('should respect custom values for optional parameters', () {
        final transaction = Transaction(
          id: 'tx_001',
          userId: 'user_001',
          amount: 100.0,
          type: TransactionType.expense,
          category: TransactionCategory.food,
          createdAt: DateTime(2024, 3, 18, 10, 0),
          description: '午餐',
          isRecurring: true,
          recurringFrequency: 'weekly',
          isSynced: true,
        );

        expect(transaction.isRecurring, equals(true));
        expect(transaction.recurringFrequency, equals('weekly'));
        expect(transaction.isSynced, equals(true));
      });
    });
  });
}
