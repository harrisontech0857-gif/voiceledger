import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../core/supabase_client.dart';
import '../../models/transaction.dart';
import '../../services/voice_service.dart';
import '../../services/ai_service.dart';
import '../../services/pet_service.dart';
import '../../services/currency_service.dart';
import '../../services/transaction_service.dart';
import '../../services/usage_service.dart';

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

  /// AI 處理輸入 — 支援一句話多筆交易
  Future<void> _processInput(String transcript) async {
    setState(() => _isProcessing = true);

    try {
      final aiService = ref.read(aiServiceProvider);
      final details = await aiService.extractTransactionDetails(transcript);

      // 取得 AI 回饋（如果有 feedback 欄位就用，否則另外呼叫）
      String feedback = '';
      if (details.containsKey('feedback') &&
          (details['feedback'] as String).isNotEmpty) {
        feedback = details['feedback'] as String;
      } else {
        feedback = await aiService.analyzeTransaction(transcript);
      }

      // 檢查是否有多筆交易
      final allTx = details['all_transactions'] as List<dynamic>?;

      if (mounted) {
        setState(() {
          _aiResponse = feedback;
          _isProcessing = false;
        });

        if (allTx != null && allTx.length > 1) {
          // 多筆交易 → 顯示列表確認
          _showMultiTransactionDialog(allTx, feedback);
        } else {
          // 單筆交易
          _showConfirmationDialog(details);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('處理失敗: $e')));
      }
    }
  }

  /// 多筆交易確認對話框
  void _showMultiTransactionDialog(
    List<dynamic> transactions,
    String feedback,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => Dialog(
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '偵測到 ${transactions.length} 筆交易',
                          style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // 交易列表
                    ...transactions.map((tx) {
                      final t = tx as Map<String, dynamic>;
                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: Theme.of(ctx).colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  ctx,
                                ).colorScheme.primary.withAlpha(20),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _categoryIcon(t['category']?.toString() ?? ''),
                                color: Theme.of(ctx).colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t['description']?.toString() ?? '',
                                    style: Theme.of(ctx).textTheme.bodyMedium,
                                  ),
                                  Text(
                                    t['category']?.toString() ?? '其他',
                                    style: Theme.of(ctx).textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              CurrencyService.formatAmount(
                                (t['amount'] as num?)?.toDouble() ?? 0,
                                t['currency']?.toString() ?? 'TWD',
                              ),
                              style: Theme.of(
                                ctx,
                              ).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(ctx).colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (feedback.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: Theme.of(ctx).colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.smart_toy_rounded,
                              size: 16,
                              color:
                                  Theme.of(ctx).colorScheme.onTertiaryContainer,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                feedback,
                                style: Theme.of(ctx).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
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
                          child: FilledButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              // 保存所有交易
                              for (final tx in transactions) {
                                _saveTransaction(tx as Map<String, dynamic>);
                              }
                            },
                            child: Text('全部保存 (${transactions.length}筆)'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  IconData _categoryIcon(String category) {
    const map = {
      '餐飲': Icons.restaurant_rounded,
      '交通': Icons.directions_car_rounded,
      '購物': Icons.shopping_bag_rounded,
      '娛樂': Icons.sports_esports_rounded,
      '日用': Icons.home_rounded,
      '健康': Icons.favorite_rounded,
      '教育': Icons.school_rounded,
      '投資': Icons.trending_up_rounded,
      '薪資': Icons.account_balance_wallet_rounded,
    };
    return map[category] ?? Icons.receipt_rounded;
  }

  void _showConfirmationDialog(Map<String, dynamic> details) {
    showDialog(
      context: context,
      builder:
          (ctx) => Dialog(
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '確認交易',
                          style: Theme.of(ctx).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _DetailChip(
                      label: '金額',
                      value: 'NT\$ ${details['amount'] ?? 'N/A'}',
                      icon: Icons.attach_money_rounded,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _DetailChip(
                      label: '類別',
                      value: details['category']?.toString() ?? 'N/A',
                      icon: Icons.category_rounded,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _DetailChip(
                      label: '描述',
                      value: details['description']?.toString() ?? _finalText,
                      icon: Icons.description_rounded,
                    ),
                    if (_aiResponse.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: Theme.of(ctx).colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.smart_toy_rounded,
                              size: 18,
                              color:
                                  Theme.of(ctx).colorScheme.onTertiaryContainer,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                _aiResponse,
                                style: Theme.of(
                                  ctx,
                                ).textTheme.bodySmall?.copyWith(
                                  color:
                                      Theme.of(
                                        ctx,
                                      ).colorScheme.onTertiaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
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
                          child: FilledButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _saveTransaction(details);
                            },
                            child: const Text('確認保存'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Future<void> _saveTransaction(Map<String, dynamic> details) async {
    const uuid = Uuid();
    final amount = double.tryParse(details['amount']?.toString() ?? '0') ?? 0;

    final transaction = Transaction(
      id: uuid.v4(),
      userId: ref.read(currentUserIdProvider) ?? 'anonymous',
      amount: amount,
      type: TransactionType.expense,
      category: _parseCategory(details['category']?.toString() ?? ''),
      createdAt: DateTime.now(),
      description: details['description']?.toString() ?? _finalText,
      voiceTranscript: _finalText,
      notes: _aiResponse,
    );

    // 持久化到 Supabase / Mock
    try {
      final txService = ref.read(transactionServiceProvider);
      await txService.addTransaction(transaction);
    } catch (e) {
      // 本地暫存失敗不阻擋 UX
    }

    // 記錄語音使用次數
    try {
      final usageService = ref.read(usageServiceProvider);
      await usageService.recordVoiceUsage();
    } catch (_) {}

    // 餵食寵物 🐱
    final petFeedback = ref
        .read(petProvider.notifier)
        .feed(amount: amount.round());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('交易已保存！$petFeedback'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 2),
        ),
      );
      Future.delayed(const Duration(seconds: 1), () {
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
              '免費版每月可語音記帳 30 次。\n升級 Pro 即可無限使用語音記帳和 AI 秘書功能！',
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

  TransactionCategory _parseCategory(String categoryStr) {
    switch (categoryStr.toLowerCase()) {
      case '餐飲':
      case 'food':
        return TransactionCategory.food;
      case '交通':
      case 'transport':
        return TransactionCategory.transport;
      case '娛樂':
      case 'entertainment':
        return TransactionCategory.entertainment;
      case '購物':
      case 'shopping':
        return TransactionCategory.shopping;
      case '日用':
      case 'utilities':
        return TransactionCategory.utilities;
      case '健康':
      case 'health':
        return TransactionCategory.health;
      case '教育':
      case 'education':
        return TransactionCategory.education;
      case '投資':
      case 'investment':
        return TransactionCategory.investment;
      case '薪資':
      case 'salary':
        return TransactionCategory.salary;
      default:
        return TransactionCategory.other;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('語音記帳'),
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
                        '例如：「午餐便當 85 元」「搭計程車 250 塊」',
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
                          hintText: '或直接輸入：午餐 85 元',
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

/// 確認對話框中的資訊行
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
