import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat/chat_model.dart';
import '../models/chat/chat_overview_model.dart';
import '../models/chat/message_model.dart';
import '../repositories/chat_repository.dart';
import 'auth_provider.dart';

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

/// Get messages for chat
final chatMessagesProvider = FutureProvider.family<List<MessageModel>, String>((ref, chatId) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  final repo = ref.watch(chatRepositoryProvider);
  final allowed = await repo.isParticipant(chatId: chatId, userId: userId);
  if (!allowed) return [];
  return repo.getChatMessages(chatId);
});

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

/// Send message
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
  
  // Refresh messages
  ref.invalidate(chatMessagesProvider(params.chatId));
  ref.invalidate(userChatsProvider);
  ref.invalidate(userChatOverviewsProvider);
  ref.invalidate(chatOverviewProvider(params.chatId));
  
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
