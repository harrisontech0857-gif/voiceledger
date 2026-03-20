import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart' show kMockMode;
import '../../core/theme.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  // Step 1: Nickname
  late TextEditingController _nicknameController;
  String _initialName = '';

  // Step 2: Pet Personality
  String? _selectedPersonality;

  // Step 3: Pet Name
  late TextEditingController _petNameController;

  final List<Map<String, String>> _personalities = [
    {
      'key': 'energetic',
      'emoji': '🐱',
      'label': '活潑好動',
      'description': '喜歡跳來跳去，常常催你寫日記',
    },
    {
      'key': 'gentle',
      'emoji': '😺',
      'label': '溫柔體貼',
      'description': '輕聲細語，會在你累的時候安慰你',
    },
    {
      'key': 'funny',
      'emoji': '😸',
      'label': '搞笑幽默',
      'description': '總是說些好笑的話逗你開心',
    },
    {
      'key': 'clingy',
      'emoji': '😻',
      'label': '黏人撒嬌',
      'description': '超級黏你，一天不寫日記就會哭哭',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Get initial name from Google auth metadata
    final user = !kMockMode ? Supabase.instance.client.auth.currentUser : null;
    _initialName =
        user?.userMetadata?['full_name'] as String? ??
        user?.userMetadata?['name'] as String? ??
        '';

    _nicknameController = TextEditingController(text: _initialName);
    _petNameController = TextEditingController(text: '小財');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nicknameController.dispose();
    _petNameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeSetup();
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

  bool _canProceed() {
    if (_currentPage == 0) {
      // Step 1: Need nickname
      return _nicknameController.text.isNotEmpty;
    } else if (_currentPage == 1) {
      // Step 2: Need personality selected
      return _selectedPersonality != null;
    } else {
      // Step 3: Need pet name
      return _petNameController.text.isNotEmpty;
    }
  }

  Future<void> _completeSetup() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save to Supabase user_profiles if not in mock mode
      if (!kMockMode) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          // Update user metadata with display_name
          await Supabase.instance.client.auth.updateUser(
            UserAttributes(
              data: {'display_name': _nicknameController.text.trim()},
            ),
          );
        }
      }

      // Save pet settings to SharedPreferences
      await prefs.setString('pet_personality', _selectedPersonality!);
      await prefs.setString('pet_custom_name', _petNameController.text.trim());
      await prefs.setBool('setup_complete', true);

      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('設定失敗: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (page) {
          setState(() => _currentPage = page);
        },
        children: [
          // Step 1: Set Nickname
          _buildStep1(cs),

          // Step 2: Choose Pet Personality
          _buildStep2(cs),

          // Step 3: Give Pet a Name
          _buildStep3(cs),
        ],
      ),
    );
  }

  Widget _buildStep1(ColorScheme cs) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Progress indicator
            _buildProgressBar(0),

            // Content
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '你想怎麼被稱呼？',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    '你的伴侶會看到這個名字',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _nicknameController,
                    maxLength: 20,
                    onChanged: (value) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: '暱稱',
                      hintText: '輸入你的暱稱',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      counterText: '${_nicknameController.text.length}/20',
                    ),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),

            // Navigation buttons
            _buildNavigationButtons(cs),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2(ColorScheme cs) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Progress indicator
            _buildProgressBar(1),

            // Content
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '選擇寵物的個性',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      children:
                          _personalities.map((p) {
                            final isSelected = _selectedPersonality == p['key'];
                            return _buildPersonalityCard(
                              emoji: p['emoji']!,
                              label: p['label']!,
                              description: p['description']!,
                              isSelected: isSelected,
                              onTap: () {
                                setState(() => _selectedPersonality = p['key']);
                              },
                              cs: cs,
                            );
                          }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Navigation buttons
            _buildNavigationButtons(cs),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3(ColorScheme cs) {
    final personalityData = _personalities.firstWhere(
      (p) => p['key'] == _selectedPersonality,
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Progress indicator
            _buildProgressBar(2),

            // Content
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '幫寵物取個名字吧',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Pet emoji and personality
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: Column(
                      children: [
                        Text(
                          personalityData['emoji']!,
                          style: const TextStyle(fontSize: 64),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          personalityData['label']!,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _petNameController,
                    maxLength: 8,
                    onChanged: (value) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: '寵物名字',
                      hintText: '輸入寵物名字',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      counterText: '${_petNameController.text.length}/8',
                    ),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),

            // Navigation buttons (with "開始使用" on final step)
            _buildFinalNavigationButtons(cs),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(int step) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: LinearProgressIndicator(
            value: (step + 1) / 3,
            minHeight: 6,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          '步驟 ${step + 1}/3',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalityCard({
    required String emoji,
    required String label,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme cs,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? cs.primaryContainer : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? cs.onPrimaryContainer : cs.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Expanded(
                child: Text(
                  description,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color:
                        isSelected
                            ? cs.onPrimaryContainer.withAlpha(200)
                            : cs.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(ColorScheme cs) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _canProceed() ? _nextPage : null,
            child: const Text('下一步'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _currentPage > 0 ? _previousPage : null,
            child: const Text('上一步'),
          ),
        ),
      ],
    );
  }

  Widget _buildFinalNavigationButtons(ColorScheme cs) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _canProceed() ? _completeSetup : null,
            child: const Text('開始使用'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _previousPage,
            child: const Text('上一步'),
          ),
        ),
      ],
    );
  }
}
