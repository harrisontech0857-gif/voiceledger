import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pet.dart';
import '../services/pet_service.dart';

/// 🐛 寵物除錯面板 — 開發測試用，正式版移除
///
/// 提供快速切換階段 & 心情的按鈕，
/// 方便測試所有 17 張寵物圖片是否正常顯示。
class PetDebugPanel extends ConsumerStatefulWidget {
  const PetDebugPanel({super.key});

  @override
  ConsumerState<PetDebugPanel> createState() => _PetDebugPanelState();
}

class _PetDebugPanelState extends ConsumerState<PetDebugPanel> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final pet = ref.watch(petProvider);
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cs.errorContainer.withAlpha(30),
        border: Border.all(color: cs.error.withAlpha(80), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題列（可收合）
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.bug_report, size: 18, color: cs.error),
                  const SizedBox(width: 8),
                  Text(
                    '🐛 除錯面板',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: cs.error,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  // 當前狀態小標
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${pet.stageName} · ${_moodLabel(pet.mood)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          // 展開內容
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 當前狀態資訊
                  _buildInfoRow(context, pet),
                  const SizedBox(height: 12),

                  // 階段切換
                  Text(
                    '階段切換',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildStageButtons(context, pet),
                  const SizedBox(height: 12),

                  // 心情切換
                  Text(
                    '心情切換',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildMoodButtons(context, pet),
                  const SizedBox(height: 12),

                  // 快速巡覽所有組合
                  _buildAutoTestButton(context),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 當前狀態資訊列
  Widget _buildInfoRow(BuildContext context, PetModel pet) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(120),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _infoChip('EXP', '${pet.exp}', cs),
          const SizedBox(width: 8),
          _infoChip('階段', pet.stageName, cs),
          const SizedBox(width: 8),
          _infoChip('心情', _moodLabel(pet.mood), cs),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              pet.imagePath.split('/').last,
              style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String label, String value, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withAlpha(80),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(fontSize: 10, color: cs.onPrimaryContainer),
      ),
    );
  }

  /// 階段快速切換按鈕列
  Widget _buildStageButtons(BuildContext context, PetModel pet) {
    const stages = [
      (PetStage.egg, '🥚 蛋', 0),
      (PetStage.baby, '🐱 幼貓', 50),
      (PetStage.teen, '😺 少年', 200),
      (PetStage.adult, '😸 招財', 500),
      (PetStage.master, '🏆 金財神', 1000),
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children:
          stages.map((s) {
            final isActive = pet.stage == s.$1;
            return _DebugChipButton(
              label: s.$2,
              isActive: isActive,
              onTap: () => ref.read(petProvider.notifier).debugSetStage(s.$1),
            );
          }).toList(),
    );
  }

  /// 心情快速切換按鈕列
  Widget _buildMoodButtons(BuildContext context, PetModel pet) {
    const moods = [
      (PetMood.happy, '✨ 開心'),
      (PetMood.neutral, '😊 日常'),
      (PetMood.hungry, '😿 餓了'),
      (PetMood.sleepy, '😴 想睡'),
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children:
          moods.map((m) {
            final isActive = pet.mood == m.$1;
            return _DebugChipButton(
              label: m.$2,
              isActive: isActive,
              onTap: () => ref.read(petProvider.notifier).debugSetMood(m.$1),
            );
          }).toList(),
    );
  }

  /// 自動巡覽所有組合按鈕
  Widget _buildAutoTestButton(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _runAutoTest(context),
        icon: Icon(Icons.play_arrow, size: 16, color: cs.primary),
        label: Text(
          '▶ 自動巡覽全部 17 張圖片（每張 1.5 秒）',
          style: TextStyle(fontSize: 12, color: cs.primary),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: cs.primary.withAlpha(80)),
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  /// 自動巡覽所有 stage × mood 組合
  Future<void> _runAutoTest(BuildContext context) async {
    final notifier = ref.read(petProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);

    // 定義所有組合：蛋只有 1 張，其餘各 4 張
    final combos = <(PetStage, PetMood?, String)>[
      (PetStage.egg, null, 'egg.png'),
      ...PetMood.values.expand(
        (mood) => [(PetStage.baby, mood, 'baby_${mood.name}.png')],
      ),
      ...PetMood.values.expand(
        (mood) => [(PetStage.teen, mood, 'teen_${mood.name}.png')],
      ),
      ...PetMood.values.expand(
        (mood) => [(PetStage.adult, mood, 'adult_${mood.name}.png')],
      ),
      ...PetMood.values.expand(
        (mood) => [(PetStage.master, mood, 'master_${mood.name}.png')],
      ),
    ];

    messenger.showSnackBar(
      SnackBar(
        content: Text('開始巡覽 ${combos.length} 張圖片...'),
        duration: const Duration(seconds: 2),
      ),
    );

    for (int i = 0; i < combos.length; i++) {
      if (!mounted) return;
      final (stage, mood, filename) = combos[i];

      notifier.debugSetStage(stage);
      if (mood != null) {
        notifier.debugSetMood(mood);
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text('[${i + 1}/${combos.length}] $filename'),
          duration: const Duration(milliseconds: 1400),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 1500));
    }

    if (mounted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('✅ 巡覽完成！全部 17 張圖片已檢查。'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  String _moodLabel(PetMood mood) {
    return switch (mood) {
      PetMood.happy => '開心',
      PetMood.neutral => '日常',
      PetMood.hungry => '餓了',
      PetMood.sleepy => '想睡',
    };
  }
}

/// 除錯面板用的小按鈕
class _DebugChipButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _DebugChipButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? cs.primary : cs.outlineVariant,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? cs.onPrimary : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
