import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../services/ai_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  late TextEditingController _messageController;
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _loadInitialGreeting();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadInitialGreeting() {
    // Add initial greeting from AI
    setState(() {
      _messages = [
        ChatMessage(
          id: '0',
          content: '你好！我是妳的 AI 財務秘書。有什麼我可以幫助的嗎？',
          isUser: false,
          timestamp: DateTime.now(),
          suggestion: '幫我分析這個月的支出',
        ),
      ];
    });
  }

  Future<void> _sendMessage(String content) async {
    if (content.isEmpty || _isSending) return;

    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isSending = true;
      _messageController.clear();
    });

    _scrollToBottom();

    try {
      final aiService = ref.read(aiServiceProvider);
      final response = await aiService.sendMessage(content, _messages);

      if (mounted) {
        setState(() {
          _messages.add(response);
          _isSending = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('錯誤: $e')));
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 財務秘書'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 64,
                          color: Colors.grey.withOpacity(0.3),
                        ),
                        const SizedBox(height: AppTheme.spacingMedium),
                        Text(
                          '開始對話',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppTheme.spacingMedium),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _ChatBubble(
                        message: message,
                        isUser: message.isUser,
                      );
                    },
                  ),
          ),

          // Message Input Area
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(color: Colors.grey.withOpacity(0.1)),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMedium,
              vertical: AppTheme.spacingSmall,
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Suggestions
                  if (_messages.isNotEmpty &&
                      _messages.last.suggestion != null &&
                      !_messages.last.isUser)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppTheme.spacingSmall,
                      ),
                      child: SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: 3,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: AppTheme.spacingSmall),
                          itemBuilder: (context, index) {
                            final suggestions = [
                              _messages.last.suggestion ?? '',
                              '顯示我的支出報告',
                              '設定月度預算',
                            ];
                            return ActionChip(
                              onPressed: () {
                                _sendMessage(suggestions[index]);
                              },
                              label: Text(
                                suggestions[index],
                                style: Theme.of(
                                  context,
                                ).textTheme.labelSmall?.copyWith(fontSize: 11),
                              ),
                              backgroundColor: AppTheme.primaryGradientStart
                                  .withOpacity(0.1),
                              side: BorderSide(
                                color: AppTheme.primaryGradientStart
                                    .withOpacity(0.3),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  // Input Field
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          enabled: !_isSending,
                          maxLines: null,
                          minLines: 1,
                          decoration: InputDecoration(
                            hintText: '輸入訊息...',
                            hintStyle: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusXLarge,
                              ),
                              borderSide: const BorderSide(
                                color: AppTheme.lightBorder,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusXLarge,
                              ),
                              borderSide: const BorderSide(
                                color: AppTheme.lightBorder,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusXLarge,
                              ),
                              borderSide: const BorderSide(
                                color: AppTheme.primaryGradientStart,
                                width: 2,
                              ),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusXLarge,
                              ),
                              borderSide: BorderSide(
                                color: Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingMedium,
                              vertical: AppTheme.spacingSmall,
                            ),
                            filled: true,
                            fillColor: Theme.of(
                              context,
                            ).colorScheme.surfaceVariant,
                          ),
                          onSubmitted: (value) {
                            _sendMessage(value);
                          },
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingSmall),
                      Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusXLarge,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isSending
                                ? null
                                : () {
                                    _sendMessage(
                                      _messageController.text.trim(),
                                    );
                                  },
                            customBorder: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusXLarge,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                AppTheme.spacingSmall,
                              ),
                              child: _isSending
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.send_rounded,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isUser;

  const _ChatBubble({required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? AppTheme.primaryGradientStart
                    : Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMedium,
                vertical: AppTheme.spacingSmall,
              ),
              child: Text(
                message.content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isUser ? Colors.white : null,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              timeFormat.format(message.timestamp),
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
