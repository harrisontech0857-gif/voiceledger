import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  late PageController _pageController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _previousDay() {
    _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextDay() {
    _selectedDate = _selectedDate.add(const Duration(days: 1));
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy年MM月dd日', 'zh_TW');
    final dayFormat = DateFormat('EEEE', 'zh_TW');

    return Scaffold(
      appBar: AppBar(title: const Text('生活日記'), centerTitle: true),
      body: Column(
        children: [
          // Date Navigation
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _previousDay,
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Column(
                      children: [
                        Text(
                          dateFormat.format(_selectedDate),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          dayFormat.format(_selectedDate),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: _nextDay,
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Journal Content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _selectedDate = DateTime.now().add(
                    Duration(days: index - 1000),
                  );
                });
              },
              itemBuilder: (context, index) {
                return _JournalEntryView(date: _selectedDate);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _JournalEntryView extends ConsumerWidget {
  final DateTime date;

  const _JournalEntryView({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mock journal entry
    final mockEntry = '''本日花費 NT\$ 1,250

早上花了 NT\$ 85 買早餐，是我最喜歡的麵店。中午和同事外出，點了便當花了 NT\$ 95。下午在便利店購物，花了 NT\$ 125，主要是買日用品。

這個月的支出比上個月多了 12%，主要是因為增加了購物和娛樂開支。AI 秘書建議我要控制購物開支，並設立更實際的每日預算。

今日反思：
• 應該提前規劃購物清單，避免衝動消費
• 和同事外出時可以選擇更經濟實惠的選項
• 娛樂開支需要更加節制

明日目標：
✓ 限制購物開支在 NT\$ 100 以內
✓ 準備便當以減少外出用餐
✓ 記錄所有消費並即時反思
''';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Generated Entry
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(
                color: AppTheme.primaryGradientStart.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppTheme.primaryGradientStart,
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.spacingSmall),
                    Text(
                      'AI 生成日記',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.primaryGradientStart,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                Text(
                  mockEntry,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingLarge),

          // Daily Stats
          Text('今日統計', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppTheme.spacingMedium),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.shopping_bag_rounded,
                  label: '交易筆數',
                  value: '5',
                  color: Color(0xFF2196F3),
                ),
              ),
              const SizedBox(width: AppTheme.spacingSmall),
              Expanded(
                child: _StatCard(
                  icon: Icons.trending_down_rounded,
                  label: '總支出',
                  value: 'NT\$ 1,250',
                  color: AppTheme.primaryGradientStart,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSmall),
              Expanded(
                child: _StatCard(
                  icon: Icons.trending_up_rounded,
                  label: '預算使用',
                  value: '45%',
                  color: AppTheme.successGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLarge),

          // Emotions
          Text('今日心情', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppTheme.spacingMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _EmotionButton(emoji: '😊', label: '愉快', selected: true),
              _EmotionButton(emoji: '😐', label: '平常'),
              _EmotionButton(emoji: '😔', label: '低落'),
              _EmotionButton(emoji: '😤', label: '煩躁'),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLarge),

          // Edit Note
          Text('個人筆記', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppTheme.spacingSmall),
          TextField(
            maxLines: 5,
            decoration: InputDecoration(
              hintText: '添加您的個人筆記...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('日記已保存')));
              },
              child: const Text('保存日記'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(AppTheme.spacingSmall),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppTheme.spacingSmall),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _EmotionButton extends StatefulWidget {
  final String emoji;
  final String label;
  final bool selected;

  const _EmotionButton({
    required this.emoji,
    required this.label,
    this.selected = false,
  });

  @override
  State<_EmotionButton> createState() => _EmotionButtonState();
}

class _EmotionButtonState extends State<_EmotionButton> {
  late bool _isSelected;

  @override
  void initState() {
    super.initState();
    _isSelected = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => _isSelected = !_isSelected);
      },
      child: Container(
        decoration: BoxDecoration(
          color: _isSelected
              ? AppTheme.primaryGradientStart.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: _isSelected
                ? AppTheme.primaryGradientStart
                : Colors.grey.withOpacity(0.2),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMedium,
          vertical: AppTheme.spacingSmall,
        ),
        child: Column(
          children: [
            Text(widget.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              widget.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _isSelected
                        ? AppTheme.primaryGradientStart
                        : Colors.grey,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
