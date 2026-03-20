import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _requestPermissions();
    }
  }

  void _skipToHome() {
    context.go('/dashboard');
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();

    if (mounted) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Page View
          PageView(
            controller: _pageController,
            onPageChanged: (page) {
              setState(() => _currentPage = page);
            },
            children: [
              _OnboardingPage(
                icon: Icons.mic_rounded,
                title: '語音日記',
                description: '用自然的語言說說你的一天，AI 幫你分析情緒、標記主題、生成日記',
                color: Theme.of(context).colorScheme.primary,
              ),
              _OnboardingPage(
                icon: Icons.smart_toy_rounded,
                title: 'AI 秘書',
                description: '隨時和 AI 秘書聊天，獲得個人化的生活洞察和溫暖鼓勵',
                color: Theme.of(context).colorScheme.secondary,
              ),
              _OnboardingPage(
                icon: Icons.pets_rounded,
                title: '寵物養成',
                description: '每天寫日記就能餵養你的招財貓，看牠一步步進化！',
                color: Theme.of(context).colorScheme.tertiary,
              ),
              _OnboardingPage(
                icon: Icons.favorite_rounded,
                title: '情侶配對',
                description: '和伴侶配對後，互相看日記、一起養寵物，讓每天更有溫度',
                color: Theme.of(context).colorScheme.error,
              ),
            ],
          ),

          // Bottom Navigation
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    // Page Indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (index) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                _currentPage == index
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.withAlpha(
                                      (255 * 0.3).round(),
                                    ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Buttons
                    Row(
                      children: [
                        if (_currentPage > 0)
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.arrow_back_rounded),
                              label: const Text('上一步'),
                              onPressed: () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),
                          )
                        else
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _skipToHome,
                              child: const Text('跳過'),
                            ),
                          ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(
                              _currentPage == 4
                                  ? Icons.check_rounded
                                  : Icons.arrow_forward_rounded,
                            ),
                            label: Text(_currentPage == 4 ? '開始使用' : '下一步'),
                            onPressed: _nextPage,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Skip Button (Top Right)
          if (_currentPage < 4)
            Positioned(
              top: MediaQuery.of(context).padding.top + AppSpacing.md,
              right: AppSpacing.md,
              child: TextButton(
                onPressed: _skipToHome,
                child: Text(
                  '跳過',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: color.withAlpha((255 * 0.1).round()),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 60),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
