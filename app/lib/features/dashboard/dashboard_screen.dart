import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import '../../core/theme.dart';
import '../../services/ai_service.dart';
import '../../services/couple_service.dart';
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

/// 寵物數據字卡列 — 三張字卡橫排（暫時保留相容性）
class _StatsCardRow extends StatelessWidget {
  final dynamic pet;

  const _StatsCardRow({required this.pet});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.star_rounded,
            iconColor: Colors.amber,
            label: '等級',
            value: 'Lv.${pet.level}',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department_rounded,
            iconColor: Colors.deepOrange,
            label: '連續',
            value: '${pet.streak} 天',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCard(
            icon: Icons.receipt_long_rounded,
            iconColor: Colors.teal,
            label: '記錄',
            value: '${pet.totalEntries} 筆',
          ),
        ),
      ],
    );
  }
}

/// 單一數據字卡
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outlineVariant.withAlpha(60)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// 功能入口字卡列 — 語音日記 + 問秘書
class _ActionCardRow extends StatelessWidget {
  final VoidCallback onVoiceTap;
  final VoidCallback onChatTap;

  const _ActionCardRow({required this.onVoiceTap, required this.onChatTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.mic_rounded,
            label: '語音日記',
            subtitle: '說一句就記好',
            onTap: onVoiceTap,
            isPrimary: true,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ActionCard(
            icon: Icons.chat_rounded,
            label: '問秘書',
            subtitle: 'AI 財務分析',
            onTap: onChatTap,
            isPrimary: false,
          ),
        ),
      ],
    );
  }
}

/// 單一功能字卡按鈕
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isPrimary ? cs.primaryContainer : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border:
              isPrimary
                  ? null
                  : Border.all(color: cs.outlineVariant.withAlpha(60)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    isPrimary
                        ? cs.primary.withAlpha(30)
                        : cs.tertiary.withAlpha(25),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                icon,
                color: isPrimary ? cs.primary : cs.tertiary,
                size: 24,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isPrimary ? cs.onPrimaryContainer : cs.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color:
                    isPrimary
                        ? cs.onPrimaryContainer.withAlpha(180)
                        : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 每日金句卡片
class _DailyQuoteCard extends StatelessWidget {
  final AsyncValue<String> dailyQuote;

  const _DailyQuoteCard({required this.dailyQuote});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lightbulb_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: dailyQuote.when(
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
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              error:
                  (e, st) => Text(
                    '無法加載金句',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
