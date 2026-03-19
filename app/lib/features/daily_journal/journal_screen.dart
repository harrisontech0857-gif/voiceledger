import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'package:table_calendar/table_calendar.dart';
import '../../core/theme.dart';
import '../../main.dart' show kMockMode;
import '../../services/pet_service.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Set<DateTime> _recordDays = {};
  Map<String, dynamic>? _selectedDiary; // 選中日期的日記
  bool _isDiaryLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDiaryDates();
    _loadDiary(_selectedDay);
  }

  /// 載入有日記的日期（用於行事曆標記）
  Future<void> _loadDiaryDates() async {
    if (kMockMode) return;
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1).toIso8601String();
      final monthEnd = DateTime(now.year, now.month + 1, 0).toIso8601String();

      final data = await Supabase.instance.client
          .from('life_diaries')
          .select('diary_date')
          .eq('user_id', userId)
          .gte('diary_date', monthStart.split('T')[0])
          .lte('diary_date', monthEnd.split('T')[0]);

      final days = <DateTime>{};
      for (final row in (data as List)) {
        final dateStr = row['diary_date'] as String;
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          days.add(
            DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            ),
          );
        }
      }

      if (mounted) setState(() => _recordDays = days);
    } catch (e) {
      debugPrint('載入日記日期失敗: $e');
    }
  }

  /// 載入選中日期的日記內容
  Future<void> _loadDiary(DateTime date) async {
    if (kMockMode) return;
    setState(() => _isDiaryLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isDiaryLoading = false);
        return;
      }

      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final data =
          await Supabase.instance.client
              .from('life_diaries')
              .select()
              .eq('user_id', userId)
              .eq('diary_date', dateStr)
              .maybeSingle();

      if (mounted) {
        setState(() {
          _selectedDiary = data;
          _isDiaryLoading = false;
        });
      }
    } catch (e) {
      debugPrint('載入日記失敗: $e');
      if (mounted) setState(() => _isDiaryLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasDiary = _selectedDiary != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('生活日記'),
        centerTitle: true,
        actions: [
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
          _buildCalendar(cs),
          Expanded(
            child:
                _isDiaryLoading
                    ? const Center(child: CircularProgressIndicator())
                    : !hasDiary
                    ? _buildEmptyState(context)
                    : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDaySummary(context),
                          _buildDiaryContent(context),
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

  Widget _buildDaySummary(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateStr = DateFormat('M月d日 EEEE', 'zh_TW').format(_selectedDay);
    final isToday = isSameDay(_selectedDay, DateTime.now());
    final mood = _selectedDiary?['mood'] as String? ?? '';
    final moodEmoji = _moodToEmoji(mood);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          if (moodEmoji.isNotEmpty) ...[
            Text(moodEmoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: AppSpacing.sm),
          ],
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
                if (_selectedDiary?['highlight'] != null)
                  Text(
                    _selectedDiary!['highlight'] as String,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _moodToEmoji(String mood) {
    switch (mood) {
      case 'happy':
        return '😊';
      case 'calm':
        return '😌';
      case 'stressed':
        return '😮‍💨';
      case 'sad':
        return '😢';
      case 'excited':
        return '🤩';
      case 'reflective':
        return '🤔';
      default:
        return '📝';
    }
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
            '用語音說說你的一天吧',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant.withAlpha(140),
            ),
          ),
        ],
      ),
    );
  }

  /// 日記內容顯示 + 寵物評語
  Widget _buildDiaryContent(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pet = ref.watch(petProvider);
    final content = _selectedDiary?['content'] as String? ?? '';
    final personalNote = _selectedDiary?['personal_note'] as String?;

    final petComment = '${pet.stageEmoji} ${pet.name}：「${pet.dialogue}」';

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
                  'AI 日記',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              content,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            if (personalNote != null && personalNote.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                '原始語音：「$personalNote」',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
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
          ],
        ),
      ),
    );
  }
}
