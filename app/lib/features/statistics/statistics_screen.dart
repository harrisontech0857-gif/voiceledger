import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  int _selectedPeriodIndex = 1; // 0=周, 1=月, 2=年

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('財務統計'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 期間選擇器
            _buildSegmentedControl(),
            const SizedBox(height: AppSpacing.lg),

            // 摘要卡片
            const _SummaryRow(),
            const SizedBox(height: AppSpacing.lg),

            // 支出趨勢圖
            _SectionHeader(title: '支出趨勢'),
            const SizedBox(height: AppSpacing.md),
            const _TrendChart(),
            const SizedBox(height: AppSpacing.lg),

            // 分類支出
            _SectionHeader(title: '分類支出'),
            const SizedBox(height: AppSpacing.md),
            const _CategoryPieChart(),
            const SizedBox(height: AppSpacing.md),
            const _CategoryBreakdownList(),
            const SizedBox(height: AppSpacing.lg),

            // 最大支出
            _SectionHeader(title: '最大支出'),
            const SizedBox(height: AppSpacing.md),
            const _TopTransactions(),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedControl() {
    final labels = ['周', '月', '年'];
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = _selectedPeriodIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriodIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withAlpha(40),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  labels[i],
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: selected
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

/// 摘要列（兩行各兩張卡片）
class _SummaryRow extends StatelessWidget {
  const _SummaryRow();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: const [
            Expanded(
              child: _StatCard(
                title: '總支出',
                amount: 'NT\$ 8,450',
                subtitle: '-12% vs 上月',
                subtitleColor: Colors.green,
                icon: Icons.trending_down_rounded,
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatCard(
                title: '總收入',
                amount: 'NT\$ 25,000',
                subtitle: '+5% vs 上月',
                subtitleColor: Colors.green,
                icon: Icons.trending_up_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: const [
            Expanded(
              child: _StatCard(
                title: '淨結餘',
                amount: 'NT\$ 16,550',
                subtitle: '66% 儲蓄率',
                subtitleColor: Colors.green,
                icon: Icons.savings_rounded,
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatCard(
                title: '日均支出',
                amount: 'NT\$ 281',
                subtitle: 'vs 預算 NT\$300',
                subtitleColor: Colors.green,
                icon: Icons.calendar_today_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String amount;
  final String subtitle;
  final Color subtitleColor;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.subtitleColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withAlpha(20),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            amount,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: subtitleColor,
                ),
          ),
        ],
      ),
    );
  }
}

/// 圓餅圖
class _CategoryPieChart extends StatelessWidget {
  const _CategoryPieChart();

  @override
  Widget build(BuildContext context) {
    final categories = [
      ('餐飲', 25.0, const Color(0xFFFF9500)),
      ('交通', 21.0, const Color(0xFF2196F3)),
      ('購物', 18.0, const Color(0xFF4CAF50)),
      ('娛樂', 14.0, const Color(0xFFFFC107)),
      ('其他', 22.0, const Color(0xFFFF6B6B)),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: categories.map((c) {
                  return PieChartSectionData(
                    value: c.$2,
                    color: c.$3,
                    title: '${c.$2.toStringAsFixed(0)}%',
                    radius: 70,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 35,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: categories.map((c) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: c.$3,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${c.$1} ${c.$2.toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// 分類明細列表
class _CategoryBreakdownList extends StatelessWidget {
  const _CategoryBreakdownList();

  @override
  Widget build(BuildContext context) {
    final categories = [
      ('餐飲', 'NT\$ 2,100', 0.25, '🍜', const Color(0xFFFF9500)),
      ('交通', 'NT\$ 1,800', 0.21, '🚗', const Color(0xFF2196F3)),
      ('購物', 'NT\$ 1,550', 0.18, '🛍️', const Color(0xFF4CAF50)),
      ('娛樂', 'NT\$ 1,200', 0.14, '🎮', const Color(0xFFFFC107)),
      ('其他', 'NT\$ 1,800', 0.22, '📝', const Color(0xFFFF6B6B)),
    ];

    return Column(
      children: categories.map((c) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(
            children: [
              Text(c.$4, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          c.$1,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          c.$2,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: c.$3,
                        minHeight: 6,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .outlineVariant
                            .withAlpha(100),
                        valueColor: AlwaysStoppedAnimation<Color>(c.$5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// 支出趨勢圖（長條圖）
class _TrendChart extends StatelessWidget {
  const _TrendChart();

  @override
  Widget build(BuildContext context) {
    final days = ['一', '二', '三', '四', '五', '六', '日'];
    final amounts = [250.0, 420.0, 180.0, 350.0, 200.0, 500.0, 350.0];
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 600,
            barTouchData: BarTouchData(enabled: true),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= days.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        days[idx],
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    );
                  },
                  reservedSize: 24,
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(days.length, (i) {
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: amounts[i],
                    color: cs.primary,
                    width: 20,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// 最大支出列表
class _TopTransactions extends StatelessWidget {
  const _TopTransactions();

  @override
  Widget build(BuildContext context) {
    final transactions = [
      ('超市購物', 'NT\$ 850', '03/15', '🛍️'),
      ('餐廳聚餐', 'NT\$ 620', '03/14', '🍽️'),
      ('計程車費用', 'NT\$ 450', '03/13', '🚕'),
    ];

    return Column(
      children: transactions.map((tx) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withAlpha(20),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Center(
                    child: Text(
                      tx.$4,
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
                        tx.$1,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        tx.$3,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Text(
                  tx.$2,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
