import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import '../../core/theme.dart';
import '../../services/couple_service.dart';
import '../../main.dart' show kMockMode;

class PairingScreen extends ConsumerStatefulWidget {
  const PairingScreen({super.key});

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  final _codeController = TextEditingController();
  String? _myInviteCode;
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _partnerDiaries = [];
  bool _isDiariesLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPartnerDiaries();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadPartnerDiaries() async {
    if (kMockMode) return;
    setState(() => _isDiariesLoading = true);
    try {
      final service = ref.read(coupleServiceProvider);
      if (service == null) return;

      final couple = await service.getCurrentCouple();
      if (couple == null || !couple.isActive) {
        setState(() => _isDiariesLoading = false);
        return;
      }

      final partnerId =
          couple.userA == Supabase.instance.client.auth.currentUser?.id
              ? couple.userB
              : couple.userA;
      if (partnerId == null) {
        setState(() => _isDiariesLoading = false);
        return;
      }

      // 取得伴侶最近的日記
      final data = await Supabase.instance.client
          .from('life_diaries')
          .select()
          .eq('user_id', partnerId)
          .order('diary_date', ascending: false)
          .limit(10);

      if (mounted) {
        setState(() {
          _partnerDiaries = List<Map<String, dynamic>>.from(data as List);
          _isDiariesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDiariesLoading = false);
      }
    }
  }

  Future<void> _dissolveCouple() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('解除配對'),
          content: const Text('確認要解除配對嗎？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('確認'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final service = ref.read(coupleServiceProvider);
        if (service == null) return;
        await service.dissolveCouple();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('已解除配對')));
          ref.invalidate(currentCoupleProvider);
          setState(() {
            _partnerDiaries = [];
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('解除配對失敗: $e')));
        }
      }
    }
  }

  Future<void> _createInvite() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final service = ref.read(coupleServiceProvider);
      if (service == null) return;
      final couple = await service.createInvite();
      setState(() => _myInviteCode = couple.inviteCode);
    } catch (e) {
      setState(() => _error = '建立邀請碼失敗: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptInvite() async {
    final code = _codeController.text.trim();
    if (code.isEmpty || code.length != 6) {
      setState(() => _error = '請輸入 6 位邀請碼');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final service = ref.read(coupleServiceProvider);
      if (service == null) return;
      await service.acceptInvite(code);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('配對成功！一起養寵物吧 🐱')));
        context.go('/dashboard');
      }
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final coupleAsync = ref.watch(currentCoupleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('配對伴侶'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => context.go('/dashboard'),
            child: const Text('返回'),
          ),
        ],
      ),
      body: coupleAsync.when(
        data: (couple) {
          if (couple == null || !couple.isActive) {
            return _buildUnpairedUI(cs);
          }
          return _buildPairedUI(couple, cs);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildUnpairedUI(cs),
      ),
    );
  }

  Widget _buildUnpairedUI(ColorScheme cs) {
    // 訪客不能配對
    if (Supabase.instance.client.auth.currentUser?.isAnonymous == true) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('💕', style: TextStyle(fontSize: 64)),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '註冊後才能和伴侶配對',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '註冊帳號後，你的體驗資料會保留',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () => context.push('/auth'),
                child: const Text('前往註冊'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 標題圖示
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('🐱', style: const TextStyle(fontSize: 56)),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '一起養寵物',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '和伴侶配對後，你們會共同養一隻招財貓\n輪流寫日記餵食牠，看牠一步步進化！',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // 錯誤訊息
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                _error!,
                style: TextStyle(color: cs.onErrorContainer),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // 方案一：建立邀請碼
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: cs.primary.withAlpha(40)),
            ),
            child: Column(
              children: [
                Text(
                  '建立邀請碼',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '把邀請碼傳給你的伴侶',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.md),
                if (_myInviteCode != null) ...[
                  // 顯示邀請碼
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _myInviteCode!,
                          style: Theme.of(
                            context,
                          ).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: _myInviteCode!),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('邀請碼已複製')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '等對方輸入後就會自動配對',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ] else
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _createInvite,
                      child:
                          _isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('產生邀請碼'),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 分隔線
          Row(
            children: [
              Expanded(child: Divider(color: cs.outlineVariant)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text('或', style: Theme.of(context).textTheme.bodySmall),
              ),
              Expanded(child: Divider(color: cs.outlineVariant)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 方案二：輸入邀請碼
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Column(
              children: [
                Text(
                  '輸入對方的邀請碼',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _codeController,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 6,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    letterSpacing: 6,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: 'A B C 1 2 3',
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _acceptInvite,
                    child: const Text('配對'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPairedUI(CoupleInfo couple, ColorScheme cs) {
    final partnerId =
        couple.userA == Supabase.instance.client.auth.currentUser?.id
            ? couple.userB
            : couple.userA;
    final isMyTurn =
        couple.feedTurn == Supabase.instance.client.auth.currentUser?.id;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 伴侶名稱和寵物資訊
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('🐱', style: const TextStyle(fontSize: 48)),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '${couple.petName} Lv.${couple.petExp ~/ 100 + 1}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 餵食狀態
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isMyTurn ? cs.primaryContainer : cs.tertiaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              children: [
                Text(
                  isMyTurn ? '輪到你寫日記餵食了！' : '輪到伴侶寫日記餵食',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color:
                        isMyTurn
                            ? cs.onPrimaryContainer
                            : cs.onTertiaryContainer,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  isMyTurn ? '🍚' : '⏳',
                  style: const TextStyle(fontSize: 24),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 伴侶日記
          Text(
            '伴侶的日記',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.md),

          if (_isDiariesLoading)
            const Center(child: CircularProgressIndicator())
          else if (_partnerDiaries.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  '伴侶還沒有日記',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _partnerDiaries.length,
              itemBuilder: (context, index) {
                final diary = _partnerDiaries[index];
                final dateStr = diary['diary_date'] as String?;
                final mood = diary['mood'] as String? ?? 'neutral';
                final content = diary['content'] as String? ?? '';

                DateTime? diaryDate;
                if (dateStr != null) {
                  try {
                    diaryDate = DateTime.parse(dateStr);
                  } catch (_) {}
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            diaryDate != null
                                ? DateFormat('M月d日', 'zh_TW').format(diaryDate)
                                : '未知日期',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                          Text(
                            _getMoodEmoji(mood),
                            style: const TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        content.length > 200
                            ? '${content.substring(0, 200)}...'
                            : content,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),

          const SizedBox(height: AppSpacing.lg),

          // 解除配對按鈕
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _dissolveCouple,
              icon: const Icon(Icons.close_rounded),
              label: const Text('解除配對'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  String _getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return '😊';
      case 'sad':
        return '😔';
      case 'neutral':
        return '😐';
      case 'balanced':
        return '😌';
      case 'peaceful':
        return '😌';
      case 'excited':
        return '🤩';
      default:
        return '😐';
    }
  }
}
