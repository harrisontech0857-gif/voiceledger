import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import '../../core/theme.dart';
import '../../services/ai_service.dart';
import '../../services/couple_service.dart';
import '../../services/quote_service.dart';
import '../../widgets/pet_companion_widget.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyQuote = ref.watch(dailyQuoteProvider);
    final coupleAsync = ref.watch(currentCoupleProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dailyQuoteProvider);
            ref.invalidate(currentCoupleProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.md),

                  // 頂部問候
                  _TopGreetingBar(onSettingsTap: () => context.go('/settings')),
                  const SizedBox(height: AppSpacing.md),

                  // 寵物主視覺
                  const PetCompanionWidget(),
                  const SizedBox(height: AppSpacing.md),

                  // 寵物成長統計
                  coupleAsync.when(
                    data: (couple) {
                      if (couple == null || !couple.isActive) {
                        return const SizedBox.shrink();
                      }
                      return _PetGrowthStatsCard(couple: couple);
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 配對狀態 + 餵食提示
                  coupleAsync.when(
                    data: (couple) {
                      if (couple == null || !couple.isActive) {
                        return _NoPairingCard(
                          onTap: () => context.push('/pairing'),
                        );
                      }
                      return _FeedStatusCard(couple: couple);
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 每日金句
                  _DailyQuoteCard(dailyQuote: dailyQuote),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 頂部問候列
class _TopGreetingBar extends StatelessWidget {
  final VoidCallback onSettingsTap;

  const _TopGreetingBar({required this.onSettingsTap});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting =
        hour < 12
            ? '早安'
            : hour < 18
            ? '午安'
            : '晚安';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting 👋',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('M月d日 EEEE', 'zh_TW').format(DateTime.now()),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: onSettingsTap,
          child: CircleAvatar(
            radius: 22,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.person_rounded,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ],
    );
  }
}

/// 未配對提示卡
class _NoPairingCard extends StatelessWidget {
  final VoidCallback onTap;
  const _NoPairingCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withAlpha(80),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: cs.primary.withAlpha(60)),
        ),
        child: Row(
          children: [
            const Text('💕', style: TextStyle(fontSize: 32)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '邀請伴侶一起養寵物',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '配對後輪流寫日記餵食，讓寵物進化！',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: cs.primary),
          ],
        ),
      ),
    );
  }
}

/// 餵食狀態卡（已配對）
class _FeedStatusCard extends StatelessWidget {
  final CoupleInfo couple;
  const _FeedStatusCard({required this.couple});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isMyTurn =
        couple.feedTurn == Supabase.instance.client.auth.currentUser?.id;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '🐱 ${couple.petName}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Lv.${couple.petExp ~/ 100 + 1}',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: cs.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // 餵食狀態
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isMyTurn ? cs.primaryContainer : cs.tertiaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              isMyTurn ? '輪到你寫日記餵食了！🍚' : '等待對方寫日記中⋯⋯',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color:
                    isMyTurn ? cs.onPrimaryContainer : cs.onTertiaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 寵物成長統計卡
class _PetGrowthStatsCard extends StatelessWidget {
  final CoupleInfo couple;

  const _PetGrowthStatsCard({required this.couple});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final level = couple.petExp ~/ 100 + 1;
    final expInLevel = couple.petExp % 100;
    final expProgress = expInLevel / 100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '寵物成長',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text(
                'Lv.$level',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: expProgress,
                        minHeight: 8,
                        backgroundColor: cs.outlineVariant,
                        valueColor: AlwaysStoppedAnimation(cs.primary),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$expInLevel/100 EXP',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 每日金句卡片
class _DailyQuoteCard extends ConsumerStatefulWidget {
  final AsyncValue<String> dailyQuote;

  const _DailyQuoteCard({required this.dailyQuote});

  @override
  ConsumerState<_DailyQuoteCard> createState() => _DailyQuoteCardState();
}

class _DailyQuoteCardState extends ConsumerState<_DailyQuoteCard> {
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
  }

  void _checkIfSaved() async {
    final quote = widget.dailyQuote.maybeWhen(data: (q) => q, orElse: () => '');
    if (quote.isNotEmpty) {
      final quoteService = ref.read(quoteServiceProvider);
      final saved = await quoteService.isQuoteSaved(quote);
      if (mounted) setState(() => _isSaved = saved);
    }
  }

  void _toggleSaveQuote() async {
    final quote = widget.dailyQuote.maybeWhen(data: (q) => q, orElse: () => '');
    if (quote.isEmpty) return;

    final quoteService = ref.read(quoteServiceProvider);
    if (_isSaved) {
      await quoteService.removeQuote(quote);
    } else {
      await quoteService.saveQuote(quote);
    }
    setState(() => _isSaved = !_isSaved);
  }

  void _showSavedQuotes() async {
    final quoteService = ref.read(quoteServiceProvider);
    final savedQuotes = await quoteService.getSavedQuotes();

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) {
          final cs = Theme.of(context).colorScheme;
          return AlertDialog(
            title: const Text('查看收藏'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: savedQuotes.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(
                        savedQuotes[index],
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('關閉'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primary.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lightbulb_rounded,
                  color: cs.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: widget.dailyQuote.when(
                  data:
                      (quote) => Text(
                        quote.isEmpty ? '每日一句，激勵人心。' : quote,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  loading:
                      () => Container(
                        height: 16,
                        decoration: BoxDecoration(
                          color: cs.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  error:
                      (e, st) => Text(
                        '無法加載金句',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                icon: Icon(
                  _isSaved ? Icons.favorite_rounded : Icons.favorite_outline,
                  color: _isSaved ? Colors.red : cs.onSurfaceVariant,
                  size: 20,
                ),
                onPressed: _toggleSaveQuote,
                constraints: const BoxConstraints.tightFor(
                  width: 40,
                  height: 40,
                ),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: _showSavedQuotes,
            child: Text(
              '查看收藏',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
