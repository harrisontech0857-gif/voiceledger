import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    required String email,
    required String displayName,
    String? avatarUrl,
    String? bio,
    required DateTime createdAt,
    DateTime? updatedAt,
    @Default(0) double totalIncome,
    @Default(0) double totalExpense,
    @Default(false) bool isPremium,
    DateTime? premiumExpiresAt,
    String? premiumProvider,
    String? premiumProductId,
    @Default('zh_TW') String locale,
    @Default('light') String themeMode,
    @Default(true) bool notificationsEnabled,
    @Default(true) bool locationTrackingEnabled,
    @Default(true) bool voiceInputEnabled,
    @Default(5) double dailyBudget,
    String? monthlyBudget,
    @Default(0) int voiceEntries,
    DateTime? lastVoiceEntryAt,
    @Default({}) Map<String, dynamic> metadata,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  factory UserProfile.fromSupabase(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      email: map['email'] as String,
      displayName: map['display_name'] as String,
      avatarUrl: map['avatar_url'] as String?,
      bio: map['bio'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      totalIncome: (map['total_income'] as num?)?.toDouble() ?? 0,
      totalExpense: (map['total_expense'] as num?)?.toDouble() ?? 0,
      isPremium: map['is_premium'] as bool? ?? false,
      premiumExpiresAt: map['premium_expires_at'] != null
          ? DateTime.parse(map['premium_expires_at'] as String)
          : null,
      premiumProvider: map['premium_provider'] as String?,
      premiumProductId: map['premium_product_id'] as String?,
      locale: map['locale'] as String? ?? 'zh_TW',
      themeMode: map['theme_mode'] as String? ?? 'light',
      notificationsEnabled: map['notifications_enabled'] as bool? ?? true,
      locationTrackingEnabled:
          map['location_tracking_enabled'] as bool? ?? true,
      voiceInputEnabled: map['voice_input_enabled'] as bool? ?? true,
      dailyBudget: (map['daily_budget'] as num?)?.toDouble() ?? 5,
      monthlyBudget: map['monthly_budget'] as String?,
      voiceEntries: map['voice_entries'] as int? ?? 0,
      lastVoiceEntryAt: map['last_voice_entry_at'] != null
          ? DateTime.parse(map['last_voice_entry_at'] as String)
          : null,
      metadata: map['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toSupabase() {
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
}
