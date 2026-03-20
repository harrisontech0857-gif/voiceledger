import 'dart:math' as math;

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
  String? _communicationStyle;
  String? _recordingHabit;
  late AnimationController _fadeAnimationController;
  late AnimationController _micPulseController;
  late AnimationController _catBounceController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Fade animation for Page 1
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Pulsing mic animation for Page 4
    _micPulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    // Bouncing cat animation for Page 5
    _catBounceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    // Start fade animation after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _fadeAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeAnimationController.dispose();
    _micPulseController.dispose();
    _catBounceController.dispose();
    super.dispose();
  }

  void _nextPage() {
    // Page 2 requires communication style selection
    if (_currentPage == 1 && _communicationStyle == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請先選擇一個選項')));
      return;
    }

    // Page 3 requires recording habit selection
    if (_currentPage == 2 && _recordingHabit == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請先選擇一個選項')));
      return;
    }

    if (_currentPage < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeWelcome() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save selections
      if (_communicationStyle != null) {
        await prefs.setString('communication_style', _communicationStyle!);
      }
      if (_recordingHabit != null) {
        await prefs.setString('recording_habit', _recordingHabit!);
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
          PageView(
            controller: _pageController,
            onPageChanged: (page) {
              setState(() => _currentPage = page);
            },
            children: [
              // Page 1: Welcome
              _Page1Welcome(fadeAnimation: _fadeAnimationController),
              // Page 2: Communication Style
              _Page2CommunicationStyle(
                selectedStyle: _communicationStyle,
                onStyleSelected: (style) {
                  setState(() => _communicationStyle = style);
                },
              ),
              // Page 3: Recording Habit
              _Page3RecordingHabit(
                selectedHabit: _recordingHabit,
                onHabitSelected: (habit) {
                  setState(() => _recordingHabit = habit);
                },
              ),
              // Page 4: Voice Diary Feature
              _Page4VoiceDiary(pulseAnimation: _micPulseController),
              // Page 5: Shared Pet Feature
              _Page5SharedPet(bounceAnimation: _catBounceController),
              // Page 6: Ready to Start
              const _Page6Ready(),
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
                  // Page indicator dots
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
                  // Navigation buttons
                  if (_currentPage < 5)
                    Row(
                      children: [
                        if (_currentPage > 0)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _previousPage,
                              child: const Text('上一步'),
                            ),
                          ),
                        if (_currentPage > 0)
                          const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: FilledButton(
                            onPressed: _nextPage,
                            child: const Text('下一步'),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _previousPage,
                            child: const Text('上一步'),
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

// ============= PAGE 1: Welcome - Emotional Connection =============
class _Page1Welcome extends StatelessWidget {
  final AnimationController fadeAnimation;

  const _Page1Welcome({required this.fadeAnimation});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withAlpha((0.3 * 255).toInt()),
            cs.primary.withAlpha((0.1 * 255).toInt()),
          ],
        ),
      ),
      child: SafeArea(
        child: FadeTransition(
          opacity: fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🌙', style: TextStyle(fontSize: 64)),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  '嘿，歡迎來到語記',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '在這裡，你不需要完美地表達自己\n只要說出來，就夠了',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============= PAGE 2: Communication Style =============
class _Page2CommunicationStyle extends StatelessWidget {
  final String? selectedStyle;
  final Function(String) onStyleSelected;

  const _Page2CommunicationStyle({
    required this.selectedStyle,
    required this.onStyleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.lg),
            Text(
              '想像一下⋯⋯',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '今天對方看起來心情不太好\n你會怎麼做？',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            _OptionCard(
              emoji: '🫂',
              title: '直接問：怎麼了？跟我說',
              isSelected: selectedStyle == 'direct',
              onTap: () => onStyleSelected('direct'),
            ),
            const SizedBox(height: AppSpacing.md),
            _OptionCard(
              emoji: '☕',
              title: '默默泡一杯熱飲，坐在旁邊陪著',
              isSelected: selectedStyle == 'action',
              onTap: () => onStyleSelected('action'),
            ),
            const SizedBox(height: AppSpacing.md),
            _OptionCard(
              emoji: '💬',
              title: '傳個訊息：今天還好嗎？',
              isSelected: selectedStyle == 'text',
              onTap: () => onStyleSelected('text'),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (selectedStyle != null)
              Text(
                '不管哪一種，願意在乎就是最溫柔的事 ✨',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

// ============= PAGE 3: Recording Habit =============
class _Page3RecordingHabit extends StatelessWidget {
  final String? selectedHabit;
  final Function(String) onHabitSelected;

  const _Page3RecordingHabit({
    required this.selectedHabit,
    required this.onHabitSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.lg),
            Text(
              '下班後⋯⋯',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '你通常怎麼記住今天發生的事？',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            _OptionCard(
              emoji: '📱',
              title: '跟朋友或伴侶聊今天的事',
              isSelected: selectedHabit == 'talk',
              onTap: () => onHabitSelected('talk'),
            ),
            const SizedBox(height: AppSpacing.md),
            _OptionCard(
              emoji: '📝',
              title: '自己在腦中回想一下就好',
              isSelected: selectedHabit == 'think',
              onTap: () => onHabitSelected('think'),
            ),
            const SizedBox(height: AppSpacing.md),
            _OptionCard(
              emoji: '📸',
              title: '拍照或發限動記錄',
              isSelected: selectedHabit == 'visual',
              onTap: () => onHabitSelected('visual'),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (selectedHabit != null)
              Text(
                '語記就是你的樹洞，想說的時候說就好 🌱',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

// ============= PAGE 4: Voice Diary Feature =============
class _Page4VoiceDiary extends StatelessWidget {
  final AnimationController pulseAnimation;

  const _Page4VoiceDiary({required this.pulseAnimation});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: AppSpacing.lg),
            // Pulsing mic icon
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
                child: Icon(Icons.mic_rounded, size: 80, color: cs.primary),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              '你只需要⋯⋯說',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            // Quote box
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                border: Border.all(color: cs.outlineVariant),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Text(
                '「今天加班好累，但同事請我喝奶茶，\n突然覺得好溫暖」',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Feature points
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Text('📝', style: TextStyle(fontSize: 24)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '記住這個瞬間',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text('😊', style: TextStyle(fontSize: 24)),
                    const SizedBox(height: AppSpacing.xs),
                    Text('懂你的心情', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                Column(
                  children: [
                    const Text('✨', style: TextStyle(fontSize: 24)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '寫成專屬你的日記',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '不用打字，不用排版，10 秒就好',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

// ============= PAGE 5: Shared Pet Feature =============
class _Page5SharedPet extends StatelessWidget {
  final AnimationController bounceAnimation;

  const _Page5SharedPet({required this.bounceAnimation});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: AppSpacing.lg),
            // Bouncing cat with sine wave animation
            AnimatedBuilder(
              animation: bounceAnimation,
              builder: (context, child) {
                final bounce =
                    math.sin(bounceAnimation.value * 2 * math.pi) * 20;
                return Transform.translate(
                  offset: Offset(0, bounce),
                  child: const Text('🐱', style: TextStyle(fontSize: 72)),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              '牠是你們的',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            // Three lines of text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                children: [
                  Text(
                    '你寫了日記，牠吃一餐 🍚',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    '對方寫了日記，牠再吃一餐',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    '兩個人都寫了，牠會開心得跳起來 🎉',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              '每一次記錄，都是對彼此的在乎',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

// ============= PAGE 6: Ready to Start =============
class _Page6Ready extends StatelessWidget {
  const _Page6Ready();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: AppSpacing.lg),
            const Text('✨', style: TextStyle(fontSize: 80)),
            const SizedBox(height: AppSpacing.xl),
            Text(
              '準備好了嗎？',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '不用完美，不用每天\n想說的時候說就好',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            // Start button is in the bottom nav
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

// ============= Reusable Option Card =============
class _OptionCard extends StatelessWidget {
  final String emoji;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.emoji,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? cs.primary : cs.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            color:
                isSelected
                    ? cs.primaryContainer.withAlpha((0.2 * 255).toInt())
                    : Colors.transparent,
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle_rounded, color: cs.primary, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
