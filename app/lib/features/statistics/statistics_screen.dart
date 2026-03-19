import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/transaction.dart';
import '../../services/transaction_service.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  int _selectedPeriodIndex = 1; // 0=周, 1=月, 2=年
  List<Transaction> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final service = ref.read(transactionServiceProvider);
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(now.year, now.month + 1, 0);

    final transactions = await service.getTransactions(
      startDate: startDate,
      endDate: endDate,
    );

    if (mounted) {
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('財務統計'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 期間選擇器
                  _buildSegmentedControl(),
                  const SizedBox(height: AppSpacing.lg),

                  // 摘要卡片
                  _SummaryRow(transactions: _transactions),
                  const SizedBox(height: AppSpacing.lg),

                  // 支出趨勢圖
                  _SectionHeader(title: '支出趨勢'),
                  const SizedBox(height: AppSpacing.md),
                  _TrendChart(transactions: _transactions),
                  const SizedBox(height: AppSpacing.lg),

                  // 分類支出
                  _SectionHeader(title: '分類支出'),
                  const SizedBox(height: AppSpacing.md),
                  _CategoryPieChart(transactions: _transactions),
                  const SizedBox(height: AppSpacing.md),
                  _CategoryBreakdownList(transactions: _transactions),
                  const SizedBox(height: AppSpacing.lg),

                  // 最大支出
                  _SectionHeader(title: '最大支出'),
                  const SizedBox(height: AppSpacing.md),
                  _TopTransactions(transactions: _transactions),
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
  final List<Transaction> transactions;

  const _SummaryRow({required this.transactions});

  @override
  Widget build(BuildContext context) {
    double totalExpense = 0;
    double totalIncome = 0;
    for (final tx in transactions) {
      if (tx.type == TransactionType.expense) {
        totalExpense += tx.amount;
      } else {
        totalIncome += tx.amount;
      }
    }

    final balance = totalIncome - totalExpense;
    final savingsRate = totalIncome > 0
        ? (balance / totalIncome * 100).toStringAsFixed(0)
        : '0';
    final dayCount = DateTime.now().day;
    final dailyAverage = totalExpense / dayCount;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: '總支出',
                amount:
                    'NT\$ ${NumberFormat('#,###').format(totalExpense.toInt())}',
                subtitle: '-12% vs 上月',
                subtitleColor: Colors.green,
                icon: Icons.trending_down_rounded,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatCard(
                title: '總收入',
                amount:
                    'NT\$ ${NumberFormat('#,###').format(totalIncome.toInt())}',
                subtitle: '+5% vs 上月',
                subtitleColor: Colors.green,
                icon: Icons.trending_up_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: '淨結餘',
                amount: 'NT\$ ${NumberFormat('#,###').format(balance.toInt())}',
                subtitle: '$savingsRate% 儲蓄率',
                subtitleColor: Colors.green,
                icon: Icons.savings_rounded,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatCard(
                title: '日均支出',
                amount:
                    'NT\$ ${NumberFormat('#,###').format(dailyAverage.toInt())}',
                subtitle: 'vs 預算 NT\$300',
                subtitleColor: dailyAverage <= 300 ? Colors.green : Colors.red,
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
                  color: Theme.of(context).colorScheme.primary.withAlpha(20),
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
  final List<Transaction> transactions;

  const _CategoryPieChart({required this.transactions});

  @override
  Widget build(BuildContext context) {
    // 計算分類支出
    final categorySummary = <String, double>{};
    double totalExpense = 0;

    for (final tx in transactions) {
      if (tx.type == TransactionType.expense) {
        final key = tx.category.displayName;
        categorySummary[key] = (categorySummary[key] ?? 0) + tx.amount;
        totalExpense += tx.amount;
      }
    }

    // 顏色對應
    final colorMap = <String, Color>{
      '餐飲': const Color(0xFFFF9500),
      '交通': const Color(0xFF2196F3),
      '購物': const Color(0xFF4CAF50),
      '娛樂': const Color(0xFFFFC107),
      '日用': const Color(0xFF9C27B0),
      '健康': const Color(0xFFE91E63),
      '教育': const Color(0xFF00BCD4),
      '投資': const Color(0xFF8BC34A),
      '其他': const Color(0xFFFF6B6B),
    };

    final categories = categorySummary.entries.map((e) {
      final percentage =
          totalExpense > 0 ? (e.value / totalExpense * 100).toDouble() : 0.0;
      return (
        e.key,
        percentage,
        colorMap[e.key] ?? const Color(0xFFFF6B6B),
      );
    }).toList();

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
            child: categories.isEmpty
                ? Center(
                    child: Text(
                      '無分類資料',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : PieChart(
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
  final List<Transaction> transactions;

  const _CategoryBreakdownList({required this.transactions});

  @override
  Widget build(BuildContext context) {
    // 計算分類支出
    final categorySummary = <String, double>{};
    double totalExpense = 0;

    for (final tx in transactions) {
      if (tx.type == TransactionType.expense) {
        final key = tx.category.displayName;
        categorySummary[key] = (categorySummary[key] ?? 0) + tx.amount;
        totalExpense += tx.amount;
      }
    }

    // 顏色和圖標對應
    final colorMap = <String, Color>{
      '餐飲': const Color(0xFFFF9500),
      '交通': const Color(0xFF2196F3),
      '購物': const Color(0xFF4CAF50),
      '娛樂': const Color(0xFFFFC107),
      '日用': const Color(0xFF9C27B0),
      '健康': const Color(0xFFE91E63),
      '教育': const Color(0xFF00BCD4),
      '投資': const Color(0xFF8BC34A),
      '其他': const Color(0xFFFF6B6B),
    };

    // 按金額排序
    final sortedCategories = categorySummary.entries
        .map((e) => (e.key, e.value))
        .toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));

    return Column(
      children: sortedCategories.map((c) {
        final percentage =
            totalExpense > 0 ? (c.$2 / totalExpense).toDouble() : 0.0;
        final category = TransactionCategory.values.firstWhere(
          (cat) => cat.displayName == c.$1,
          orElse: () => TransactionCategory.other,
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(
            children: [
              Text(category.icon, style: const TextStyle(fontSize: 22)),
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
                          'NT\$ ${NumberFormat('#,###').format(c.$2.toInt())}',
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
                        value: percentage,
                        minHeight: 6,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .outlineVariant
                            .withAlpha(100),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorMap[c.$1] ?? const Color(0xFFFF6B6B),
                        ),
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
  final List<Transaction> transactions;

  const _TrendChart({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 計算最近 7 天的每日支出
    final dailyExpense = <double>[];
    double maxAmount = 0;

    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      double dayTotal = 0;

      for (final tx in transactions) {
        if (tx.type == TransactionType.expense &&
            tx.createdAt.year == date.year &&
            tx.createdAt.month == date.month &&
            tx.createdAt.day == date.day) {
          dayTotal += tx.amount;
        }
      }

      dailyExpense.add(dayTotal);
      if (dayTotal > maxAmount) maxAmount = dayTotal;
    }

    final days = ['一', '二', '三', '四', '五', '六', '日'];
    final chartMaxY = (maxAmount * 1.2).ceilToDouble();

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
            maxY: chartMaxY > 0 ? chartMaxY : 100,
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
            barGroups: List.generate(dailyExpense.length, (i) {
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: dailyExpense[i],
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
  final List<Transaction> transactions;

  const _TopTransactions({required this.transactions});

  @override
  Widget build(BuildContext context) {
    // 排序取前 3 筆最大支出
    final topExpenses = transactions
        .where((tx) => tx.type == TransactionType.expense)
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final topThree = topExpenses.take(3).toList();

    if (topThree.isEmpty) {
      return Center(
        child: Text(
          '無支出記錄',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return Column(
      children: topThree.map((tx) {
        final dateStr = DateFormat('MM/dd').format(tx.createdAt);

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
                    color: Theme.of(context).colorScheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Center(
                    child: Text(
                      tx.category.icon,
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
                        tx.description,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        dateStr,
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
                  'NT\$ ${NumberFormat('#,###').format(tx.amount.toInt())}',
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
