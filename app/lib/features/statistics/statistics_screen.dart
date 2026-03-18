import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('財務統計'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Selector
            _PeriodSelector(),
            const SizedBox(height: AppTheme.spacingLarge),

            // Summary Cards
            _SummaryCards(),
            const SizedBox(height: AppTheme.spacingLarge),

            // Spending by Category
            Text('分類支出', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppTheme.spacingMedium),
            _CategoryBreakdown(),
            const SizedBox(height: AppTheme.spacingLarge),

            // Trend Chart
            Text('支出趨勢', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppTheme.spacingMedium),
            _TrendChart(),
            const SizedBox(height: AppTheme.spacingLarge),

            // Top Transactions
            Text('最大支出', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppTheme.spacingMedium),
            _TopTransactions(),
          ],
        ),
      ),
    );
  }
}

class _PeriodSelector extends StatefulWidget {
  const _PeriodSelector();

  @override
  State<_PeriodSelector> createState() => _PeriodSelectorState();
}

class _PeriodSelectorState extends State<_PeriodSelector> {
  String _selectedPeriod = '月';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      padding: const EdgeInsets.all(AppTheme.spacingSmall),
      child: Row(
        children: [
          _PeriodButton(
            label: '周',
            isSelected: _selectedPeriod == '周',
            onTap: () => setState(() => _selectedPeriod = '周'),
          ),
          _PeriodButton(
            label: '月',
            isSelected: _selectedPeriod == '月',
            onTap: () => setState(() => _selectedPeriod = '月'),
          ),
          _PeriodButton(
            label: '年',
            isSelected: _selectedPeriod == '年',
            onTap: () => setState(() => _selectedPeriod = '年'),
          ),
        ],
      ),
    );
  }
}

class _PeriodButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color:
                isSelected ? AppTheme.primaryGradientStart : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSmall),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isSelected ? Colors.white : null,
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatSummaryCard(
                title: '總支出',
                amount: 'NT\$ 8,450',
                change: '-12% vs 上月',
                isPositive: true,
                icon: Icons.trending_down_rounded,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSmall),
            Expanded(
              child: _StatSummaryCard(
                title: '總收入',
                amount: 'NT\$ 25,000',
                change: '+5% vs 上月',
                isPositive: true,
                icon: Icons.trending_up_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSmall),
        Row(
          children: [
            Expanded(
              child: _StatSummaryCard(
                title: '淨結餘',
                amount: 'NT\$ 16,550',
                change: '66% 儲蓄率',
                isPositive: true,
                icon: Icons.savings_rounded,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSmall),
            Expanded(
              child: _StatSummaryCard(
                title: '平均日支出',
                amount: 'NT\$ 281',
                change: 'vs 預算 NT\$300',
                isPositive: true,
                icon: Icons.calendar_today_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatSummaryCard extends StatelessWidget {
  final String title;
  final String amount;
  final String change;
  final bool isPositive;
  final IconData icon;

  const _StatSummaryCard({
    required this.title,
    required this.amount,
    required this.change,
    required this.isPositive,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelSmall),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGradientStart.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  padding: const EdgeInsets.all(AppTheme.spacingSmall),
                  child: Icon(
                    icon,
                    color: AppTheme.primaryGradientStart,
                    size: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              amount,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              change,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isPositive ? AppTheme.successGreen : Colors.red,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown();

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'name': '餐飲', 'amount': 'NT\$ 2,100', 'percentage': 25.0, 'icon': '🍜'},
      {'name': '交通', 'amount': 'NT\$ 1,800', 'percentage': 21.0, 'icon': '🚗'},
      {'name': '購物', 'amount': 'NT\$ 1,550', 'percentage': 18.0, 'icon': '🛍️'},
      {'name': '娛樂', 'amount': 'NT\$ 1,200', 'percentage': 14.0, 'icon': '🎮'},
      {'name': '其他', 'amount': 'NT\$ 1,800', 'percentage': 22.0, 'icon': '📝'},
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppTheme.spacingSmall),
      itemBuilder: (context, index) {
        final cat = categories[index];
        final percentage = cat['percentage'] as double;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      cat['icon'] as String,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: AppTheme.spacingSmall),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat['name'] as String,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          cat['amount'] as String,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 8,
                backgroundColor: Colors.grey.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getCategoryColor(index),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getCategoryColor(int index) {
    final colors = [
      Color(0xFFFF9500),
      Color(0xFF2196F3),
      Color(0xFF4CAF50),
      Color(0xFFFFC107),
      Color(0xFFFF6B6B),
    ];
    return colors[index % colors.length];
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart();

  @override
  Widget build(BuildContext context) {
    final days = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final amounts = [250, 420, 180, 350, 200, 500, 350];
    final maxAmount = amounts.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(days.length, (index) {
                  final amount = amounts[index];
                  final height = (amount / maxAmount) * 150;

                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'NT\$${amount}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: AppTheme.spacingSmall),
                        Container(
                          width: double.infinity,
                          height: height,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(AppTheme.radiusSmall),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingSmall),
                        Text(
                          days[index],
                          style: Theme.of(context).textTheme.labelSmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopTransactions extends StatelessWidget {
  const _TopTransactions();

  @override
  Widget build(BuildContext context) {
    final transactions = [
      {
        'name': '超市購物',
        'amount': 'NT\$ 850',
        'date': '2024-03-15',
        'icon': '🛍️',
      },
      {
        'name': '餐廳聚餐',
        'amount': 'NT\$ 620',
        'date': '2024-03-14',
        'icon': '🍽️',
      },
      {
        'name': '計程車費用',
        'amount': 'NT\$ 450',
        'date': '2024-03-13',
        'icon': '🚕',
      },
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppTheme.spacingSmall),
      itemBuilder: (context, index) {
        final tx = transactions[index];

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGradientStart.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Center(
                  child: Text(
                    tx['icon'] as String,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx['name'] as String,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      tx['date'] as String,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              Text(
                tx['amount'] as String,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}
