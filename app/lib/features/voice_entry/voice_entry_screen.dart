import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../services/voice_service.dart';
import '../../services/couple_service.dart';
import '../../services/usage_service.dart';
import '../../services/voice_diary_service.dart';

class VoiceEntryScreen extends ConsumerStatefulWidget {
  const VoiceEntryScreen({super.key});

  @override
  ConsumerState<VoiceEntryScreen> createState() => _VoiceEntryScreenState();
}

class _VoiceEntryScreenState extends ConsumerState<VoiceEntryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isListening = false;
  bool _isProcessing = false;
  bool _voiceAvailable = true;
  String _partialText = ''; // 即時辨識結果
  String _finalText = ''; // 最終辨識結果
  String _aiResponse = '';

  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _checkVoiceAvailability();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _checkVoiceAvailability() async {
    final voiceService = ref.read(voiceServiceProvider);
    final ok = await voiceService.initialize();
    if (mounted) {
      setState(() => _voiceAvailable = ok);
    }
  }

  /// 開始錄音（檢查免費額度）
  Future<void> _startListening() async {
    if (_isListening) {
      await _stopListening();
      return;
    }

    // 檢查免費額度
    final usageService = ref.read(usageServiceProvider);
    final canUse = await usageService.canUseVoice();
    if (!canUse && mounted) {
      _showQuotaExhaustedDialog();
      return;
    }

    setState(() {
      _isListening = true;
      _partialText = '';
      _finalText = '';
      _aiResponse = '';
      _isProcessing = false;
    });

    _pulseController.repeat(reverse: true);

    final voiceService = ref.read(voiceServiceProvider);

    // 設定即時回呼 — 手動停止模式，不自動處理
    voiceService.onResult = (text, isFinal) {
      if (!mounted) return;
      setState(() {
        _partialText = text;
        if (isFinal) {
          _finalText = text;
        }
      });
      // 手動停止模式：不在 isFinal 時自動處理
    };

    voiceService.onStatus = (status) {
      if (!mounted) return;
      if (status == 'done' || status == 'notListening') {
        // 手動停止模式：語音引擎因平台限制暫停時，自動重啟繼續聆聽
        if (_isListening) {
          voiceService.restartListening(localeId: 'zh_TW');
        }
      } else if (status == 'not_supported' || status == 'error') {
        setState(() {
          _isListening = false;
          _voiceAvailable = false;
        });
        _pulseController.stop();
        _pulseController.reset();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('語音功能不可用，請使用文字輸入')));
        }
      }
    };

    await voiceService.startListening(localeId: 'zh_TW');
  }

  /// 手動停止錄音
  Future<void> _stopListening() async {
    final voiceService = ref.read(voiceServiceProvider);
    final text = await voiceService.stopListening();

    _pulseController.stop();
    _pulseController.reset();

    if (mounted) {
      setState(() => _isListening = false);

      final result = text.isNotEmpty ? text : _partialText;
      if (result.isNotEmpty) {
        _onRecognitionDone(result);
      }
    }
  }

  /// 辨識完成後處理
  void _onRecognitionDone(String text) {
    _pulseController.stop();
    _pulseController.reset();

    setState(() {
      _isListening = false;
      _finalText = text;
      _partialText = text;
    });

    _processInput(text);
  }

  /// 用文字輸入提交
  void _submitText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _finalText = text;
      _partialText = text;
    });

    _textController.clear();
    _processInput(text);
  }

  /// AI 處理輸入 — 語音日記模式（MVP 核心流程）
  ///
  /// 語音 → AI 分析情緒 + 主題標籤 → 生成日記 → 存到 life_diaries
  Future<void> _processInput(String transcript) async {
    setState(() => _isProcessing = true);

    try {
      final voiceDiaryService = ref.read(voiceDiaryServiceProvider);
      final analysis = await voiceDiaryService.analyze(transcript);

      if (mounted) {
        setState(() {
          _aiResponse =
              '${analysis.moodEmoji} ${analysis.diary}\n\n'
              '標籤：${analysis.tags.map((t) => '#$t').join(' ')}';
          _isProcessing = false;
        });

        _showDiaryConfirmDialog(analysis);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('AI 分析失敗: $e')));
      }
    }
  }

  /// 日記確認對話框
  void _showDiaryConfirmDialog(VoiceDiaryAnalysis analysis) {
    showDialog(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 標題列
                  Row(
                    children: [
                      Text(
                        analysis.moodEmoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'AI 日記',
                          style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 標籤列
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children:
                        analysis.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(
                                AppRadius.full,
                              ),
                            ),
                            child: Text(
                              '#$tag',
                              style: Theme.of(
                                ctx,
                              ).textTheme.labelSmall?.copyWith(
                                color: cs.onPrimaryContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 日記內容
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                      analysis.diary,
                      style: Theme.of(
                        ctx,
                      ).textTheme.bodyMedium?.copyWith(height: 1.6),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // 原始語音
                  Text(
                    '原始語音：「${analysis.originalTranscript}」',
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 按鈕
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('取消'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.save_rounded, size: 18),
                          label: const Text('存入日記'),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _saveDiaryEntry(analysis);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 儲存日記
  Future<void> _saveDiaryEntry(VoiceDiaryAnalysis analysis) async {
    final voiceDiaryService = ref.read(voiceDiaryServiceProvider);
    await voiceDiaryService.saveDiaryEntry(analysis);

    // 記錄語音使用次數
    try {
      final usageService = ref.read(usageServiceProvider);
      await usageService.recordVoiceUsage();
    } catch (_) {}

    // 餵食共同寵物
    String feedMessage = '';
    try {
      final coupleService = ref.read(coupleServiceProvider);
      if (coupleService != null) {
        feedMessage = await coupleService.feedPet();
      }
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            feedMessage.isNotEmpty
                ? '${analysis.moodEmoji} 日記已保存！$feedMessage'
                : '${analysis.moodEmoji} 日記已保存！',
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 3),
        ),
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) context.go('/dashboard');
      });
    }
  }

  void _showQuotaExhaustedDialog() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('本月免費額度已用完'),
            content: const Text(
              '免費版每月可記錄 30 則語音日記。\n升級 Pro 即可無限使用語音日記和 AI 秘書功能！',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('下次再說'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/paywall');
                },
                child: const Text('查看方案'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('語音日記'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 主要內容區（可滾動）
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.xl),

                    // 麥克風按鈕（按下開始/停止）
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 外圈脈衝動畫
                          if (_isListening)
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Container(
                                  width: 200 * _pulseAnimation.value,
                                  height: 200 * _pulseAnimation.value,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: cs.primary.withAlpha(80),
                                      width: 2,
                                    ),
                                  ),
                                );
                              },
                            ),
                          // 主按鈕
                          GestureDetector(
                            onTap: _isProcessing ? null : _startListening,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: _isListening ? 150 : 140,
                              height: _isListening ? 150 : 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors:
                                      _isListening
                                          ? [Colors.red, Colors.red.shade700]
                                          : [cs.primary, cs.tertiary],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isListening
                                            ? Colors.red
                                            : cs.primary)
                                        .withAlpha(100),
                                    blurRadius: _isListening ? 30 : 15,
                                    spreadRadius: _isListening ? 5 : 0,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _isListening
                                    ? Icons.stop_rounded
                                    : Icons.mic_rounded,
                                color: Colors.white,
                                size: 56,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // 狀態文字
                    Text(
                      _isListening
                          ? '正在聆聽中...'
                          : _isProcessing
                          ? 'AI 正在分析中...'
                          : _voiceAvailable
                          ? '按下麥克風開始說話'
                          : '語音不可用，請用下方文字輸入',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    if (_isListening)
                      Text(
                        '說完後按紅色按鈕停止',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.red.shade200,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    if (!_isListening && !_isProcessing)
                      Text(
                        '例如：「今天和朋友喝咖啡聊得很開心」「加班好累但完成了專案」',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withAlpha(100),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: AppSpacing.lg),

                    // 即時辨識結果
                    if (_partialText.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(15),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(
                            color:
                                _isListening
                                    ? Colors.amber.withAlpha(80)
                                    : cs.primary.withAlpha(60),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _isListening
                                      ? Icons.hearing_rounded
                                      : Icons.check_circle_rounded,
                                  color:
                                      _isListening
                                          ? Colors.amber
                                          : Colors.green,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _isListening ? '辨識中...' : '辨識完成',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.labelSmall?.copyWith(
                                    color:
                                        _isListening
                                            ? Colors.amber
                                            : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              _partialText,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),

                    // AI 回饋
                    if (_aiResponse.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: cs.tertiary.withAlpha(30),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: cs.tertiary.withAlpha(60)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.smart_toy_rounded,
                              color: cs.tertiary,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                _aiResponse,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withAlpha(200),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (_isProcessing) ...[
                      const SizedBox(height: AppSpacing.lg),
                      const CircularProgressIndicator(color: Colors.white),
                    ],
                  ],
                ),
              ),
            ),

            // 底部：文字輸入備案
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(10),
                border: Border(
                  top: BorderSide(color: Colors.white.withAlpha(20)),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: '或直接輸入今天發生的事...',
                          hintStyle: TextStyle(
                            color: Colors.white.withAlpha(80),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white.withAlpha(15),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (_) => _submitText(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [cs.primary, cs.tertiary],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isProcessing ? null : _submitText,
                          customBorder: const CircleBorder(),
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 已棄用 — 舊交易確認元件（保留防止其他地方引用）
class _DetailChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(value, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }
}
