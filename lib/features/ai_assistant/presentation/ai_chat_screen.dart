import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../data/ai_chat_notifier.dart';
import '../data/chat_message.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await ref.read(aiChatNotifierProvider.notifier).sendMessage(text);
    // Scroll to bottom after send
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    final chatAsync = ref.watch(aiChatNotifierProvider);
    final messages = chatAsync.valueOrNull ?? [];
    final isLoading = chatAsync.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('AI Assistant')),
      body: Column(
        children: [
          const _DisclaimerBanner(),
          Expanded(
            child: messages.isEmpty && !isLoading
                ? Center(
                    child: Text(
                      'Ask me anything about your cycle or health.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding:
                        const EdgeInsets.all(AppSpacing.screenPadding),
                    itemCount:
                        messages.length + (isLoading ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == messages.length) {
                        // Typing indicator
                        return const _TypingIndicator();
                      }
                      return _MessageBubble(msg: messages[i]);
                    },
                  ),
          ),
          _InputBar(controller: _controller, onSend: _send),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.2)),
        ),
        child: const SizedBox(
          width: 40,
          child: LinearProgressIndicator(minHeight: 3),
        ),
      ),
    );
  }
}

class _DisclaimerBanner extends StatelessWidget {
  const _DisclaimerBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      color: AppColors.accent.withValues(alpha: 0.15),
      child: Text(
        '⚠️ AI responses are not medical advice. Consult a doctor for medical concerns.',
        style: Theme.of(context).textTheme.bodySmall,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.msg});
  final ChatMessage msg;

  @override
  Widget build(BuildContext context) {
    final isUser = msg.isUser;
    final theme = Theme.of(context);
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: isUser ? null : Border.all(color: AppColors.divider),
        ),
        child: Text(
          msg.content,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isUser ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({required this.controller, required this.onSend});
  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Ask a health question…',
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filled(
              icon: const Icon(Icons.send),
              onPressed: onSend,
            ),
          ],
        ),
      ),
    );
  }
}
