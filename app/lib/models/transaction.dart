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

class Transaction {
  final String id;
  final String userId;
  final double amount;
  final TransactionType type;
  final TransactionCategory category;
  final DateTime createdAt;
  final String description;
  final String? notes;
  final String? voiceTranscript;
  final String? photoUrl;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final bool isRecurring;
  final String? recurringFrequency;
  final bool isSynced;

  const Transaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.category,
    required this.createdAt,
    required this.description,
    this.notes,
    this.voiceTranscript,
    this.photoUrl,
    this.latitude,
    this.longitude,
    this.locationName,
    this.isRecurring = false,
    this.recurringFrequency,
    this.isSynced = false,
  });

  Transaction copyWith({
    String? id,
    String? userId,
    double? amount,
    TransactionType? type,
    TransactionCategory? category,
    DateTime? createdAt,
    String? description,
    String? notes,
    String? voiceTranscript,
    String? photoUrl,
    double? latitude,
    double? longitude,
    String? locationName,
    bool? isRecurring,
    String? recurringFrequency,
    bool? isSynced,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      voiceTranscript: voiceTranscript ?? this.voiceTranscript,
      photoUrl: photoUrl ?? this.photoUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringFrequency: recurringFrequency ?? this.recurringFrequency,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? json['userId'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'] as String,
        orElse: () => TransactionType.expense,
      ),
      category: TransactionCategory.values.firstWhere(
        (e) => e.name == json['category'] as String,
        orElse: () => TransactionCategory.other,
      ),
      createdAt: DateTime.parse(
        json['created_at'] as String? ??
            json['createdAt'] as String? ??
            DateTime.now().toIso8601String(),
      ),
      description: json['description'] as String? ?? '',
      notes: json['notes'] as String?,
      voiceTranscript: json['voice_transcript'] as String? ??
          json['voiceTranscript'] as String?,
      photoUrl: json['photo_url'] as String? ?? json['photoUrl'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationName:
          json['location_name'] as String? ?? json['locationName'] as String?,
      isRecurring: json['is_recurring'] as bool? ??
          json['isRecurring'] as bool? ??
          false,
      recurringFrequency: json['recurring_frequency'] as String? ??
          json['recurringFrequency'] as String?,
      isSynced:
          json['is_synced'] as bool? ?? json['isSynced'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
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

  factory Transaction.fromSupabase(Map<String, dynamic> map) {
    return Transaction.fromJson(map).copyWith(isSynced: true);
  }

  Map<String, dynamic> toSupabase() => toJson();
}
