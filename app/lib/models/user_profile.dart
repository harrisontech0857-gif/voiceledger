class UserProfile {
  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final double totalIncome;
  final double totalExpense;
  final bool isPremium;
  final DateTime? premiumExpiresAt;
  final String? premiumProvider;
  final String? premiumProductId;
  final String locale;
  final String themeMode;
  final bool notificationsEnabled;
  final bool locationTrackingEnabled;
  final bool voiceInputEnabled;
  final double dailyBudget;
  final String? monthlyBudget;
  final int voiceEntries;
  final DateTime? lastVoiceEntryAt;
  final Map<String, dynamic> metadata;

  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.bio,
    required this.createdAt,
    this.updatedAt,
    this.totalIncome = 0,
    this.totalExpense = 0,
    this.isPremium = false,
    this.premiumExpiresAt,
    this.premiumProvider,
    this.premiumProductId,
    this.locale = 'zh_TW',
    this.themeMode = 'light',
    this.notificationsEnabled = true,
    this.locationTrackingEnabled = true,
    this.voiceInputEnabled = true,
    this.dailyBudget = 5,
    this.monthlyBudget,
    this.voiceEntries = 0,
    this.lastVoiceEntryAt,
    this.metadata = const {},
  });

  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? avatarUrl,
    String? bio,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? totalIncome,
    double? totalExpense,
    bool? isPremium,
    DateTime? premiumExpiresAt,
    String? premiumProvider,
    String? premiumProductId,
    String? locale,
    String? themeMode,
    bool? notificationsEnabled,
    bool? locationTrackingEnabled,
    bool? voiceInputEnabled,
    double? dailyBudget,
    String? monthlyBudget,
    int? voiceEntries,
    DateTime? lastVoiceEntryAt,
    Map<String, dynamic>? metadata,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      isPremium: isPremium ?? this.isPremium,
      premiumExpiresAt: premiumExpiresAt ?? this.premiumExpiresAt,
      premiumProvider: premiumProvider ?? this.premiumProvider,
      premiumProductId: premiumProductId ?? this.premiumProductId,
      locale: locale ?? this.locale,
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      locationTrackingEnabled:
          locationTrackingEnabled ?? this.locationTrackingEnabled,
      voiceInputEnabled: voiceInputEnabled ?? this.voiceInputEnabled,
      dailyBudget: dailyBudget ?? this.dailyBudget,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      voiceEntries: voiceEntries ?? this.voiceEntries,
      lastVoiceEntryAt: lastVoiceEntryAt ?? this.lastVoiceEntryAt,
      metadata: metadata ?? this.metadata,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName:
          json['display_name'] as String? ??
          json['displayName'] as String? ??
          '',
      avatarUrl: json['avatar_url'] as String? ?? json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      createdAt: DateTime.parse(
        json['created_at'] as String? ??
            json['createdAt'] as String? ??
            DateTime.now().toIso8601String(),
      ),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      totalIncome:
          (json['total_income'] as num?)?.toDouble() ??
          (json['totalIncome'] as num?)?.toDouble() ??
          0,
      totalExpense:
          (json['total_expense'] as num?)?.toDouble() ??
          (json['totalExpense'] as num?)?.toDouble() ??
          0,
      isPremium:
          json['is_premium'] as bool? ?? json['isPremium'] as bool? ?? false,
      premiumExpiresAt: json['premium_expires_at'] != null
          ? DateTime.parse(json['premium_expires_at'] as String)
          : null,
      premiumProvider: json['premium_provider'] as String?,
      premiumProductId: json['premium_product_id'] as String?,
      locale: json['locale'] as String? ?? 'zh_TW',
      themeMode:
          json['theme_mode'] as String? ??
          json['themeMode'] as String? ??
          'light',
      notificationsEnabled:
          json['notifications_enabled'] as bool? ??
          json['notificationsEnabled'] as bool? ??
          true,
      locationTrackingEnabled:
          json['location_tracking_enabled'] as bool? ??
          json['locationTrackingEnabled'] as bool? ??
          true,
      voiceInputEnabled:
          json['voice_input_enabled'] as bool? ??
          json['voiceInputEnabled'] as bool? ??
          true,
      dailyBudget:
          (json['daily_budget'] as num?)?.toDouble() ??
          (json['dailyBudget'] as num?)?.toDouble() ??
          5,
      monthlyBudget:
          json['monthly_budget'] as String? ?? json['monthlyBudget'] as String?,
      voiceEntries:
          json['voice_entries'] as int? ?? json['voiceEntries'] as int? ?? 0,
      lastVoiceEntryAt: json['last_voice_entry_at'] != null
          ? DateTime.parse(json['last_voice_entry_at'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'total_income': totalIncome,
      'total_expense': totalExpense,
      'is_premium': isPremium,
      'premium_expires_at': premiumExpiresAt?.toIso8601String(),
      'premium_provider': premiumProvider,
      'premium_product_id': premiumProductId,
      'locale': locale,
      'theme_mode': themeMode,
      'notifications_enabled': notificationsEnabled,
      'location_tracking_enabled': locationTrackingEnabled,
      'voice_input_enabled': voiceInputEnabled,
      'daily_budget': dailyBudget,
      'monthly_budget': monthlyBudget,
      'voice_entries': voiceEntries,
      'last_voice_entry_at': lastVoiceEntryAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory UserProfile.fromSupabase(Map<String, dynamic> map) {
    return UserProfile.fromJson(map);
  }

  Map<String, dynamic> toSupabase() => toJson();
}
