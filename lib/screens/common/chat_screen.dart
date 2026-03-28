import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/chat_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';
import 'chat_detail_screen.dart';

class ChatScreen extends ConsumerWidget {
  final String? role;
  const ChatScreen({super.key, this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(userChatOverviewsProvider(role));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Chats', style: AppTypography.heading4.copyWith(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryColor,
        backgroundColor: AppColors.surfaceLight,
        onRefresh: () async {
          ref.invalidate(userChatOverviewsProvider(role));
          await ref.read(userChatOverviewsProvider(role).future);
        },
        child: chatsAsync.when(
          loading: () => const LoadingWidget(message: 'Loading chats...'),
          error: (error, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Center(
                  child: Text(
                    'Failed to load chats:\n$error',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ),
            ],
          ),
          data: (chats) {
            if (chats.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(
                    height: 500,
                    child: EmptyStateWidget(
                      message: 'No chats yet.\nChats appear after a project bid is accepted.',
                      icon: Icons.chat_bubble_outline,
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: chats.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.divider),
              itemBuilder: (context, index) {
                final chat = chats[index];
                final projectTitle = chat.jobTitle ?? 'Contract Chat';
                final otherParticipant = chat.otherUserName.trim().isEmpty
                    ? 'Participant'
                    : chat.otherUserName;
                final title = projectTitle;
                final subtitle = chat.lastMessage?.trim().isNotEmpty == true
                    ? chat.lastMessage!
                  : (chat.isClosed ? 'Conversation closed' : 'No messages yet');

                return Container(
                  color: AppColors.surfaceLight,
                  child: ListTile(
                    isThreeLine: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatDetailScreen(
                            chatId: chat.chatId,
                            initialTitle: title,
                          ),
                        ),
                      );
                    },
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.accentGradient,
                      ),
                      child: Center(
                        child: Text(
                          _initials(chat.otherUserName),
                          style: AppTypography.labelMedium.copyWith(color: AppColors.textPrimary),
                        ),
                      ),
                    ),
                    title: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Row(
                      children: [
                        if (chat.isClosed) ...[
                          Icon(Icons.lock_outline, size: 14, color: AppColors.textHint),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            '$otherParticipant • $subtitle',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    trailing: chat.lastMessageAt == null
                        ? null
                        : Text(
                            Formatters.formatChatTimestamp(chat.lastMessageAt!),
                            style: AppTypography.captionSmall.copyWith(color: AppColors.textHint),
                          ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
