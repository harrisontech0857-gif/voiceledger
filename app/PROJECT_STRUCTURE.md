# VoiceLedger Project Structure

Complete file organization and architectural overview for the Flutter application.

## Directory Tree

```
voiceledger/
├── lib/
│   ├── main.dart                                 # App entry point with Riverpod scope
│   │
│   ├── core/
│   │   ├── env.dart                             # Environment variables (Envied)
│   │   ├── theme.dart                           # Design system & Material themes
│   │   ├── app_router.dart                      # Go Router configuration
│   │   └── supabase_client.dart                 # Supabase providers & auth state
│   │
│   ├── models/                                  # Data models (Freezed)
│   │   ├── transaction.dart                     # Transaction data model
│   │   │   └── Freezed annotation-based
│   │   │   └── Supabase serialization
│   │   │   └── Category enum with extensions
│   │   └── user_profile.dart                    # User profile model
│   │       └── Premium subscription state
│   │       └── Settings persistence
│   │
│   ├── services/                                # Business logic & API integration
│   │   ├── voice_service.dart                   # Speech-to-text wrapper
│   │   │   ├── Initialize speech recognition
│   │   │   ├── Real-time listening streams
│   │   │   ├── Language support (zh_TW)
│   │   │   └── Error handling & logging
│   │   │
│   │   ├── ai_service.dart                      # AI & Supabase Edge Functions
│   │   │   ├── analyzeTransaction()
│   │   │   ├── sendMessage() - multi-turn chat
│   │   │   ├── getDailyQuote()
│   │   │   ├── getFinancialAdvice()
│   │   │   ├── analyzeSpendingPatterns()
│   │   │   ├── generateJournalEntry()
│   │   │   └── extractTransactionDetails()
│   │   │
│   │   └── passive_tracking_service.dart        # Location & geofencing
│   │       ├── Real-time position stream
│   │       ├── Geofence management
│   │       ├── Permission handling
│   │       ├── Distance calculation
│   │       └── Alert broadcasting
│   │
│   └── features/                                # Feature modules
│       │
│       ├── auth/                                # Authentication module
│       │   └── auth_screen.dart
│       │       ├── Email/password login
│       │       ├── Account creation
│       │       ├── OAuth integration
│       │       └── Supabase Auth integration
│       │
│       ├── onboarding/                          # Feature introduction
│       │   └── onboarding_screen.dart
│       │       ├── 5-page PageView carousel
│       │       ├── Feature descriptions
│       │       ├── Permission requests
│       │       └── Skip/continue flow
│       │
│       ├── dashboard/                           # Home screen & summary
│       │   ├── dashboard_screen.dart
│       │   │   ├── Daily quote card (AI)
│       │   │   ├── Today's spending summary
│       │   │   ├── Budget progress indicator
│       │   │   ├── Quick action buttons
│       │   │   ├── Recent transactions list
│       │   │   └── Shimmer loading animations
│       │   │
│       │   └── widgets/
│       │       ├── Shimmer effect
│       │       └── Transaction tiles
│       │
│       ├── voice_entry/                        # Core voice recording (★ MAIN FEATURE)
│       │   └── voice_entry_screen.dart
│       │       ├── Animated microphone button
│       │       ├── Real-time transcription
│       │       ├── AI confidence scoring
│       │       ├── Transaction extraction
│       │       ├── Confirmation dialog
│       │       ├── Category auto-detection
│       │       └── Supabase transaction save
│       │
│       ├── ai_secretary/                       # Chat interface with AI
│       │   └── chat_screen.dart
│       │       ├── Multi-turn conversation
│       │       ├── Message history
│       │       ├── Chat bubbles (user vs AI)
│       │       ├── Suggestion chips
│       │       ├── Real-time typing indicators
│       │       └── Edge Function integration
│       │
│       ├── statistics/                         # Financial analytics
│       │   └── statistics_screen.dart
│       │       ├── Period selector (week/month/year)
│       │       ├── Summary cards
│       │       │   ├── Total expense
│       │       │   ├── Total income
│       │       │   ├── Net savings
│       │       │   └── Avg daily spend
│       │       ├── Category breakdown
│       │       │   └── Horizontal progress bars
│       │       ├── Spending trend chart
│       │       │   └── Bar chart by day
│       │       └── Top transactions list
│       │
│       ├── daily_journal/                      # Personal journaling
│       │   └── journal_screen.dart
│       │       ├── Date navigation (PageView)
│       │       ├── AI-generated entry
│       │       ├── Daily statistics
│       │       ├── Emotion tracking (emojis)
│       │       ├── Personal notes
│       │       ├── Reflections & goals
│       │       └── Entry save/edit
│       │
│       └── settings/                           # User preferences
│           └── settings_screen.dart
│               ├── User profile section
│               ├── Display settings
│               │   ├── Dark mode toggle
│               │   └── Language selection
│               ├── Notifications toggle
│               ├── Location tracking toggle
│               ├── Budget configuration
│               ├── Premium subscription
│               ├── Account security
│               ├── Privacy & terms
│               └── Logout button
│
├── pubspec.yaml                                 # Project configuration & dependencies
├── .env.example                                 # Example environment variables
├── README.md                                    # Project documentation
├── PROJECT_STRUCTURE.md                         # This file
└── analysis_options.yaml                        # Linter configuration
```

## Core Files Detailed

### `lib/main.dart`
**Purpose**: Application entry point and setup

**Key Responsibilities**:
1. Initialize Hive for local caching
2. Register Hive adapters for data models
3. Initialize Supabase with authentication callback
4. Set up Riverpod `ProviderScope`
5. Configure Material app with router

**Code Structure**:
```dart
main() async {
  // Initialize Hive, Supabase
  Supabase.initialize()
  runApp(ProviderScope(child: VoiceLedgerApp()))
}
```

### `lib/core/theme.dart`
**Purpose**: Centralized design system and Material themes

**Exports**:
- `AppTheme` class with static constants
- `lightTheme` and `darkTheme` MaterialTheme objects
- Color palette (warm orange/coral/green)
- Typography (Poppins font)
- Spacing & radius constants
- Shadow utilities
- Gradient definitions
- `isDarkModeProvider` for theme state

**Key Colors**:
```dart
primaryGradientStart = Color(0xFFFF9500)  // Warm orange
primaryGradientEnd = Color(0xFFFF6B6B)    // Coral red
accentGreen = Color(0xFF4CAF50)           // AI secretary
warningYellow = Color(0xFFFFC107)         // Alerts
successGreen = Color(0xFF66BB6A)          // Success states
```

### `lib/core/app_router.dart`
**Purpose**: Route configuration with Go Router

**Routing Structure**:
- **Shell Route**: Bottom navigation persistence
- **Auth Routes**: Login/signup/onboarding flow
- **Main Routes**: Dashboard, voice entry, chat, statistics, journal, settings
- **Transitions**: Fade + slide animations

**Route Tree**:
```
/auth                 (no bottom nav)
/onboarding          (no bottom nav)
Shell
├── /dashboard       (tab 0)
├── /voice-entry     (tab 1)
├── /ai-secretary    (tab 2)
├── /statistics      (tab 3)
├── /journal         (tab 4)
└── /settings        (tab 5)
```

### `lib/core/supabase_client.dart`
**Purpose**: Supabase initialization and provider setup

**Providers Exported**:
- `supabaseClientProvider` - Raw Supabase client
- `supabaseAuthProvider` - Auth client
- `userIdProvider` - Current user ID
- `isAuthenticatedProvider` - Auth state boolean
- `currentUserProvider` - Current user async data
- `authStateChangesProvider` - Auth stream

**Usage Pattern**:
```dart
final client = ref.watch(supabaseClientProvider);
final isAuth = ref.watch(isAuthenticatedProvider);
final authStream = ref.watch(authStateChangesProvider);
```

### `lib/services/voice_service.dart`
**Purpose**: Speech-to-text wrapper and voice management

**Key Methods**:
- `initialize()` - Set up speech recognition
- `startListening()` - Begin listening with stream
- `listenOnce()` - Single recognition session (up to 5 min)
- `stopListening()` - End current session
- `getAvailableLanguages()` - List supported locales

**Providers**:
- `voiceServiceProvider` - Singleton service instance
- `voiceListeningProvider` - Current listening state
- `recognizedTextProvider` - Current transcript text
- `confidenceProvider` - Recognition confidence score

**Features**:
- Chinese (zh_TW) language support
- Real-time partial results
- Automatic silence detection
- Error handling with logging

### `lib/services/ai_service.dart`
**Purpose**: AI analysis and Supabase Edge Functions integration

**Key Methods**:
1. `analyzeTransaction(String)` - Parse voice to transaction
2. `getFinancialAdvice(Map)` - Spending analysis
3. `getDailyQuote()` - Motivational quote
4. `sendMessage(String, List)` - Multi-turn chat
5. `analyzeSpendingPatterns(List)` - Pattern detection
6. `generateJournalEntry(List)` - AI journal writing
7. `extractTransactionDetails(String)` - Detailed parsing

**Data Models**:
- `ChatMessage` - Conversation data class
  - id, content, isUser, timestamp, suggestion

**Integration Points**:
- Calls Supabase Edge Functions via `.functions.invoke()`
- Returns structured JSON responses
- Includes error handling and logging

### `lib/services/passive_tracking_service.dart`
**Purpose**: Location tracking and geofence management

**Key Classes**:
- `GeofenceLocation` - Fence definition (lat, long, radius, category)
- `GeofenceAlert` - Crossing event (location, isEntering, timestamp)

**Key Methods**:
- `startLocationTracking()` - Begin streaming updates
- `getCurrentLocation()` - Single location query
- `addGeofence()` - Register new fence
- `removeGeofence()` - Remove fence by ID
- `getActiveGeofences()` - Current fence list

**Streams**:
- `getLocationStream()` - Position updates (10m filter)
- `getGeofenceAlerts()` - Fence entry/exit alerts

**Providers**:
- `passiveTrackingProvider` - Service singleton
- `currentLocationProvider` - Location stream
- `geofenceAlertsProvider` - Alert stream

### `lib/models/transaction.dart`
**Purpose**: Transaction data model with serialization

**Fields**:
- id, userId, amount, type (income/expense)
- category (food, transport, entertainment, etc.)
- createdAt, description, notes
- voiceTranscript, photoUrl
- latitude, longitude, locationName
- isRecurring, recurringFrequency
- isSynced

**Enums**:
```dart
enum TransactionType { income, expense }
enum TransactionCategory {
  food, transport, entertainment, shopping, utilities,
  health, education, investment, salary, other
}
```

**Extensions**:
- `displayName` - Localized category name (zh_TW)
- `icon` - Emoji icon for category

**Serialization**:
- Freezed annotation-based
- `fromJson()` / `toJson()` for JSON
- `fromSupabase()` / `toSupabase()` for database

### `lib/features/voice_entry/voice_entry_screen.dart`
**Purpose**: Core voice recording UI with AI feedback

**UI Components**:
1. **Animated Microphone Button**
   - Circular gradient container
   - Pulse animation when listening
   - Large tap target (160x160)

2. **Status Display**
   - "Listening...", "Processing...", "Ready"
   - Real-time transcription text
   - AI response box with green background

3. **Confirmation Dialog**
   - Extracted transaction details
   - AI feedback/suggestions
   - Editable fields
   - Save/cancel buttons

**State Management**:
- `_isListening` - Current recording state
- `_recognizedText` - Transcript from speech
- `_aiResponse` - AI analysis feedback
- `_isProcessing` - API call in progress

**Flow**:
1. User taps mic → Start listening
2. Real-time transcript appears
3. On stop → Process with AI
4. Show confirmation with details
5. User confirms → Save to Supabase

**Features**:
- Automatic category detection
- Confidence-based validation
- Transaction save with voice transcript
- Location integration (if available)

### `lib/features/dashboard/dashboard_screen.dart`
**Purpose**: Home screen with spending summary and quick actions

**Sections**:
1. **Daily Quote Card**
   - Gradient background
   - Shimmer loading effect
   - AI-generated quote

2. **Today's Summary**
   - Total spending: NT$ amount
   - Budget progress bar (%)
   - Date and budget info

3. **Quick Action Grid**
   - Voice entry button
   - Photo capture button
   - Ask secretary button
   - View stats button

4. **Recent Transactions**
   - List of 5 most recent transactions
   - Category emoji + description
   - Amount (red) and time
   - Tap to view details

**Providers**:
- `dailyQuoteProvider` - AI quote
- `isDarkModeProvider` - Theme toggle

**Interactions**:
- Pull-to-refresh updates quote
- Bottom nav item for quick voice entry
- Links to other screens

### `lib/features/ai_secretary/chat_screen.dart`
**Purpose**: Multi-turn conversational AI interface

**UI Structure**:
1. **Chat Bubble List**
   - User messages: right-aligned, orange gradient
   - AI messages: left-aligned, light card
   - Timestamps for each message
   - Scrollable with auto-scroll to bottom

2. **Message Input Area**
   - Text field with char counter
   - Suggestion chips below input
   - Send button (circular, gradient)
   - Safe area padding

3. **Features**:
   - Real-time typing indicators
   - Suggestion quick-reply chips
   - Message editing (long-press)
   - Share response (long-press)

**State**:
- `_messages` - Conversation history
- `_isSending` - Send button disabled state
- `_messageController` - Text input control

**Integration**:
- `AiService.sendMessage()` calls Edge Function
- Maintains conversation context
- Returns suggestions for next queries

### `lib/features/daily_journal/journal_screen.dart`
**Purpose**: Personal finance journaling with AI generation

**Components**:
1. **Date Navigation**
   - Previous/next day buttons
   - Current date display (MMM dd, YYYY)
   - Day of week
   - PageView for swiping

2. **AI Journal Entry**
   - Auto-generated from daily transactions
   - Spending summary
   - Insights and patterns
   - Personal reflections
   - Tomorrow's goals

3. **Daily Statistics**
   - Transaction count
   - Total spending
   - Budget usage %
   - Savings rate

4. **Emotion Tracker**
   - 4 emoji buttons (happy, neutral, sad, frustrated)
   - Toggle selection
   - Save with entry

5. **Personal Notes**
   - Multi-line text input
   - Save button
   - Persist to database

**Layout**:
- Scrollable single-page view per day
- Separate cards for each section
- Mobile-optimized spacing

### `lib/features/statistics/statistics_screen.dart`
**Purpose**: Comprehensive financial analytics and reporting

**Sections**:
1. **Period Selector**
   - Week / Month / Year tabs
   - State management for filtering

2. **Summary Cards** (2x2 grid)
   - Total expense (with trend ↓)
   - Total income (with trend ↑)
   - Net savings (with %)
   - Average daily spend (vs budget)

3. **Category Breakdown**
   - Horizontal bar chart per category
   - Amount labels
   - Percentage display
   - 5 top categories

4. **Trend Chart**
   - 7-day bar chart
   - Values above bars
   - Day labels below
   - Gradient bars

5. **Top Transactions**
   - 3 highest spending transactions
   - Category emoji + date
   - Sortable by amount

**Interactions**:
- Switch periods to filter data
- Tap category for detailed view
- Tap transaction for details

### `lib/features/settings/settings_screen.dart`
**Purpose**: User preferences and account management

**Sections**:
1. **User Profile**
   - Avatar + display name
   - Email address
   - Edit button

2. **Display**
   - Dark mode toggle
   - Language selector (zh_TW)

3. **Notifications**
   - Enable/disable toggle
   - Fine-grained settings
   - Sound & vibration

4. **Tracking**
   - Location tracking toggle
   - Geofence alerts
   - Photo analysis

5. **Budget**
   - Daily budget input
   - Monthly budget input
   - Budget goals

6. **Account**
   - Change password
   - Privacy policy link
   - Terms of service link

7. **Premium**
   - Subscription status
   - Feature list
   - Upgrade button

8. **About**
   - App version
   - Report issue link
   - Check for updates

9. **Logout**
   - Confirmation dialog
   - Clears local cache
   - Redirects to auth

### `lib/features/auth/auth_screen.dart`
**Purpose**: User authentication (login/signup)

**UI**:
1. **Header**
   - App logo "語記"
   - Tagline "AI 財務秘書"

2. **Tab Switcher**
   - Login / Signup toggle
   - Animated transition

3. **Form Fields**
   - Email input
   - Password input
   - Show/hide password toggle

4. **Actions**
   - Login/Create Account button (state: loading)
   - Forgot password link
   - Divider
   - Google OAuth button

**Flow**:
1. User enters credentials
2. Submit → Supabase Auth
3. Success → Redirect to onboarding
4. Error → Show error message

**Integration**:
- Supabase email/password auth
- OAuth providers (Google, GitHub)
- Error message display
- Loading state management

### `lib/features/onboarding/onboarding_screen.dart`
**Purpose**: Feature introduction and permission requests

**Pages** (5-page PageView):
1. Voice Entry
   - Icon: microphone
   - Description: natural language input

2. AI Secretary
   - Icon: robot/chat
   - Description: conversational advice

3. Passive Tracking
   - Icon: location pin
   - Description: geofence & photo analysis

4. Smart Analytics
   - Icon: trending up
   - Description: spending insights

5. Daily Journal
   - Icon: book
   - Description: personal finance stories

**Navigation**:
- Dot indicators (5 dots)
- Previous/Next buttons
- Skip button (only early pages)
- Start Using button (final page)

**Permissions** (on final screen):
- Microphone
- Location
- Photos
- Notifications

**Flow**:
- New users → Auto onboarding
- Can skip mid-way
- Can revisit in settings

## File Statistics

| Category | Count | Screens | Services | Models |
|----------|-------|---------|----------|--------|
| Features | 7 | 7 | - | - |
| Services | 3 | - | 3 | - |
| Models | 2 | - | - | 2 |
| Core | 4 | - | - | - |
| **Total** | **16** | **7** | **3** | **2** |

## Dependency Graph

```
main.dart
├── Riverpod (ProviderScope)
├── Supabase (initialization)
├── Hive (local DB)
├── GoRouter (navigation)
├── AppTheme (Material design)
└── Features
    ├── Auth (Supabase Auth)
    ├── Onboarding (Permissions)
    ├── Dashboard (Providers, Services)
    ├── VoiceEntry (VoiceService, AiService)
    ├── AiSecretary (AiService)
    ├── Statistics (Data visualization)
    ├── Journal (AiService)
    └── Settings (Theme, Preferences)
```

## Code Generation Files (generated, not in repo)

```
lib/
├── models/
│   ├── transaction.freezed.dart          # Freezed codegen
│   ├── transaction.g.dart                # JSON serialization
│   ├── user_profile.freezed.dart         # Freezed codegen
│   └── user_profile.g.dart               # JSON serialization
├── core/
│   └── env.g.dart                        # Envied codegen
└── services/
    └── *.g.dart                          # Riverpod codegen (future)
```

## Build Configuration

**pubspec.yaml Sections**:
- `dependencies`: Runtime packages
- `dev_dependencies`: Build-time tools
  - `build_runner`
  - `freezed`
  - `json_serializable`
  - `hive_generator`
  - `riverpod_generator`
  - `envied_generator`

**Code generation command**:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## State Management Pattern

All screens follow **Riverpod provider pattern**:

```dart
// In service
final serviceProvider = Provider((ref) => Service());

// In screen
ref.watch(serviceProvider)        // Read & watch
ref.read(serviceProvider)         // Read once
ref.refresh(serviceProvider)      // Manual refresh
ref.watch(serviceProvider.future) // Wait for async
```

## Naming Conventions

- **Classes**: PascalCase (`VoiceLedgerApp`, `ChatScreen`)
- **Files**: snake_case (`voice_service.dart`, `chat_screen.dart`)
- **Providers**: camelCase + `Provider` suffix (`voiceServiceProvider`)
- **Methods**: camelCase (`startListening()`, `sendMessage()`)
- **Constants**: UPPER_CASE (inside classes: `AppTheme.spacingMedium`)
- **Private members**: Leading underscore (`_isListening`, `_controller`)

## Version Control

**.gitignore** includes:
- `/build` - Flutter build output
- `/ios`, `/android` - Native builds
- `.dart_tool/` - Build artifacts
- `.env` - Environment secrets
- `*.iml` - IDE files
- `pubspec.lock` - Lock file (optional)

## Next Implementation Steps

1. **Backend Setup**
   - Create Supabase tables (transactions, user_profiles)
   - Implement Edge Functions
   - Set up RLS policies

2. **Testing**
   - Unit tests for services
   - Widget tests for screens
   - Integration tests for flows

3. **Localization**
   - Extract hardcoded strings to i18n
   - Add Traditional Chinese (zh_TW)
   - Support additional languages

4. **Advanced Features**
   - Photo analysis with ML
   - Spending predictions
   - Smart budgeting alerts
   - Social sharing

5. **DevOps**
   - CI/CD pipeline (GitHub Actions)
   - App signing & release
   - Crash reporting (Sentry)
   - Analytics (Mixpanel)
