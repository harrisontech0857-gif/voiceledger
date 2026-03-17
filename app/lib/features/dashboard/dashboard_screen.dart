import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/app_router.dart';
import '../../services/ai_service.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyQuote = ref.watch(dailyQuoteProvider);
    final isDarkMode = ref.watch(isDarkModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('語記'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppTheme.spacingMedium),
            child: GestureDetector(
              onTap: () => GoRouter.of(context).go(Routes.settings),
              child: CircleAvatar(
                backgroundColor: AppTheme.primaryGradientStart.withOpacity(0.2),
                child: const Icon(Icons.person_rounded),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(dailyQuoteProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Daily Quote Card
                _DailyQuoteCard(dailyQuote: dailyQuote),
                const SizedBox(height: AppTheme.spacingLarge),

                // Today's Summary
                _TodaysSummaryCard(),
                const SizedBox(height: AppTheme.spacingLarge),

                // Quick Actions
                _QuickActionsSection(),
                const SizedBox(height: AppTheme.spacingLarge),

                // Recent Transactions
                _RecentTransactionsSection(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => GoRouter.of(context).go(Routes.voiceEntry),
        icon: const Icon(Icons.mic_rounded),
        label: const Text('快速記帳'),
      ),
    );
  }
}

class _DailyQuoteCard extends StatelessWidget {
  final AsyncValue<String> dailyQuote;

  const _DailyQuoteCard({required this.dailyQuote});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [AppTheme.mediumShadow],
      ),
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_rounded, color: Colors.white),
              const SizedBox(width: AppTheme.spacingSmall),
              Text(
                '今日金句',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          dailyQuote.when(
            data: (quote) => Text(
              quote.isEmpty ? '每日一句，激勵人心。' : quote,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontStyle: FontStyle.italic,
                  ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            loading: () => Shimmer.fromColors(
              baseColor: Colors.white.withOpacity(0.3),
              highlightColor: Colors.white.withOpacity(0.5),
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
              ),
            ),
            error: (e, st) => Text(
              '無法加載金句',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodaysSummaryCard extends ConsumerWidget {
  const _TodaysSummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final dateFormat = DateFormat('MMM dd, yyyy', 'zh_TW');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '今日花費',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppTheme.spacingSmall),
                    Text(
                      'NT\$ 1,250',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: AppTheme.primaryGradientStart,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  padding: const EdgeInsets.all(AppTheme.spacingMedium),
                  child: const Icon(
                    Icons.trending_down_rounded,
                    color: AppTheme.successGreen,
                    size: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                widthFactor: 0.45, // 45% of daily budget used
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '已用 45% 預算',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                Text(
                  dateFormat.format(now),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '快速操作',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.mic_rounded,
                label: '語音記帳',
                color: AppTheme.primaryGradientStart,
                onTap: () => GoRouter.of(context).go(Routes.voiceEntry),
              ),
            ),
            const SizedBox(width: AppTheme.spacingSmall),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.camera_alt_rounded,
                label: '拍照記帳',
                color: Color(0xFF4CAF50),
                onTap: () {
                  // Implement photo capture
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSmall),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.chat_rounded,
                label: '詢問秘書',
                color: Color(0xFF2196F3),
                onTap: () => GoRouter.of(context).go(Routes.aiSecretary),
              ),
            ),
            const SizedBox(width: AppTheme.spacingSmall),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.trending_up_rounded,
                label: '查看統計',
                color: Color(0xFFFFC107),
                onTap: () => GoRouter.of(context).go(Routes.statistics),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingSmall,
          vertical: AppTheme.spacingMedium,
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentTransactionsSection extends StatelessWidget {
  const _RecentTransactionsSection();

  @override
  Widget build(BuildContext context) {
    // Mock data
    final transactions = [
      {
        'category': '餐飲',
        'icon': '🍜',
        'description': '中午便當',
        'amount': '-NT\$ 85',
        'time': '12:30',
      },
      {
        'category': '交通',
        'icon': '🚗',
        'description': '計程車',
        'amount': '-NT\$ 250',
        'time': '10:45',
      },
      {
        'category': '購物',
        'icon': '🛍️',
        'description': '便利店購物',
        'amount': '-NT\$ 125',
        'time': '08:20',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '最近交易',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            GestureDetector(
              onTap: () => GoRouter.of(context).go(Routes.statistics),
              child: Text(
                '查看全部',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.primaryGradientStart,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spacingSmall),
          itemBuilder: (context, index) {
            final tx = transactions[index];
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              padding: const EdgeInsets.all(AppTheme.spacingSmall),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Center(
                      child: Text(
                        tx['icon'] as String,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSmall),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx['description'] as String,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          tx['category'] as String,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        tx['amount'] as String,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        tx['time'] as String,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

// Shimmer widget for loading states
class Shimmer extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration period;

  const Shimmer({
    Key? key,
    required this.child,
    required this.baseColor,
    required this.highlightColor,
    this.period = const Duration(milliseconds: 1500),
  }) : super(key: key);

  static ShimmerState? of(BuildContext context) {
    return context.findAncestorStateOfType<ShimmerState>();
  }

  factory Shimmer.fromColors({
    Key? key,
    required Widget child,
    required Color baseColor,
    required Color highlightColor,
    Duration period = const Duration(milliseconds: 1500),
  }) {
    return Shimmer(
      key: key,
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: period,
      child: child,
    );
  }

  @override
  State<Shimmer> createState() => ShimmerState();
}

class ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController.unbounded(vsync: this)
      ..repeat(min: -0.5, max: 1.5, period: widget.period);
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0, -0.3),
              end: Alignment(1.0, 0.3),
              stops: const [0.0, 0.5, 1.0],
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              tileMode: TileMode.clamp,
            ).createShader(
              Rect.fromLTWH(
                0,
                0,
                bounds.width,
                bounds.height,
              ).shift(
                Offset(
                  _shimmerController.value * bounds.width * 2,
                  0,
                ),
              ),
            );
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
