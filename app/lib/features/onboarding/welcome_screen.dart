import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  String? _selectedRole; // 'proactive' or 'passive'
  late AnimationController _fadeAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _bounceAnimationController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _bounceAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    // Start fade animation
    _fadeAnimationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeAnimationController.dispose();
    _pulseAnimationController.dispose();
    _bounceAnimationController.dispose();
    super.dispose();
  }

  void _nextPage() {
    // Page 2 (index 1) requires role selection
    if (_currentPage == 1 && _selectedRole == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請先選擇你的角色')));
      return;
    }

    if (_currentPage < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipToEnd() {
    _pageController.jumpToPage(5);
  }

  Future<void> _completeWelcome() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save role selection
      if (_selectedRole != null) {
        await prefs.setString('relationship_role', _selectedRole!);
      }

      // Request microphone permission
      if (mounted) {
        await Permission.microphone.request();
      }

      // Mark welcome as complete
      if (mounted) {
        await prefs.setBool('welcome_complete', true);
        if (mounted) {
          context.go('/setup');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('錯誤: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // PageView
          PageView(
            controller: _pageController,
            onPageChanged: (page) {
              setState(() => _currentPage = page);
            },
            children: [
              // Page 1: Welcome
              _Page1Welcome(fadeAnimation: _fadeAnimationController),
              // Page 2: Role Selection
              _Page2RoleSelection(
                selectedRole: _selectedRole,
                onRoleSelected: (role) {
                  setState(() => _selectedRole = role);
                },
              ),
              // Page 3: Voice Diary
              _Page3VoiceDiary(pulseAnimation: _pulseAnimationController),
              // Page 4: Shared Pet
              _Page4SharedPet(bounceAnimation: _bounceAnimationController),
              // Page 5: Partner Diary
              const _Page5PartnerDiary(),
              // Page 6: Ready to Start
              const _Page6ReadyToStart(),
            ],
          ),

          // Bottom Navigation
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(top: BorderSide(color: cs.outlineVariant)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      6,
                      (index) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: _currentPage == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color:
                                _currentPage == index
                                    ? cs.primary
                                    : cs.outlineVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Buttons
                  Row(
                    children: [
                      if (_currentPage > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: const Text('上一步'),
                          ),
                        ),
                      if (_currentPage > 0)
                        const SizedBox(width: AppSpacing.md),
                      if (_currentPage < 5)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _skipToEnd,
                            child: const Text('略過'),
                          ),
                        ),
                      if (_currentPage < 5)
                        const SizedBox(width: AppSpacing.md),
                      if (_currentPage < 5)
                        Expanded(
                          child: FilledButton(
                            onPressed: _nextPage,
                            child: const Text('下一步'),
                          ),
                        ),
                      if (_currentPage == 5)
                        Expanded(
                          child: FilledButton(
                            onPressed: _completeWelcome,
                            child: const Text('開始使用'),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============= PAGE 1: Welcome =============
class _Page1Welcome extends StatelessWidget {
  final AnimationController fadeAnimation;

  const _Page1Welcome({required this.fadeAnimation});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Icon
            const Text('🐱💕', style: TextStyle(fontSize: 80)),
            const SizedBox(height: AppSpacing.lg),

            // Title
            Text(
              '歡迎來到語記',
              style: Theme.of(
                context,
              ).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),

            // Subtitle
            Text(
              '和你最重要的人，一起記錄生活',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ============= PAGE 2: Role Selection =============
class _Page2RoleSelection extends StatelessWidget {
  final String? selectedRole;
  final Function(String) onRoleSelected;

  const _Page2RoleSelection({
    required this.selectedRole,
    required this.onRoleSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: AppSpacing.lg),

            // Title
            Text(
              '你在關係中是什麼角色？',
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Subtitle
            Text(
              '這會影響寵物和你說話的方式',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Role 1: Proactive
            _RoleCard(
              emoji: '💪',
              title: '主動型',
              subtitle: '你喜歡主動關心對方，常常是先開口的那個人',
              isSelected: selectedRole == 'proactive',
              onTap: () => onRoleSelected('proactive'),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Role 2: Passive
            _RoleCard(
              emoji: '🌸',
              title: '被動型',
              subtitle: '你比較害羞內斂，但心裡很在乎對方',
              isSelected: selectedRole == 'passive',
              onTap: () => onRoleSelected('passive'),
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? cs.primary : cs.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          color:
              isSelected
                  ? cs.primaryContainer.withAlpha(50)
                  : cs.surfaceContainerLow,
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: cs.primary, size: 24),
          ],
        ),
      ),
    );
  }
}

// ============= PAGE 3: Voice Diary Feature =============
class _Page3VoiceDiary extends StatelessWidget {
  final AnimationController pulseAnimation;

  const _Page3VoiceDiary({required this.pulseAnimation});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: AppSpacing.lg),

            // Pulsing Mic Icon
            ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 1.15).animate(
                CurvedAnimation(
                  parent: pulseAnimation,
                  curve: Curves.easeInOut,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.mic_rounded, size: 64, color: cs.primary),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Title
            Text(
              '說出你的一天',
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Features
            _FeatureItem(emoji: '🎙️', text: '對著手機說話，AI 幫你寫成日記'),
            const SizedBox(height: AppSpacing.md),
            _FeatureItem(emoji: '😊', text: '自動分析你的情緒和心情'),
            const SizedBox(height: AppSpacing.md),
            _FeatureItem(emoji: '🏷️', text: '智慧標籤，輕鬆回顧每一天'),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

// ============= PAGE 4: Shared Pet Feature =============
class _Page4SharedPet extends StatelessWidget {
  final AnimationController bounceAnimation;

  const _Page4SharedPet({required this.bounceAnimation});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: AppSpacing.lg),

            // Bouncing Cat Emoji
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0),
                end: const Offset(0, -0.1),
              ).animate(
                CurvedAnimation(
                  parent: bounceAnimation,
                  curve: Curves.easeInOut,
                ),
              ),
              child: const Text('🐱', style: TextStyle(fontSize: 80)),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Title
            Text(
              '一起養寵物',
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Features
            _FeatureItem(emoji: '🍚', text: '你寫日記 = 餵寵物一餐'),
            const SizedBox(height: AppSpacing.md),
            _FeatureItem(emoji: '🔄', text: '輪流餵食，兩人都要寫才會飽'),
            const SizedBox(height: AppSpacing.md),
            _FeatureItem(emoji: '⭐', text: '寵物會從蛋進化到大師級！'),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

// ============= PAGE 5: Partner Diary Feature =============
class _Page5PartnerDiary extends StatelessWidget {
  const _Page5PartnerDiary();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: AppSpacing.lg),

            // Two overlapping cards illustration
            Stack(
              alignment: Alignment.center,
              children: [
                // Card 1
                Transform.translate(
                  offset: const Offset(-20, -10),
                  child: Container(
                    width: 100,
                    height: 120,
                    decoration: BoxDecoration(
                      color: cs.primary.withAlpha(180),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withAlpha(60),
                          blurRadius: 8,
                          offset: const Offset(2, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_stories_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
                // Card 2
                Transform.translate(
                  offset: const Offset(20, 10),
                  child: Container(
                    width: 100,
                    height: 120,
                    decoration: BoxDecoration(
                      color: cs.tertiary.withAlpha(180),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      boxShadow: [
                        BoxShadow(
                          color: cs.tertiary.withAlpha(60),
                          blurRadius: 8,
                          offset: const Offset(2, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_stories_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Title
            Text(
              '互看日記，更懂彼此',
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Features
            _FeatureItem(emoji: '📖', text: '看到對方的一天是怎麼過的'),
            const SizedBox(height: AppSpacing.md),
            _FeatureItem(emoji: '💭', text: '了解對方的心情和感受'),
            const SizedBox(height: AppSpacing.md),
            _FeatureItem(emoji: '🔒', text: '只有你們兩個人看得到'),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

// ============= PAGE 6: Ready to Start =============
class _Page6ReadyToStart extends StatelessWidget {
  const _Page6ReadyToStart();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: AppSpacing.lg),

            // Sparkle decoration
            const Text('✨', style: TextStyle(fontSize: 80)),
            const SizedBox(height: AppSpacing.xl),

            // Title
            Text(
              '準備好了嗎？',
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),

            // Subtitle
            Text(
              '接下來設定你的暱稱和寵物',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Info text
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('我們會需要：', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: AppSpacing.sm),
                  Text('• 你的暱稱', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '• 寵物的名字和個性',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '• 允許使用麥克風',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

// ============= Reusable Feature Item =============
class _FeatureItem extends StatelessWidget {
  final String emoji;
  final String text;

  const _FeatureItem({required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
