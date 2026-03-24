import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_constants.dart';
import '../models/chat/chat_model.dart';
import '../models/chat/chat_overview_model.dart';
import '../models/chat/message_model.dart';
import '../repositories/chat_repository.dart';
import '../services/database_service.dart';
import 'auth_provider.dart';
import 'notification_provider.dart';

final chatRepositoryProvider = Provider((ref) => ChatRepository());

/// Get user's chats filtered by role
final userChatsProvider = FutureProvider.family<List<ChatModel>, String?>((ref, role) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final repo = ref.watch(chatRepositoryProvider);
  return repo.getUserChats(userId, role: role);
});

/// Get chat list with participant + last-message metadata for UI, filtered by role
final userChatOverviewsProvider = FutureProvider.family<List<ChatOverviewModel>, String?>((ref, role) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final repo = ref.watch(chatRepositoryProvider);
  return repo.getUserChatOverviews(userId, role: role);
});

/// Get a single chat overview by chat ID
final chatOverviewProvider = FutureProvider.family<ChatOverviewModel?, String>((ref, chatId) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final repo = ref.watch(chatRepositoryProvider);
  final allowed = await repo.isParticipant(chatId: chatId, userId: userId);
  if (!allowed) return null;
  return repo.getChatOverview(chatId: chatId, currentUserId: userId);
});

/// Get specific chat
final chatProvider = FutureProvider.family<ChatModel?, String>((ref, chatId) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  final repo = ref.watch(chatRepositoryProvider);
  final allowed = await repo.isParticipant(chatId: chatId, userId: userId);
  if (!allowed) return null;
  return repo.getChatById(chatId);
});

/// Get chat by job ID
final chatByJobProvider = FutureProvider.family<ChatModel?, String>((ref, jobId) async {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getChatByJobId(jobId);
});

final chatByContractProvider = FutureProvider.family<ChatModel?, String>((ref, contractId) async {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getChatByContractId(contractId);
});

/// Holds messages for one chat in memory so new messages can be injected
/// directly from Realtime payloads — no DB round-trip on cross-device updates.
class ChatMessagesNotifier extends FamilyAsyncNotifier<List<MessageModel>, String> {
  @override
  Future<List<MessageModel>> build(String chatId) async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return [];
    final repo = ref.watch(chatRepositoryProvider);
    final allowed = await repo.isParticipant(chatId: chatId, userId: userId);
    if (!allowed) return [];
    return repo.getChatMessages(chatId);
  }

  /// Append a message that arrived via Realtime — skips duplicates.
  void appendMessage(MessageModel message) {
    final current = state.valueOrNull;
    if (current == null) return; // still loading; the build() fetch will include it
    if (current.any((m) => m.id == message.id)) return;
    state = AsyncData([...current, message]);
  }
}

final chatMessagesProvider =
    AsyncNotifierProvider.family<ChatMessagesNotifier, List<MessageModel>, String>(
  ChatMessagesNotifier.new,
);

/// Create chat
final createChatProvider = FutureProvider.family<ChatModel, ({String contractId, String clientId, String providerId})>((ref, params) async {
  final repo = ref.watch(chatRepositoryProvider);
  final chat = await repo.createChat(
    contractId: params.contractId,
    clientId: params.clientId,
    providerId: params.providerId,
  );

  // Refresh user's chats
  ref.invalidate(userChatsProvider);
  ref.invalidate(userChatOverviewsProvider);
  ref.invalidate(chatByContractProvider(params.contractId));

  return chat;
});

/// Send message — also notifies the other participant.
final sendMessageProvider = FutureProvider.family<MessageModel, ({String chatId, String content, String messageType})>((ref, params) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) throw Exception('User not authenticated');

  final repo = ref.watch(chatRepositoryProvider);
  final allowed = await repo.isParticipant(chatId: params.chatId, userId: userId);
  if (!allowed) throw Exception('You are not a participant in this chat');
  final message = await repo.sendMessage(
    chatId: params.chatId,
    senderId: userId,
    content: params.content,
    messageType: params.messageType,
  );

  // Inject the confirmed message directly — no re-fetch needed
  ref.read(chatMessagesProvider(params.chatId).notifier).appendMessage(message);
  ref.invalidate(userChatsProvider);
  ref.invalidate(userChatOverviewsProvider);
  ref.invalidate(chatOverviewProvider(params.chatId));

  // ── Notification: tell the other participant about the new message ──
  try {
    final db = DatabaseService();
    final chatRows = await db.fetchData(
      table: 'chats',
      select: 'client_id,provider_id,contract_id',
      filters: {'id': params.chatId},
    );
    if (chatRows.isNotEmpty) {
      final clientId = chatRows.first['client_id'] as String?;
      final providerId = chatRows.first['provider_id'] as String?;
      final recipientId = (clientId == userId) ? providerId : clientId;
      final recipientRole = (recipientId == clientId) ? 'client' : 'provider';

      if (recipientId != null) {
        // Try to resolve job title for a richer notification
        String? jobTitle;
        final contractId = chatRows.first['contract_id'] as String?;
        if (contractId != null) {
          final contractRows = await db.fetchData(
            table: 'contracts',
            select: 'job_id',
            filters: {'id': contractId},
          );
          if (contractRows.isNotEmpty) {
            final jobId = contractRows.first['job_id'] as String?;
            if (jobId != null) {
              final jobRows = await db.fetchData(
                table: 'jobs',
                select: 'title',
                filters: {'id': jobId},
              );
              if (jobRows.isNotEmpty) {
                jobTitle = jobRows.first['title'] as String?;
              }
            }
          }
        }

        final preview = params.content.length > 80
            ? '${params.content.substring(0, 80)}...'
            : params.content;

        final notifRepo = ref.read(notificationRepositoryProvider);
        await notifRepo.createNotification(
          userId: recipientId,
          type: AppConstants.notifNewMessage,
          title: jobTitle != null ? 'Message - $jobTitle' : 'New Message',
          body: preview,
          data: {
            'chat_id': params.chatId,
            'role': recipientRole,
          },
        );
      }
    }
  } catch (_) {}

  return message;
});

/// Mark message as read
final markMessageAsReadProvider = FutureProvider.family<void, String>((ref, messageId) async {
  final repo = ref.watch(chatRepositoryProvider);
  await repo.markMessageAsRead(messageId);
});

/// Mark all messages in chat as read
final markChatAsReadProvider = FutureProvider.family<void, String>((ref, chatId) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return;

  final repo = ref.watch(chatRepositoryProvider);
  await repo.markChatAsRead(chatId, userId);

  // Refresh messages
  ref.invalidate(chatMessagesProvider(chatId));
  ref.invalidate(userChatOverviewsProvider);
});
