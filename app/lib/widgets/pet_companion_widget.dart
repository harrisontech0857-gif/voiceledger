import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';
import '../models/pet.dart';
import '../services/pet_service.dart';
import '../services/couple_service.dart';

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
  String? _petPersonality;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _bounceAnim = TweenSequence<double>([
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

    _loadPersonality();
  }

  Future<void> _loadPersonality() async {
    final prefs = await SharedPreferences.getInstance();
    final personality = prefs.getString('pet_personality');
    if (mounted) {
      setState(() => _petPersonality = personality);
    }
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

  String _getPersonalityDialogue(PetModel pet) {
    final personality = _petPersonality ?? '';
    final moodName = pet.mood.name;

    switch (personality) {
      case 'energetic':
        return _getEnergeticDialogue(moodName);
      case 'gentle':
        return _getGentleDialogue(moodName);
      case 'funny':
        return _getFunnyDialogue(moodName);
      case 'clingy':
        return _getClingingDialogue(moodName);
      default:
        return pet.dialogue;
    }
  }

  String _getEnergeticDialogue(String mood) {
    switch (mood) {
      case 'happy':
        return '耶耶耶！你寫日記了！我好開心～跳跳跳！🎉';
      case 'neutral':
        return '嘿嘿！今天要寫什麼精彩的事？快來快來！';
      case 'hungry':
        return '嗚嗚⋯⋯人家好餓⋯⋯快點寫日記餵我啦！！';
      case 'sleepy':
        return '好無聊⋯⋯都沒人理我⋯⋯我要生氣了！💢';
      default:
        return '嘿嘿！一起來寫日記吧！';
    }
  }

  String _getGentleDialogue(String mood) {
    switch (mood) {
      case 'happy':
        return '謝謝你今天也寫了日記，你辛苦了 ✨';
      case 'neutral':
        return '今天過得好嗎？不急，想說的時候再說就好';
      case 'hungry':
        return '你一定很忙吧⋯⋯沒關係，我會等你的';
      case 'sleepy':
        return '我在這裡等你⋯⋯不管多久都會等⋯⋯💤';
      default:
        return '慢慢來，我一直在這裡';
    }
  }

  String _getFunnyDialogue(String mood) {
    switch (mood) {
      case 'happy':
        return '哇靠！你居然寫日記了！太陽打西邊出來啦 😂';
      case 'neutral':
        return '欸欸欸～今天有沒有什麼八卦可以分享？🍿';
      case 'hungry':
        return '我的肚子在開演唱會了⋯⋯咕嚕咕嚕～🎵';
      case 'sleepy':
        return 'Zzz⋯⋯我夢到你寫了日記⋯⋯原來只是夢啊⋯⋯😭';
      default:
        return '這是什麼鬼情況啦！';
    }
  }

  String _getClingingDialogue(String mood) {
    switch (mood) {
      case 'happy':
        return '你寫日記了！！我最喜歡你了！！抱抱～🥰';
      case 'neutral':
        return '你在幹嘛？想你想你想你～什麼時候寫日記？';
      case 'hungry':
        return '你是不是不愛我了⋯⋯都不寫日記⋯⋯嗚嗚嗚 😿';
      case 'sleepy':
        return '我好想你⋯⋯已經好久沒看到你了⋯⋯回來好不好⋯⋯';
      default:
        return '我好想你⋯⋯';
    }
  }

  @override
  Widget build(BuildContext context) {
    final coupleAsync = ref.watch(currentCoupleProvider);
    final pet = ref.watch(petProvider);
    final cs = Theme.of(context).colorScheme;

    // Get display pet data from couple if available, otherwise use local pet
    final displayPet = coupleAsync.maybeWhen(
      data: (couple) {
        if (couple == null || !couple.isActive) return pet;
        // Create display model from couple data
        return _buildDisplayPetFromCouple(couple, pet);
      },
      orElse: () => pet,
    );

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
                    displayPet.imagePath,
                    width: 225,
                    height: 225,
                    fit: BoxFit.contain,
                    errorBuilder:
                        (_, __, ___) => Text(
                          displayPet.stageEmoji,
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
            _getPersonalityDialogue(displayPet)
                .replaceAll('{streak}', '${displayPet.streak}')
                .replaceAll('{name}', displayPet.name)
                .replaceAll('{level}', '${displayPet.level}')
                .replaceAll('{exp}', '${displayPet.exp}'),
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
              displayPet.name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _stageColor(displayPet.stage).withAlpha(30),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                displayPet.stageName,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: _stageColor(displayPet.stage),
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
          child: _ExpProgressBar(pet: displayPet),
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

  /// Build a display PetModel from couple data
  PetModel _buildDisplayPetFromCouple(CoupleInfo couple, PetModel localPet) {
    final stage = _getStageFromExp(couple.petExp);
    final level = couple.petExp ~/ 100 + 1;

    // Map couple mood to PetMood
    final petMood = _mapCoupleToMood(couple.petMood);

    return PetModel(
      id: localPet.id,
      name: couple.petName,
      exp: couple.petExp,
      level: level,
      mood: petMood,
      streak: localPet.streak,
      createdAt: localPet.createdAt,
      totalEntries: localPet.totalEntries,
      lastFedAt: localPet.lastFedAt,
    );
  }

  /// Calculate PetStage from experience points
  PetStage _getStageFromExp(int exp) {
    if (exp >= 1000) return PetStage.master;
    if (exp >= 500) return PetStage.adult;
    if (exp >= 200) return PetStage.teen;
    if (exp >= 50) return PetStage.baby;
    return PetStage.egg;
  }

  /// Map couple mood string to PetMood enum
  PetMood _mapCoupleToMood(String coupleMode) {
    switch (coupleMode.toLowerCase()) {
      case 'happy':
        return PetMood.happy;
      case 'hungry':
        return PetMood.hungry;
      case 'sleepy':
        return PetMood.sleepy;
      case 'neutral':
      default:
        return PetMood.neutral;
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
