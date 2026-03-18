import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../services/ai_service.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyQuote = ref.watch(dailyQuoteProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dailyQuoteProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 頂部問候區域
                _TopGreetingBar(onSettingsTap: () => context.go('/settings')),
                const SizedBox(height: AppSpacing.sm),

                // Hero 財務摘要卡片
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: _HeroSummaryCard(),
                ),
                const SizedBox(height: AppSpacing.lg),

                // 每日金句
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: _DailyQuoteCard(dailyQuote: dailyQuote),
                ),
                const SizedBox(height: AppSpacing.lg),

                // 快速操作（水平捲動）
                const _QuickActionsRow(),
                const SizedBox(height: AppSpacing.lg),

                // 最近交易
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: _RecentTransactionsSection(),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
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
    final greeting = hour < 12
        ? '早安'
        : hour < 18
            ? '午安'
            : '晚安';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting 👋',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                '今天的財務狀況如何？',
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
              backgroundColor:
                  Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.person_rounded,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hero 財務摘要卡片 — 收入/支出/結餘合一
class _HeroSummaryCard extends StatelessWidget {
  const _HeroSummaryCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final monthLabel = DateFormat('yyyy 年 M 月', 'zh_TW').format(now);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primary, cs.tertiary],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                monthLabel,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white.withAlpha(200),
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '已用 45%',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'NT\$ 16,550',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '本月結餘',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withAlpha(180),
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // 預算進度條
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.45,
              minHeight: 6,
              backgroundColor: Colors.white.withAlpha(50),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // 收入 / 支出 Row
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  icon: Icons.arrow_downward_rounded,
                  label: '收入',
                  amount: 'NT\$ 25,000',
                  iconBgColor: Colors.white.withAlpha(40),
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: Colors.white.withAlpha(50),
              ),
              Expanded(
                child: _MiniStat(
                  icon: Icons.arrow_upward_rounded,
                  label: '支出',
                  amount: 'NT\$ 8,450',
                  iconBgColor: Colors.white.withAlpha(40),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String amount;
  final Color iconBgColor;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.amount,
    required this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconBgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white.withAlpha(180),
                  ),
            ),
            Text(
              amount,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 每日金句卡片（精簡版）
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
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withAlpha(25),
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
              data: (quote) => Text(
                quote.isEmpty ? '每日一句，激勵人心。' : quote,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              loading: () => Container(
                height: 16,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              error: (e, st) => Text(
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

/// 水平捲動快速操作
class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QA(Icons.mic_rounded, '語音記帳', '/voice-entry', Theme.of(context).colorScheme.primary),
      _QA(Icons.add_rounded, '手動記帳', '/add-transaction', Theme.of(context).colorScheme.secondary),
      _QA(Icons.chat_rounded, '詢問秘書', '/ai-secretary', Theme.of(context).colorScheme.tertiary),
      _QA(Icons.bar_chart_rounded, '查看統計', '/statistics', Theme.of(context).colorScheme.error),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            '快速操作',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: actions.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final a = actions[index];
              return GestureDetector(
                onTap: () {
                  if (a.route.startsWith('/statistics')) {
                    context.go(a.route);
                  } else {
                    context.push(a.route);
                  }
                },
                child: SizedBox(
                  width: 80,
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: a.color.withAlpha(25),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(
                            color: a.color.withAlpha(60),
                          ),
                        ),
                        child: Icon(a.icon, color: a.color, size: 28),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        a.label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _QA {
  final IconData icon;
  final String label;
  final String route;
  final Color color;
  const _QA(this.icon, this.label, this.route, this.color);
}

/// 最近交易區段
class _RecentTransactionsSection extends StatelessWidget {
  _RecentTransactionsSection();

  final transactions = const [
    {'category': '餐飲', 'icon': '🍜', 'description': '中午便當', 'amount': '-NT\$ 85', 'time': '12:30'},
    {'category': '交通', 'icon': '🚗', 'description': '計程車', 'amount': '-NT\$ 250', 'time': '10:45'},
    {'category': '購物', 'icon': '🛍️', 'description': '便利店購物', 'amount': '-NT\$ 125', 'time': '08:20'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '最近交易',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            GestureDetector(
              onTap: () => context.go('/transactions'),
              child: Text(
                '查看全部 →',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ...transactions.map((tx) => _TransactionTile(tx: tx)),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Map<String, String> tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Center(
                child: Text(
                  tx['icon'] ?? '',
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx['description'] ?? '',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${tx['category']} · ${tx['time']}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Text(
              tx['amount'] ?? '',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
