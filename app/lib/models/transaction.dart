import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

enum TransactionType { expense, income }

enum TransactionCategory {
  food,
  transport,
  entertainment,
  shopping,
  utilities,
  health,
  education,
  investment,
  salary,
  other,
}

extension TransactionCategoryExt on TransactionCategory {
  String get displayName {
    switch (this) {
      case TransactionCategory.food:
        return '餐飲';
      case TransactionCategory.transport:
        return '交通';
      case TransactionCategory.entertainment:
        return '娛樂';
      case TransactionCategory.shopping:
        return '購物';
      case TransactionCategory.utilities:
        return '日用';
      case TransactionCategory.health:
        return '健康';
      case TransactionCategory.education:
        return '教育';
      case TransactionCategory.investment:
        return '投資';
      case TransactionCategory.salary:
        return '薪資';
      case TransactionCategory.other:
        return '其他';
    }
  }

  String get icon {
    switch (this) {
      case TransactionCategory.food:
        return '🍜';
      case TransactionCategory.transport:
        return '🚗';
      case TransactionCategory.entertainment:
        return '🎮';
      case TransactionCategory.shopping:
        return '🛍️';
      case TransactionCategory.utilities:
        return '🏠';
      case TransactionCategory.health:
        return '⚕️';
      case TransactionCategory.education:
        return '📚';
      case TransactionCategory.investment:
        return '📈';
      case TransactionCategory.salary:
        return '💰';
      case TransactionCategory.other:
        return '📝';
    }
  }
}

@freezed
class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    required String userId,
    required double amount,
    required TransactionType type,
    required TransactionCategory category,
    required DateTime createdAt,
    required String description,
    String? notes,
    String? voiceTranscript,
    String? photoUrl,
    double? latitude,
    double? longitude,
    String? locationName,
    @Default(false) bool isRecurring,
    String? recurringFrequency,
    @Default(false) bool isSynced,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);

  factory Transaction.fromSupabase(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'] as String,
        orElse: () => TransactionType.expense,
      ),
      category: TransactionCategory.values.firstWhere(
        (e) => e.name == map['category'] as String,
        orElse: () => TransactionCategory.other,
      ),
      createdAt: DateTime.parse(map['created_at'] as String),
      description: map['description'] as String,
      notes: map['notes'] as String?,
      voiceTranscript: map['voice_transcript'] as String?,
      photoUrl: map['photo_url'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      locationName: map['location_name'] as String?,
      isRecurring: map['is_recurring'] as bool? ?? false,
      recurringFrequency: map['recurring_frequency'] as String?,
      isSynced: true,
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'type': type.name,
      'category': category.name,
      'created_at': createdAt.toIso8601String(),
      'description': description,
      'notes': notes,
      'voice_transcript': voiceTranscript,
      'photo_url': photoUrl,
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
      'is_recurring': isRecurring,
      'recurring_frequency': recurringFrequency,
    };
  }
}
