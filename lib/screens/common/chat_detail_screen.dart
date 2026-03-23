import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/supabase_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/notification_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/loading_widget.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String chatId;

  const ChatDetailScreen({super.key, required this.chatId});

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;
  RealtimeChannel? _msgChannel;

  @override
  void initState() {
    super.initState();
    // Mark this chat as active so the shell suppresses its message notification
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(activeChatIdProvider.notifier).state = widget.chatId;
      }
      _subscribeToMessages();
    });
  }

  @override
  void dispose() {
    try {
      ref.read(activeChatIdProvider.notifier).state = null;
    } catch (_) {}
    _msgChannel?.unsubscribe();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Realtime: instantly receive messages from the other participant
  // ---------------------------------------------------------------------------
  void _subscribeToMessages() {
    _msgChannel = supabase
        .channel('chat_messages_${widget.chatId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: widget.chatId,
          ),
          callback: (payload) {
            if (!mounted) return;
            // Only react to messages sent by the other person
            final senderId = payload.newRecord['sender_id'] as String?;
            final myId = ref.read(currentUserIdProvider);
            if (senderId == myId) return; // we already appended our own message

            ref.invalidate(chatMessagesProvider(widget.chatId));
            // Scroll to bottom after re-render
            Future.delayed(const Duration(milliseconds: 250), () {
              if (mounted && _scrollCtrl.hasClients) {
                _scrollCtrl.animateTo(
                  _scrollCtrl.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOut,
                );
              }
            });
          },
        )
        .subscribe();
  }

  // ---------------------------------------------------------------------------
  // Send
  // ---------------------------------------------------------------------------
  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);

    try {
      await ref.read(
        sendMessageProvider(
          (chatId: widget.chatId, content: text, messageType: 'text'),
        ).future,
      );
      _msgCtrl.clear();
      ref.invalidate(chatMessagesProvider(widget.chatId));

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

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final chatOverviewAsync = ref.watch(chatOverviewProvider(widget.chatId));
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));
    final myUserId = ref.watch(currentUserIdProvider);

    final isClosed = chatOverviewAsync.valueOrNull?.isClosed ?? false;

    return Scaffold(
      appBar: AppBar(
        title: chatOverviewAsync.when(
          data: (chat) {
            if (chat == null) return const Text('Chat');
            final projectTitle = chat.jobTitle ?? 'Contract Chat';
            final otherParticipant = chat.otherUserName.trim().isEmpty
                ? 'Participant'
                : chat.otherUserName;
            return Text(
              '$projectTitle | $otherParticipant',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          },
          loading: () => const Text('Chat'),
          error: (_, __) => const Text('Chat'),
        ),
      ),
      body: Column(
        children: [
          chatOverviewAsync.when(
            data: (chat) {
              if (chat == null) return const SizedBox.shrink();
              final projectTitle = chat.jobTitle ?? 'Contract Chat';
              final otherParticipant = chat.otherUserName.trim().isEmpty
                  ? 'Participant'
                  : chat.otherUserName;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                color: Colors.grey.shade100,
                child: Text(
                  '$projectTitle | $otherParticipant',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          if (isClosed)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.orange.shade50,
              child: Row(
                children: [
                  Icon(Icons.lock_outline,
                      size: 16, color: Colors.orange.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This chat is closed. The contract has been completed.',
                      style: TextStyle(
                          fontSize: 13, color: Colors.orange.shade800),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: messagesAsync.when(
              loading: () =>
                  const LoadingWidget(message: 'Loading messages...'),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Failed to load messages:\n$error',
                      textAlign: TextAlign.center),
                ),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('No messages yet. Start the conversation.'),
                  );
                }
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe =
                        myUserId != null && msg.senderId == myUserId;
                    return _MessageBubble(
                      text: msg.content,
                      isMe: isMe,
                      time: Formatters.formatTime(msg.createdAt.toLocal()),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: isClosed
                ? const SizedBox.shrink()
                : Container(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                          top: BorderSide(color: Colors.grey.shade200)),
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
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _sending ? null : _sendMessage,
                          icon: _sending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Icon(Icons.send),
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
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.only(bottom: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? Colors.black87 : Colors.grey.shade100,
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
              style:
                  TextStyle(color: isMe ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
