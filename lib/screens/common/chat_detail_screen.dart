import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/loading_widget.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String? initialTitle;

  const ChatDetailScreen({super.key, required this.chatId, this.initialTitle});

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);

    try {
      await ref
          .read(
            sendMessageProvider(
              (chatId: widget.chatId, content: text, messageType: 'text'),
            ).future,
          )
          .then((_) {
        _msgCtrl.clear();
        ref.invalidate(chatMessagesProvider(widget.chatId));
      });

      if (!mounted) return;

      await Future.delayed(const Duration(milliseconds: 60));
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatOverviewAsync = ref.watch(chatOverviewProvider(widget.chatId));
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));
    final myUserId = ref.watch(currentUserIdProvider);

    final isClosed = chatOverviewAsync.valueOrNull?.isClosed ?? false;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: chatOverviewAsync.when(
          data: (chat) {
            if (chat == null) {
              return Text(widget.initialTitle ?? 'Chat', style: AppTypography.heading4.copyWith(color: AppColors.textPrimary));
            }
            final projectTitle = chat.jobTitle ?? 'Contract Chat';
            return Text(
              projectTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
            );
          },
          loading: () => Text(widget.initialTitle ?? 'Chat', style: AppTypography.heading4.copyWith(color: AppColors.textPrimary)),
          error: (_, __) => Text(widget.initialTitle ?? 'Chat', style: AppTypography.heading4.copyWith(color: AppColors.textPrimary)),
        ),
      ),
      body: Column(
        children: [
          // Closed notice
          if (isClosed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.warningLight,
              child: Row(
                children: [
                  Icon(Icons.lock_outline, size: 16, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This chat is closed. The contract is no longer active.',
                      style: AppTypography.caption.copyWith(color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: messagesAsync.when(
              loading: () => const LoadingWidget(message: 'Loading messages...'),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Failed to load messages:\n$error', textAlign: TextAlign.center, style: TextStyle(color: AppColors.error)),
                ),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  if (isClosed) {
                    return Center(
                      child: Text('This conversation is closed.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textHint)),
                    );
                  }
                  return Center(
                    child: Text('No messages yet. Start the conversation.', style: AppTypography.bodyMedium.copyWith(color: AppColors.textHint)),
                  );
                }

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = myUserId != null && msg.senderId == myUserId;

                    return _MessageBubble(
                      text: msg.content,
                      isMe: isMe,
                      time: Formatters.formatTime(msg.createdAt),
                    );
                  },
                );
              },
            ),
          ),
          // Input bar
          SafeArea(
            top: false,
            child: isClosed
                ? const SizedBox.shrink()
                : Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textHint),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(color: AppColors.borderFocus),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sending ? null : _sendMessage,
                    icon: _sending
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryColor),
                          )
                        : Icon(Icons.send, color: AppColors.primaryColor),
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

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String time;

  const _MessageBubble({
    required this.text,
    required this.isMe,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primaryColor : AppColors.surfaceVariant,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isMe ? 14 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 14),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                color: isMe ? AppColors.textDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: AppTypography.captionSmall.copyWith(
                color: isMe ? AppColors.textDark.withValues(alpha: 0.6) : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
