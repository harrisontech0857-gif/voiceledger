import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart' show kMockMode;
import '../features/auth/auth_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/consent_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/voice_entry/voice_entry_screen.dart';
import '../features/ai_secretary/chat_screen.dart';
import '../features/statistics/statistics_screen.dart';
import '../features/daily_journal/journal_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/couples/pairing_screen.dart';
import '../features/subscription/paywall_screen.dart';
import '../features/legal/privacy_policy_screen.dart';
import '../features/legal/terms_of_service_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// 路由設定提供者
///
/// 管理應用程式導航，包含認證流和路由防護
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    redirect: (context, state) {
      // Mock 模式：跳過認證，直接進入 Dashboard
      if (kMockMode) return null;

      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final isAuthRoute = state.matchedLocation == '/auth';

      if (!isLoggedIn && !isAuthRoute) {
        return '/auth';
      }
      if (isLoggedIn && isAuthRoute) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/consent',
        builder: (context, state) => const ConsentScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/ai-secretary',
            builder: (context, state) => const ChatScreen(),
          ),
          GoRoute(
            path: '/journal',
            builder: (context, state) => const JournalScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/voice-entry',
        builder: (context, state) => const VoiceEntryScreen(),
      ),
      GoRoute(
        path: '/pairing',
        builder: (context, state) => const PairingScreen(),
      ),
      GoRoute(
        path: '/paywall',
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsOfServiceScreen(),
      ),
    ],
  );
});

/// 主導覽頁面 Shell — 懸浮底部導航 + 語音圓形按鈕
class MainShell extends StatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _routes = [
    '/dashboard',
    '/ai-secretary',
    '/journal',
    '/settings',
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final idx = _routes.indexOf(location);
    if (idx >= 0) _currentIndex = idx;

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: widget.child,
      extendBody: true,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            // 懸浮導航列本體
            Container(
              height: 64,
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.home_rounded,
                    label: '首頁',
                    isSelected: _currentIndex == 0,
                    onTap: () => _goTo(0),
                    color: cs,
                  ),
                  _NavItem(
                    icon: Icons.smart_toy_rounded,
                    label: 'AI 秘書',
                    isSelected: _currentIndex == 1,
                    onTap: () => _goTo(1),
                    color: cs,
                  ),
                  // 中間留空給語音按鈕
                  const SizedBox(width: 56),
                  _NavItem(
                    icon: Icons.auto_stories_rounded,
                    label: '日記',
                    isSelected: _currentIndex == 2,
                    onTap: () => _goTo(2),
                    color: cs,
                  ),
                  _NavItem(
                    icon: Icons.settings_rounded,
                    label: '設定',
                    isSelected: _currentIndex == 3,
                    onTap: () => _goTo(3),
                    color: cs,
                  ),
                ],
              ),
            ),

            // 語音圓形按鈕（突出在導航列上方）
            Positioned(
              top: -22,
              child: GestureDetector(
                onTap: () => context.push('/voice-entry'),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [cs.primary, cs.tertiary],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withAlpha(60),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mic_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goTo(int index) {
    setState(() => _currentIndex = index);
    context.go(_routes[index]);
  }
}

/// 導航列單一項目
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme color;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? color.primary : color.onSurfaceVariant,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? color.primary : color.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
