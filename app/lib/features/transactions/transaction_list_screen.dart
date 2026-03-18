import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/transaction.dart';
import '../../services/transaction_service.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  TransactionType? _selectedType;
  TransactionCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(
      userTransactionsProvider((
        userId: 'current_user_id',
        startDate: null,
        endDate: null,
      )),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('交易列表'), centerTitle: true),
      body: Column(
        children: [
          // 篩選選項
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('篩選', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<TransactionType?>(
                        segments: const [
                          ButtonSegment(value: null, label: Text('全部')),
                          ButtonSegment(
                            value: TransactionType.expense,
                            label: Text('支出'),
                          ),
                          ButtonSegment(
                            value: TransactionType.income,
                            label: Text('收入'),
                          ),
                        ],
                        selected: {_selectedType},
                        onSelectionChanged: (selected) {
                          setState(() => _selectedType = selected.first);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 交易列表
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                // 篩選交易
                var filtered = transactions;

                if (_selectedType != null) {
                  filtered =
                      filtered.where((tx) => tx.type == _selectedType).toList();
                }

                if (_selectedCategory != null) {
                  filtered = filtered
                      .where((tx) => tx.category == _selectedCategory)
                      .toList();
                }

                // 按日期分組
                final grouped = <DateTime, List<Transaction>>{};
                for (final tx in filtered) {
                  final date = DateTime(
                    tx.createdAt.year,
                    tx.createdAt.month,
                    tx.createdAt.day,
                  );
                  grouped.putIfAbsent(date, () => []).add(tx);
                }

                final sortedDates = grouped.keys.toList()
                  ..sort((a, b) => b.compareTo(a));

                if (sortedDates.isEmpty) {
                  return Center(
                    child: Text(
                      '沒有交易',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: sortedDates.length,
                  itemBuilder: (context, index) {
                    final date = sortedDates[index];
                    final dayTransactions = grouped[date]!;
                    final dateFormat = DateFormat('MMM dd, yyyy', 'zh_TW');

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          child: Text(
                            dateFormat.format(date),
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                        ...dayTransactions.map(
                          (tx) => _TransactionTile(transaction: tx),
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(child: Text('載入失敗: $error')),
            ),
          ),
        ],
      ),
    );
  }
}

/// 單個交易卡片
class _TransactionTile extends ConsumerWidget {
  final Transaction transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeFormat = DateFormat('HH:mm', 'zh_TW');
    final isIncome = transaction.type == TransactionType.income;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Card(
        child: ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Center(
              child: Text(
                transaction.category.icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          title: Text(transaction.description),
          subtitle: Text(transaction.category.displayName),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}NT\$ ${transaction.amount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: isIncome
                          ? Theme.of(context).colorScheme.tertiaryContainer
                          : Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                timeFormat.format(transaction.createdAt),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
          onTap: () {
            _showTransactionDetails(context, transaction);
          },
        ),
      ),
    );
  }

  void _showTransactionDetails(BuildContext context, Transaction transaction) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('交易詳情', style: Theme.of(context).textTheme.headlineSmall),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // 詳情
            _DetailRow(
              label: '金額',
              value: 'NT\$ ${transaction.amount.toStringAsFixed(2)}',
            ),
            _DetailRow(label: '類別', value: transaction.category.displayName),
            _DetailRow(label: '描述', value: transaction.description),
            if (transaction.notes != null)
              _DetailRow(label: '備註', value: transaction.notes!),
            if (transaction.voiceTranscript != null)
              _DetailRow(label: '語音', value: transaction.voiceTranscript!),
            const SizedBox(height: AppSpacing.lg),

            // 刪除按鈕
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteTransaction(context, transaction);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('刪除交易'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteTransaction(BuildContext context, Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認刪除'),
        content: const Text('確定要刪除此交易嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final txService = ref.read(transactionServiceProvider);
              await txService.deleteTransaction(transaction.id);
              if (mounted) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('交易已刪除')),
                );
              }
            },
            child: const Text('刪除'),
          ),
        ],
      ),
    );
  }
}

/// 詳情行
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
