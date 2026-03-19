import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/theme.dart';
import '../../models/transaction.dart';
import '../../services/diary_service.dart';
import '../../services/pet_service.dart';
import '../../services/transaction_service.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<Transaction> _transactions = [];
  Set<DateTime> _recordDays = {};
  DiaryEntry? _diaryEntry;
  bool _isDiaryLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _loadDiary(_selectedDay);
  }

  Future<void> _loadTransactions() async {
    final service = ref.read(transactionServiceProvider);
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(now.year, now.month + 1, 0);

    final transactions = await service.getTransactions(
      startDate: startDate,
      endDate: endDate,
    );

    final recordDays = <DateTime>{};
    for (final tx in transactions) {
      recordDays.add(
        DateTime(tx.createdAt.year, tx.createdAt.month, tx.createdAt.day),
      );
    }

    if (mounted) {
      setState(() {
        _transactions = transactions;
        _recordDays = recordDays;
      });
    }
  }

  Future<void> _loadDiary(DateTime date) async {
    setState(() => _isDiaryLoading = true);
    final diaryService = ref.read(diaryServiceProvider);

    // 先嘗試取得已存在的日記
    var diary = await diaryService.getDiary(date);

    // 如果沒有，且當天有交易，則生成
    if (diary == null) {
      final dayTx = _getTransactionsForDay(date);
      if (dayTx.isNotEmpty) {
        diary = await diaryService.generateDiary(date);
      }
    }

    if (mounted) {
      setState(() {
        _diaryEntry = diary;
        _isDiaryLoading = false;
      });
    }
  }

  List<Transaction> _getTransactionsForDay(DateTime day) {
    return _transactions.where((tx) {
      return tx.createdAt.year == day.year &&
          tx.createdAt.month == day.month &&
          tx.createdAt.day == day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final transactions = _getTransactionsForDay(_selectedDay);
    final totalExpense = transactions.fold<double>(
      0,
      (sum, tx) => sum + tx.amount,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('生活日記'),
        centerTitle: true,
        actions: [
          // 切換月/雙週/週 視圖
          IconButton(
            icon: Icon(
              _calendarFormat == CalendarFormat.month
                  ? Icons.view_week_rounded
                  : Icons.calendar_month_rounded,
            ),
            tooltip:
                _calendarFormat == CalendarFormat.month ? '切換週視圖' : '切換月視圖',
            onPressed: () {
              setState(() {
                _calendarFormat =
                    _calendarFormat == CalendarFormat.month
                        ? CalendarFormat.twoWeeks
                        : CalendarFormat.month;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 月曆區域
          _buildCalendar(cs),

          // 下方可滾動內容
          Expanded(
            child:
                transactions.isEmpty
                    ? _buildEmptyState(context)
                    : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 選中日期的摘要
                          _buildDaySummary(context, transactions, totalExpense),

                          // AI 日記摘要
                          _buildAiDiary(context, transactions, totalExpense),

                          // 當日交易明細標題
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              AppSpacing.sm,
                              AppSpacing.md,
                              AppSpacing.sm,
                            ),
                            child: Text(
                              '交易明細',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),

                          // 當日交易列表
                          ...transactions.map(
                            (tx) => _buildTransactionTile(context, tx),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xl),
        ),
      ),
      child: TableCalendar(
        locale: 'zh_TW',
        firstDay: DateTime(2024, 1, 1),
        lastDay: DateTime(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
            _diaryEntry = null;
          });
          _loadDiary(selectedDay);
        },
        onFormatChanged: (format) {
          setState(() => _calendarFormat = format);
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        // 外觀設定
        calendarStyle: CalendarStyle(
          // 今天
          todayDecoration: BoxDecoration(
            color: cs.primary.withAlpha(40),
            shape: BoxShape.circle,
          ),
          todayTextStyle: TextStyle(
            color: cs.primary,
            fontWeight: FontWeight.bold,
          ),
          // 選中日
          selectedDecoration: BoxDecoration(
            color: cs.primary,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          // 預設
          defaultTextStyle: TextStyle(color: cs.onSurface),
          weekendTextStyle: TextStyle(color: cs.onSurfaceVariant),
          outsideTextStyle: TextStyle(color: cs.onSurfaceVariant.withAlpha(80)),
          // marker（有記錄的日期）
          markersMaxCount: 1,
          markerDecoration: BoxDecoration(
            color: cs.tertiary,
            shape: BoxShape.circle,
          ),
          markerSize: 6,
          markerMargin: const EdgeInsets.only(top: 1),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
          leftChevronIcon: Icon(Icons.chevron_left, color: cs.onSurfaceVariant),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: cs.onSurfaceVariant,
          ),
          headerPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          weekendStyle: TextStyle(
            color: cs.onSurfaceVariant.withAlpha(160),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        // 標記有記帳的日期
        eventLoader: (day) {
          return _recordDays.any(
                (d) =>
                    d.year == day.year &&
                    d.month == day.month &&
                    d.day == day.day,
              )
              ? ['record']
              : [];
        },
        calendarBuilders: CalendarBuilders(
          // 自訂 marker：小圓點
          markerBuilder: (context, date, events) {
            if (events.isEmpty) return null;
            // 不要在選中日和今天重複顯示
            if (isSameDay(date, _selectedDay)) return null;
            return Positioned(
              bottom: 4,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: cs.tertiary,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDaySummary(
    BuildContext context,
    List<Transaction> transactions,
    double totalExpense,
  ) {
    final cs = Theme.of(context).colorScheme;
    final dateStr = DateFormat('M月d日 EEEE', 'zh_TW').format(_selectedDay);
    final isToday = isSameDay(_selectedDay, DateTime.now());

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isToday ? '今天 · $dateStr' : dateStr,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  transactions.isEmpty
                      ? '尚無記錄'
                      : '${transactions.length} 筆交易 · 支出 NT\$ ${NumberFormat('#,###').format(totalExpense)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (transactions.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                '-NT\$ ${NumberFormat('#,###').format(totalExpense)}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onErrorContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_note_rounded,
            size: 56,
            color: cs.onSurfaceVariant.withAlpha(80),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '這天還沒有記錄',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '用語音說說你的花費吧',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant.withAlpha(140),
            ),
          ),
        ],
      ),
    );
  }

  /// AI 生成的日記摘要 + 寵物評語
  Widget _buildAiDiary(
    BuildContext context,
    List<Transaction> transactions,
    double totalExpense,
  ) {
    final cs = Theme.of(context).colorScheme;
    final pet = ref.watch(petProvider);
    final dateStr = DateFormat('M月d日', 'zh_TW').format(_selectedDay);

    // 優先使用 Edge Function 生成的日記，否則 fallback 到 client-side
    String summary;
    if (_diaryEntry != null && _diaryEntry!.content.isNotEmpty) {
      summary = _diaryEntry!.content;
    } else if (_isDiaryLoading) {
      summary = '正在生成日記⋯⋯';
    } else {
      final categories = transactions
          .map((tx) => tx.category.displayName)
          .toSet()
          .join('、');
      summary =
          '今日共 ${transactions.length} 筆消費，'
          '總計 NT\$ ${NumberFormat('#,###').format(totalExpense.toInt())}。'
          '主要類別為$categories。';
    }

    // 寵物對今日消費的評語
    String petComment;
    final expenseAmount = transactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold<double>(0, (sum, tx) => sum + tx.amount);
    if (expenseAmount > 1000) {
      petComment = '${pet.stageEmoji} ${pet.name}：「今天花好多⋯⋯我的肚子都在叫了！」';
    } else if (expenseAmount > 500) {
      petComment = '${pet.stageEmoji} ${pet.name}：「還行啦，但可以再省一點喔～」';
    } else if (expenseAmount > 0) {
      petComment = '${pet.stageEmoji} ${pet.name}：「很棒！今天花費控制得不錯 ✨」';
    } else {
      petComment = '${pet.stageEmoji} ${pet.name}：「零消費日！太厲害了吧！」';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: cs.primary.withAlpha(50)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: cs.primary, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'AI 日記 · $dateStr',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              summary,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            const SizedBox(height: AppSpacing.sm),
            // 寵物評語
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: cs.tertiaryContainer.withAlpha(60),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                petComment,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onTertiaryContainer,
                  height: 1.4,
                ),
              ),
            ),
            if (expenseAmount > 500) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: cs.errorContainer.withAlpha(80),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  '💡 今日花費偏高，注意控制支出',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: cs.error),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 單筆交易 tile
  Widget _buildTransactionTile(BuildContext context, Transaction tx) {
    final isIncome = tx.type == TransactionType.income;
    final timeStr = DateFormat('HH:mm').format(tx.createdAt);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.sm,
      ),
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
                  const SizedBox(height: 2),
                  Text(
                    '${tx.category.displayName} · $timeStr',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${isIncome ? '+' : '-'}NT\$ ${NumberFormat('#,###').format(tx.amount.toInt())}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color:
                    isIncome
                        ? Colors.green
                        : Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
