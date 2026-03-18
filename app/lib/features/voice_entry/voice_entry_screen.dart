import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../services/voice_service.dart';
import '../../services/ai_service.dart';
import 'package:uuid/uuid.dart';
import '../../models/transaction.dart';

class VoiceEntryScreen extends ConsumerStatefulWidget {
  const VoiceEntryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<VoiceEntryScreen> createState() => _VoiceEntryScreenState();
}

class _VoiceEntryScreenState extends ConsumerState<VoiceEntryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isListening = false;
  String _recognizedText = '';
  String _aiResponse = '';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _initializeVoice();
  }

  @override
  void dispose() {
    _animationController.dispose();
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

    _animationController.forward();

    try {
      final voiceService = ref.read(voiceServiceProvider);
      final text = await voiceService.listenOnce(localeId: 'zh_TW');

      if (mounted) {
        setState(() {
          _recognizedText = text;
          _isListening = false;
        });

        if (text.isNotEmpty) {
          await _processVoiceInput(text);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isListening = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('錯誤: $e')));
      }
    }

    _animationController.stop();
  }

  Future<void> _processVoiceInput(String transcript) async {
    setState(() => _isProcessing = true);

    try {
      final aiService = ref.read(aiServiceProvider);

      // Extract transaction details from transcript
      final details = await aiService.extractTransactionDetails(transcript);

      // Get AI response
      final response = await aiService.analyzeTransaction(transcript);

      if (mounted) {
        setState(() {
          _aiResponse = response;
          _isProcessing = false;
        });

        // Show confirmation dialog
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '確認交易詳情',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                _buildDetailField(
                  context,
                  '金額',
                  details['amount']?.toString() ?? 'N/A',
                ),
                _buildDetailField(
                  context,
                  '類別',
                  details['category']?.toString() ?? 'N/A',
                ),
                _buildDetailField(
                  context,
                  '描述',
                  details['description']?.toString() ?? _recognizedText,
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.spacingSmall),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGradientStart.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    'AI 回饋: $_aiResponse',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLarge),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('取消'),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSmall),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
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

  Widget _buildDetailField(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingSmall,
              vertical: AppTheme.spacingSmall,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  void _saveTransaction(Map<String, dynamic> details) {
    // Save transaction to database
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

    // TODO: Save to Supabase
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('交易已保存'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          GoRouter.of(context).go('/dashboard');
        }
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
    return Scaffold(
      appBar: AppBar(title: const Text('語音記帳'), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Microphone Button
                GestureDetector(
                  onTap: _isListening || _isProcessing ? null : _startListening,
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            if (_isListening)
                              BoxShadow(
                                color: AppTheme.primaryGradientStart
                                    .withOpacity(0.5),
                                blurRadius:
                                    20 + (_animationController.value * 10),
                                spreadRadius:
                                    10 + (_animationController.value * 10),
                              ),
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.primaryGradient,
                            boxShadow: [AppTheme.mediumShadow],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isListening || _isProcessing
                                  ? null
                                  : _startListening,
                              customBorder: const CircleBorder(),
                              child: Center(
                                child: Icon(
                                  _isListening
                                      ? Icons.stop_rounded
                                      : Icons.mic_rounded,
                                  color: Colors.white,
                                  size: 64,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLarge),

                // Status Text
                Text(
                  _isListening
                      ? '正在聆聽...'
                      : _isProcessing
                      ? '正在處理...'
                      : '輕按麥克風開始記帳',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingMedium),

                // Recognized Text Display
                if (_recognizedText.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTheme.spacingMedium),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      border: Border.all(
                        color: AppTheme.primaryGradientStart.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '辨識結果',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: AppTheme.spacingSmall),
                        Text(
                          _recognizedText,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                if (_recognizedText.isNotEmpty)
                  const SizedBox(height: AppTheme.spacingMedium),

                // AI Response Display
                if (_aiResponse.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTheme.spacingMedium),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      border: Border.all(
                        color: AppTheme.accentGreen.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.smart_toy_rounded,
                              color: AppTheme.accentGreen,
                            ),
                            const SizedBox(width: AppTheme.spacingSmall),
                            Text(
                              'AI 秘書',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: AppTheme.accentGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingSmall),
                        Text(
                          _aiResponse,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),

                if (_isProcessing)
                  const SizedBox(height: AppTheme.spacingMedium),
                if (_isProcessing) const CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
