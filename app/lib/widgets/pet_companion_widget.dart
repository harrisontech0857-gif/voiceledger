import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../models/pet.dart';
import '../services/pet_service.dart';

/// 寵物伴侶 Widget — 首頁主視覺
///
/// 大尺寸寵物圖 + 對話氣泡 + 名字/階段 + 經驗條
/// 等級/連續/筆數已移至獨立字卡區塊
class PetCompanionWidget extends ConsumerStatefulWidget {
  final VoidCallback? onTap;

  const PetCompanionWidget({super.key, this.onTap});

  @override
  ConsumerState<PetCompanionWidget> createState() => _PetCompanionWidgetState();
}

class _PetCompanionWidgetState extends ConsumerState<PetCompanionWidget>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _floatController;
  late Animation<double> _bounceAnim;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _bounceAnim =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.12), weight: 30),
          TweenSequenceItem(tween: Tween(begin: 1.12, end: 0.95), weight: 30),
          TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 40),
        ]).animate(
          CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
        );

    _floatController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _onPetTap() {
    _bounceController.forward(from: 0);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final pet = ref.watch(petProvider);
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        // 寵物主視覺區域
        GestureDetector(
          onTap: _onPetTap,
          child: SizedBox(
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 背景光暈
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        cs.primaryContainer.withAlpha(80),
                        cs.primaryContainer.withAlpha(0),
                      ],
                    ),
                  ),
                ),
                // 寵物圖片（大尺寸 + 漂浮動畫）
                AnimatedBuilder(
                  animation: Listenable.merge([_bounceAnim, _floatAnim]),
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _floatAnim.value),
                      child: Transform.scale(
                        scale: _bounceAnim.value,
                        child: child,
                      ),
                    );
                  },
                  child: Image.asset(
                    pet.imagePath,
                    width: 225,
                    height: 225,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Text(
                      pet.stageEmoji,
                      style: const TextStyle(fontSize: 120),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 對話氣泡
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Text(
            pet.dialogue.replaceAll('{streak}', '${pet.streak}'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.3),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // 名字 + 階段標籤
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              pet.name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _stageColor(pet.stage).withAlpha(30),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                pet.stageName,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: _stageColor(pet.stage),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // 經驗條
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: _ExpProgressBar(pet: pet),
        ),
      ],
    );
  }

  Color _stageColor(PetStage stage) {
    switch (stage) {
      case PetStage.egg:
        return Colors.grey;
      case PetStage.baby:
        return Colors.green;
      case PetStage.teen:
        return Colors.blue;
      case PetStage.adult:
        return Colors.orange;
      case PetStage.master:
        return Colors.amber;
    }
  }
}

/// 經驗條
class _ExpProgressBar extends StatelessWidget {
  final PetModel pet;
  const _ExpProgressBar({required this.pet});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isMaxed = pet.stage == PetStage.master;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isMaxed ? '已達最高階段' : '下一階段',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            Text(
              isMaxed ? 'EXP ${pet.exp}' : '還需 ${pet.expToNextStage} EXP',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pet.stageProgress.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: cs.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              isMaxed ? Colors.amber : cs.primary,
            ),
          ),
        ),
      ],
    );
  }
}
