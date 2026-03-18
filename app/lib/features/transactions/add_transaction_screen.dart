import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/transaction.dart';
import '../../services/transaction_service.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _noteController;

  TransactionType _type = TransactionType.expense;
  TransactionCategory _category = TransactionCategory.food;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveTransaction() async {
    if (_amountController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請輸入所有必要資訊')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      const uuid = Uuid();
      final transaction = Transaction(
        id: uuid.v4(),
        userId: 'current_user_id',
        amount: double.parse(_amountController.text),
        type: _type,
        category: _category,
        createdAt: _selectedDate,
        description: _descriptionController.text,
        notes: _noteController.text.isNotEmpty ? _noteController.text : null,
      );

      final service = ref.read(transactionServiceProvider);
      await service.addTransaction(transaction);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('交易已保存')));
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失敗: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd', 'zh_TW');

    return Scaffold(
      appBar: AppBar(title: const Text('新增交易'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 交易類型選擇
            Text('交易類型', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<TransactionType>(
                    segments: const [
                      ButtonSegment(
                        value: TransactionType.expense,
                        label: Text('支出'),
                        icon: Icon(Icons.arrow_downward_rounded),
                      ),
                      ButtonSegment(
                        value: TransactionType.income,
                        label: Text('收入'),
                        icon: Icon(Icons.arrow_upward_rounded),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: (selected) {
                      setState(() => _type = selected.first);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // 金額輸入
            Text('金額', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              enabled: !_isLoading,
              decoration: const InputDecoration(
                labelText: '金額 (NT\$)',
                prefixIcon: Icon(Icons.attach_money_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 類別選擇
            Text('類別', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            DropdownMenu<TransactionCategory>(
              width: double.infinity,
              initialSelection: _category,
              onSelected: (value) {
                if (value != null) {
                  setState(() => _category = value);
                }
              },
              dropdownMenuEntries: TransactionCategory.values
                  .map(
                    (cat) => DropdownMenuEntry(
                      value: cat,
                      label: '${cat.icon} ${cat.displayName}',
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 日期選擇
            Text('日期', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: _isLoading ? null : _selectDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      dateFormat.format(_selectedDate),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 描述輸入
            Text('描述', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _descriptionController,
              enabled: !_isLoading,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: '交易描述',
                hintText: '例如：午餐',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 備註輸入
            Text('備註 (選擇)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _noteController,
              enabled: !_isLoading,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '額外備註',
                hintText: '您可以添加任何額外信息',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 儲存按鈕
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveTransaction,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('保存交易'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
