# VoiceLedger (語記) - AI Financial Secretary App

A warm, friendly Flutter application that acts as your personal AI financial secretary. Record expenses with your voice, get intelligent analysis, and track your financial journey through beautiful interfaces.

## Project Overview

VoiceLedger is built with Flutter 3.x and uses cutting-edge technologies to simplify personal finance management:

- **Voice-First Interface**: Natural language expense recording via speech-to-text
- **AI Secretary**: Conversational financial advice powered by Edge Functions
- **Passive Tracking**: Geofence-based location tracking and photo analysis
- **Smart Analytics**: Real-time spending analysis and trend visualization
- **Daily Journaling**: AI-generated personal finance journals
- **Premium Subscriptions**: RevenueCat integration for monetization

## Architecture

### Feature-First Structure

```
lib/
├── core/                          # Core utilities & configuration
│   ├── env.dart                   # Environment variables
│   ├── theme.dart                 # Design system & theming
│   ├── app_router.dart            # Go Router configuration
│   └── supabase_client.dart       # Supabase initialization
├── models/                        # Data models
│   ├── transaction.dart           # Transaction model (Freezed)
│   └── user_profile.dart          # User profile model (Freezed)
├── services/                      # Business logic & API integration
│   ├── voice_service.dart         # Speech-to-text wrapper
│   ├── ai_service.dart            # AI & Supabase Edge Functions
│   └── passive_tracking_service.dart # Location & geofencing
└── features/                      # Feature modules
    ├── auth/                      # Authentication
    ├── onboarding/                # Onboarding wizard
    ├── dashboard/                 # Home screen & summary
    ├── voice_entry/               # Core voice recording UI
    ├── ai_secretary/              # Chat interface
    ├── statistics/                # Financial analytics
    ├── daily_journal/             # Personal journaling
    └── settings/                  # User preferences
```

## Key Dependencies

### State Management & Navigation
- **riverpod** (2.4.0): Advanced state management with code generation support
- **flutter_riverpod**: Riverpod for Flutter
- **go_router** (14.0.0): Declarative routing with nested navigation

### Backend & Authentication
- **supabase_flutter** (1.10.0): Authentication, Database, Real-time, Edge Functions
- **supabase**: Dart SDK for Supabase

### Voice & Audio
- **speech_to_text** (7.0.0): Speech-to-text recognition
- **record** (5.1.0): Audio recording capabilities
- **audio_session** (0.1.13): Audio session management

### Location & Geofencing
- **geolocator** (10.1.0): Location services
- **geofencing** (1.0.0): Geofence management

### Local Storage
- **hive** (2.2.0): Local NoSQL database
- **hive_flutter**: Hive Flutter integration
- **shared_preferences** (2.2.0): Simple key-value storage

### Monetization
- **purchases_flutter** (7.0.0): RevenueCat integration for subscriptions

### UI & Design
- **google_fonts** (6.1.0): Google Fonts integration
- **flutter_svg** (2.0.0): SVG rendering
- **lottie** (3.1.0): Animation support
- **animations** (2.0.0): Material transitions

### Data Models
- **freezed_annotation** (2.4.0): Immutable data classes
- **json_annotation** (4.8.0): JSON serialization
- **uuid** (4.0.0): Unique ID generation

### Utilities
- **intl** (0.19.0): Internationalization
- **logger** (2.0.0): Logging utility
- **envied** (0.5.0): Environment configuration

## Getting Started

### Prerequisites

1. Flutter 3.16.0 or later
2. Supabase project with:
   - Authentication enabled
   - Database with migrations
   - Edge Functions set up
3. RevenueCat account for premium features

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd voiceledger

# Install dependencies
flutter pub get

# Generate code (Freezed, Riverpod, Hive)
flutter pub run build_runner build --delete-conflicting-outputs

# Create environment file
cp .env.example .env
# Edit .env with your Supabase & RevenueCat keys
```

### Running the App

```bash
# Development build
flutter run -d chrome  # or your target device

# Production build
flutter build apk
flutter build ios
```

## Core Features

### 1. Voice Entry (語音記帳)

**File**: `lib/features/voice_entry/voice_entry_screen.dart`

- Real-time speech-to-text with visual feedback
- Animated microphone button with pulse effect
- AI confidence scoring
- Automatic transaction detail extraction
- Category auto-detection
- Confidence-based confirmation dialog

**Key Services**:
- `VoiceService`: Wraps `speech_to_text` with lifecycle management
- `AiService.extractTransactionDetails()`: Parses voice transcript

### 2. AI Secretary (AI 財務秘書)

**File**: `lib/features/ai_secretary/chat_screen.dart`

- Multi-turn conversational interface
- Message history with timestamps
- Suggestion chips for quick responses
- Real-time streaming responses
- Context-aware financial advice

**Key Services**:
- `AiService.sendMessage()`: Chat endpoint
- `AiService.analyzeSpendingPatterns()`: Financial insights

### 3. Dashboard

**File**: `lib/features/dashboard/dashboard_screen.dart`

- Daily motivational quotes (AI-generated)
- Today's spending summary with budget progress
- Quick action buttons (voice, photo, chat, stats)
- Recent transactions list with categorization
- Shimmer loading animations

**Key Providers**:
- `dailyQuoteProvider`: Async AI quote fetching
- `isDarkModeProvider`: Theme state management

### 4. Statistics & Analytics

**File**: `lib/features/statistics/statistics_screen.dart`

- Period-based filtering (week/month/year)
- Summary cards (income, expense, savings rate)
- Category breakdown with horizontal bar charts
- Spending trend visualization (bar chart)
- Top transactions list
- Responsive grid layouts

### 5. Daily Journal

**File**: `lib/features/daily_journal/journal_screen.dart`

- Date navigation with page view
- AI-generated journal entries from daily transactions
- Emotion tracking (happy, neutral, sad, frustrated)
- Custom personal notes
- Daily statistics display
- Reflections and tomorrow's goals

**Key Services**:
- `AiService.generateJournalEntry()`: AI journal generation

### 6. Passive Tracking

**File**: `lib/services/passive_tracking_service.dart`

- Continuous location monitoring with stream
- Geofence creation and management
- Automatic expense alerts when entering predefined areas
- Distance calculation using Haversine formula
- Permission management (location, photos, microphone)

### 7. Settings

**File**: `lib/features/settings/settings_screen.dart`

- Dark mode toggle
- Language selection
- Notification preferences
- Location tracking toggle
- Budget configuration (daily/monthly)
- Premium subscription management
- Account security
- Privacy & terms

## Design System

### Theme (AppTheme)

**Warm & Friendly Color Palette**:
- Primary: Orange to Coral gradient (FF9500 → FF6B6B)
- Accent Green: #4CAF50 (AI Secretary)
- Warning Yellow: #FFC107 (Statistics)
- Success: #66BB6A

**Typography**:
- Body: Google Poppins font family
- Code: JetBrains Mono (for logs/debug)

**Spacing Constants**:
- XSmall: 4px
- Small: 8px
- Medium: 16px
- Large: 24px
- XLarge: 32px

**Border Radius**:
- Small: 8px
- Medium: 12px
- Large: 16px
- XLarge: 24px

## State Management with Riverpod

### Key Providers

```dart
// Authentication
final isAuthenticatedProvider → bool
final currentUserProvider → FutureProvider<User?>
final authStateChangesProvider → StreamProvider<AuthState>

// Voice Entry
final voiceServiceProvider → VoiceService
final voiceListeningProvider → StateProvider<bool>
final recognizedTextProvider → StateProvider<String>
final confidenceProvider → StateProvider<double>

// AI Services
final aiServiceProvider → AiService
final aiResponseProvider → FutureProvider<String>
final dailyQuoteProvider → FutureProvider<String>
final chatMessageProvider → StateProvider<List<ChatMessage>>

// Passive Tracking
final passiveTrackingProvider → PassiveTrackingService
final currentLocationProvider → StreamProvider<Position?>
final geofenceAlertsProvider → StreamProvider<GeofenceAlert>

// Theme
final isDarkModeProvider → StateProvider<bool>
```

## Supabase Integration

### Database Schema (PostgreSQL)

```sql
-- Users table (managed by Auth)
-- Custom columns can be added via profiles

-- Transactions table
CREATE TABLE transactions (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users,
  amount DECIMAL(12, 2),
  type TEXT, -- 'income' | 'expense'
  category TEXT, -- category enum
  created_at TIMESTAMP,
  description TEXT,
  notes TEXT,
  voice_transcript TEXT,
  photo_url TEXT,
  latitude DECIMAL(9, 6),
  longitude DECIMAL(9, 6),
  location_name TEXT,
  is_recurring BOOLEAN,
  recurring_frequency TEXT,
  CREATED_AT TIMESTAMP DEFAULT now()
);

-- User profiles table
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users,
  display_name TEXT,
  avatar_url TEXT,
  bio TEXT,
  total_income DECIMAL(15, 2),
  total_expense DECIMAL(15, 2),
  is_premium BOOLEAN DEFAULT false,
  premium_expires_at TIMESTAMP,
  locale TEXT DEFAULT 'zh_TW',
  theme_mode TEXT DEFAULT 'light',
  daily_budget DECIMAL(10, 2),
  voice_entries INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);
```

### Edge Functions

- `analyze-transaction`: Parse voice transcript and extract details
- `extract-transaction`: Detailed transaction info from transcript
- `chat-with-secretary`: Multi-turn conversation endpoint
- `get-financial-advice`: Generate spending analysis
- `get-daily-quote`: Daily motivational quote
- `analyze-spending`: Spending pattern analysis
- `generate-journal`: AI journal entry generation

## Data Models

### Transaction (Freezed)

```dart
@freezed
class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    required String userId,
    required double amount,
    required TransactionType type,      // expense, income
    required TransactionCategory category, // food, transport, ...
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
}
```

### UserProfile (Freezed)

```dart
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
    // ... other fields
  }) = _UserProfile;
}
```

## Routing with Go Router

**Named Routes**:
- `/auth` - Authentication (login/signup)
- `/onboarding` - Feature introduction
- `/dashboard` - Home screen
- `/voice-entry` - Voice recording
- `/ai-secretary` - Chat interface
- `/statistics` - Analytics
- `/journal` - Daily journaling
- `/settings` - Preferences

**Bottom Navigation Bar**:
- Persists across all main routes (shell route)
- 6 navigation items with icons

## Permissions

Required permissions in `AndroidManifest.xml` and `Info.plist`:
- Microphone (voice input)
- Location (geofencing & tracking)
- Photos (photo analysis)
- Notifications (alerts)

## Development Workflow

### Code Generation

```bash
# Generate Freezed models, Riverpod providers, JSON serialization
flutter pub run build_runner build --delete-conflicting-outputs

# Watch for changes
flutter pub run build_runner watch
```

### Testing

```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/
```

### Building for Production

```bash
# Android
flutter build apk --split-per-abi
flutter build appbundle

# iOS
flutter build ios --release
```

## Performance Optimizations

1. **Riverpod Code Generation**: Compile-time dependency injection
2. **Hive Local Caching**: Offline-first data synchronization
3. **Lazy Loading**: Stream-based pagination in lists
4. **Image Optimization**: Cached network image with compression
5. **Voice Streaming**: Real-time transcription with chunking
6. **Location Filtering**: 10m distance threshold before updates

## Security Considerations

1. **Environment Variables**: Sensitive keys in `.env` (not committed)
2. **Supabase RLS**: Row-level security for database tables
3. **JWT Tokens**: Automatic token refresh by `supabase_flutter`
4. **Voice Data**: Transcript stored locally before upload
5. **Location Data**: Only shared with Supabase when permitted

## Internationalization (i18n)

Currently supports Traditional Chinese (zh_TW). Extensible via `intl` package:

```dart
final dateFormat = DateFormat('yyyy年MM月dd日', 'zh_TW');
final timeFormat = DateFormat('HH:mm', 'zh_TW');
```

## Next Steps

1. Implement RevenueCat subscription management
2. Add image analysis for photo-based expense entry
3. Implement advanced ML-based spending predictions
4. Add social sharing of finance insights
5. Integrate calendar view for monthly planning
6. Add export to CSV/PDF for financial advisors

## Troubleshooting

### Speech-to-text not working
- Check microphone permissions
- Ensure device locale supports Chinese (zh_TW)
- Test with `speech_to_text.locales()` to verify language support

### Location services not updating
- Verify location permission status
- Check if device location is enabled
- Test with physical device (not always reliable on emulator)

### Supabase connection errors
- Verify `.env` file contains correct URL and ANON_KEY
- Check internet connectivity
- Confirm Supabase project is active

## License

[Your License Here]

## Support

For issues and feature requests, please open a GitHub issue or contact support@voiceledger.app
