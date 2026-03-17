import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'supabase_client.dart';
import '../features/auth/auth_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/voice_entry/voice_entry_screen.dart';
import '../features/ai_secretary/chat_screen.dart';
import '../features/statistics/statistics_screen.dart';
import '../features/daily_journal/journal_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/onboarding/onboarding_screen.dart';

// Route names
class Routes {
  static const String auth = '/auth';
  static const String onboarding = '/onboarding';
  static const String dashboard = '/dashboard';
  static const String voiceEntry = '/voice-entry';
  static const String aiSecretary = '/ai-secretary';
  static const String statistics = '/statistics';
  static const String journal = '/journal';
  static const String settings = '/settings';
}

// Router provider with navigation state
final goRouterProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  final authStateChanges = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: Routes.dashboard,
    redirect: (context, state) {
      // Handle auth redirects
      return authStateChanges.when(
        data: (authState) {
          final isAuth = authState.session != null;

          if (!isAuth && !state.fullPath!.startsWith(Routes.auth)) {
            return Routes.auth;
          }

          if (isAuth && state.fullPath == Routes.auth) {
            return Routes.dashboard;
          }

          return null;
        },
        loading: () => Routes.dashboard,
        error: (_, __) => Routes.auth,
      );
    },
    routes: [
      GoRoute(
        path: Routes.auth,
        pageBuilder: (context, state) => _buildTransitionPage(
          context,
          const AuthScreen(),
          state,
        ),
      ),
      GoRoute(
        path: Routes.onboarding,
        pageBuilder: (context, state) => _buildTransitionPage(
          context,
          const OnboardingScreen(),
          state,
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => _BottomNavShell(child: child),
        routes: [
          GoRoute(
            path: Routes.dashboard,
            pageBuilder: (context, state) => _buildTransitionPage(
              context,
              const DashboardScreen(),
              state,
            ),
          ),
          GoRoute(
            path: Routes.voiceEntry,
            pageBuilder: (context, state) => _buildTransitionPage(
              context,
              const VoiceEntryScreen(),
              state,
            ),
          ),
          GoRoute(
            path: Routes.aiSecretary,
            pageBuilder: (context, state) => _buildTransitionPage(
              context,
              const ChatScreen(),
              state,
            ),
          ),
          GoRoute(
            path: Routes.statistics,
            pageBuilder: (context, state) => _buildTransitionPage(
              context,
              const StatisticsScreen(),
              state,
            ),
          ),
          GoRoute(
            path: Routes.journal,
            pageBuilder: (context, state) => _buildTransitionPage(
              context,
              const JournalScreen(),
              state,
            ),
          ),
          GoRoute(
            path: Routes.settings,
            pageBuilder: (context, state) => _buildTransitionPage(
              context,
              const SettingsScreen(),
              state,
            ),
          ),
        ],
      ),
    ],
  );
});

Page<dynamic> _buildTransitionPage(
  BuildContext context,
  Widget child,
  GoRouterState state,
) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.1, 0.0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      );
    },
  );
}

class _BottomNavShell extends ConsumerWidget {
  final Widget child;

  const _BottomNavShell({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _getSelectedIndex(location),
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: '首頁',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mic_rounded),
            label: '記帳',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_rounded),
            label: '秘書',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up_rounded),
            label: '統計',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_rounded),
            label: '日記',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: '設定',
          ),
        ],
        onTap: (index) => _onNavTap(context, index),
      ),
    );
  }

  int _getSelectedIndex(String location) {
    switch (location) {
      case Routes.dashboard:
        return 0;
      case Routes.voiceEntry:
        return 1;
      case Routes.aiSecretary:
        return 2;
      case Routes.statistics:
        return 3;
      case Routes.journal:
        return 4;
      case Routes.settings:
        return 5;
      default:
        return 0;
    }
  }

  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        GoRouter.of(context).go(Routes.dashboard);
        break;
      case 1:
        GoRouter.of(context).go(Routes.voiceEntry);
        break;
      case 2:
        GoRouter.of(context).go(Routes.aiSecretary);
        break;
      case 3:
        GoRouter.of(context).go(Routes.statistics);
        break;
      case 4:
        GoRouter.of(context).go(Routes.journal);
        break;
      case 5:
        GoRouter.of(context).go(Routes.settings);
        break;
    }
  }
}
