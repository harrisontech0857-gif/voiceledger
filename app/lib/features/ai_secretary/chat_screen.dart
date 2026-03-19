import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../services/ai_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

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
    setState(() {
      _messages = [
        ChatMessage(
          id: '0',
          content: '你好！我是你的 AI 財務秘書 🤖\n有什麼我可以幫助的嗎？',
          isUser: false,
          timestamp: DateTime.now(),
          suggestion: '幫我分析這個月的支出',
        ),
      ];
    });
  }

  Future<void> _sendMessage(String content) async {
    if (content.isEmpty || _isSending) return;

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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.smart_toy_rounded,
                size: 18,
                color: cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text('AI 財務秘書'),
          ],
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 訊息列表
          Expanded(
            child: _messages.isEmpty
                ? _EmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    itemCount: _messages.length + (_isSending ? 1 : 0),
                    itemBuilder: (context, index) {
                      // 打字指示器
                      if (_isSending && index == _messages.length) {
                        return const _TypingIndicator();
                      }
                      final message = _messages[index];
                      return _ChatBubble(
                        message: message,
                        isUser: message.isUser,
                      );
                    },
                  ),
          ),

          // 快速回覆
          if (_messages.isNotEmpty &&
              !_messages.last.isUser &&
              _messages.last.suggestion != null &&
              !_isSending)
            _QuickReplies(
              suggestions: [_messages.last.suggestion ?? '', '顯示支出報告', '設定預算'],
              onTap: _sendMessage,
            ),

          // 輸入區
          _InputBar(
            controller: _messageController,
            isSending: _isSending,
            onSend: () => _sendMessage(_messageController.text.trim()),
            onSubmitted: _sendMessage,
          ),
        ],
      ),
    );
  }
}

/// 空狀態
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 56,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '開始對話',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// 打字中指示器
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppRadius.lg),
              topRight: Radius.circular(AppRadius.lg),
              bottomRight: Radius.circular(AppRadius.lg),
              bottomLeft: Radius.circular(4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Dot(delay: 0),
              const SizedBox(width: 4),
              _Dot(delay: 150),
              const SizedBox(width: 4),
              _Dot(delay: 300),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

/// 快速回覆列
class _QuickReplies extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onTap;

  const _QuickReplies({required this.suggestions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: suggestions.length,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (context, index) {
            return ActionChip(
              onPressed: () => onTap(suggestions[index]),
              label: Text(
                suggestions[index],
                style: Theme.of(context).textTheme.labelSmall,
              ),
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primaryContainer.withAlpha(100),
              side: BorderSide(
                color: Theme.of(context).colorScheme.primary.withAlpha(60),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            );
          },
        ),
      ),
    );
  }
}

/// 聊天氣泡
class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isUser;

  const _ChatBubble({required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    final cs = Theme.of(context).colorScheme;

    // 不同的圓角：自己的訊息右下較小，AI 的訊息左下較小
    final borderRadius = isUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(AppRadius.lg),
            topRight: Radius.circular(AppRadius.lg),
            bottomLeft: Radius.circular(AppRadius.lg),
            bottomRight: Radius.circular(4),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(AppRadius.lg),
            topRight: Radius.circular(AppRadius.lg),
            bottomRight: Radius.circular(AppRadius.lg),
            bottomLeft: Radius.circular(4),
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: cs.primaryContainer,
              child: Icon(
                Icons.smart_toy_rounded,
                size: 14,
                color: cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? cs.primary : cs.surfaceContainerLow,
                    borderRadius: borderRadius,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 10,
                  ),
                  child: Text(
                    message.content,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isUser ? Colors.white : null,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeFormat.format(message.timestamp),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 輸入欄
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;
  final ValueChanged<String> onSubmitted;

  const _InputBar({
    required this.controller,
    required this.isSending,
    required this.onSend,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: cs.outlineVariant.withAlpha(80))),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !isSending,
                maxLines: null,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: '輸入訊息...',
                  hintStyle: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: cs.surfaceContainerLow,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 10,
                  ),
                ),
                onSubmitted: onSubmitted,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [cs.primary, cs.tertiary]),
                shape: BoxShape.circle,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isSending ? null : onSend,
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: isSending
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
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
    );
  }
}
