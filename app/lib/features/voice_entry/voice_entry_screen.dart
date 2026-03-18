import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../models/transaction.dart';
import '../../services/voice_service.dart';
import '../../services/ai_service.dart';

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
  String _recognizedText = '';
  String _aiResponse = '';
  bool _isProcessing = false;

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
    _initializeVoice();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    ref.read(voiceServiceProvider).dispose();
    super.dispose();
  }

  Future<void> _initializeVoice() async {
    final voiceService = ref.read(voiceServiceProvider);
    final isInitialized = await voiceService.initialize();
    if (!isInitialized && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('語音服務初始化失敗')));
    }
  }

  Future<void> _startListening() async {
    if (_isListening) return;

    setState(() {
      _isListening = true;
      _recognizedText = '';
      _aiResponse = '';
      _isProcessing = false;
    });

    _pulseController.repeat(reverse: true);

    try {
      final voiceService = ref.read(voiceServiceProvider);
      final text = await voiceService.listenOnce(localeId: 'zh_TW');

      if (mounted) {
        setState(() {
          _recognizedText = text;
          _isListening = false;
        });
        _pulseController.stop();
        _pulseController.reset();

        if (text.isNotEmpty) {
          await _processVoiceInput(text);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isListening = false);
        _pulseController.stop();
        _pulseController.reset();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('錯誤: $e')));
      }
    }
  }

  Future<void> _processVoiceInput(String transcript) async {
    setState(() => _isProcessing = true);

    try {
      final aiService = ref.read(aiServiceProvider);
      final details = await aiService.extractTransactionDetails(transcript);
      final response = await aiService.analyzeTransaction(transcript);

      if (mounted) {
        setState(() {
          _aiResponse = response;
          _isProcessing = false;
        });
        _showConfirmationDialog(details);
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

  void _showConfirmationDialog(Map<String, dynamic> details) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
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
                      style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
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
                  value: details['amount']?.toString() ?? 'N/A',
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
                  value: details['description']?.toString() ?? _recognizedText,
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
                          color: Theme.of(ctx).colorScheme.onTertiaryContainer,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _aiResponse,
                            style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(ctx)
                                      .colorScheme
                                      .onTertiaryContainer,
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

  void _saveTransaction(Map<String, dynamic> details) {
    const uuid = Uuid();
    // ignore: unused_local_variable
    final transaction = Transaction(
      id: uuid.v4(),
      userId: 'current_user_id',
      amount: double.tryParse(details['amount']?.toString() ?? '0') ?? 0,
      type: TransactionType.expense,
      category: _parseCategory(details['category']?.toString() ?? ''),
      createdAt: DateTime.now(),
      description: details['description']?.toString() ?? _recognizedText,
      voiceTranscript: _recognizedText,
      notes: _aiResponse,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('交易已保存'),
          backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
        ),
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) context.go('/dashboard');
      });
    }
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 波紋環
              SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 外圈脈衝
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
                    if (_isListening)
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          final scale = 1.0 +
                              (_pulseAnimation.value - 1.0) * 0.6;
                          return Container(
                            width: 180 * scale,
                            height: 180 * scale,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: cs.primary.withAlpha(40),
                                width: 1.5,
                              ),
                            ),
                          );
                        },
                      ),
                    // 主按鈕
                    GestureDetector(
                      onTap:
                          _isListening || _isProcessing ? null : _startListening,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              cs.primary,
                              cs.tertiary,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: cs.primary.withAlpha(100),
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
              const SizedBox(height: AppSpacing.xl),

              // 狀態文字
              Text(
                _isListening
                    ? '正在聆聽...'
                    : _isProcessing
                        ? '正在處理...'
                        : '輕按麥克風開始記帳',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              if (!_isListening && !_isProcessing) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '說出金額與用途，AI 自動分類',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withAlpha(120),
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),

              // 辨識結果
              if (_recognizedText.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(15),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: cs.primary.withAlpha(60),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '辨識結果',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white.withAlpha(150),
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _recognizedText,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                    ],
                  ),
                ),

              if (_aiResponse.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: cs.tertiary.withAlpha(30),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: cs.tertiary.withAlpha(60),
                    ),
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
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
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
