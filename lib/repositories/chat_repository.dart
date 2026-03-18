import '../models/chat/chat_model.dart';
import '../models/chat/message_model.dart';
import '../models/chat/chat_overview_model.dart';
import '../services/database_service.dart';
import '../utils/exceptions.dart';
import '../utils/app_logger.dart';

class ChatRepository {
  final _databaseService = DatabaseService();

  dynamic _asIso(dynamic value) {
    if (value is DateTime) return value.toIso8601String();
    return value;
  }

  Future<String?> _resolveJobIdForContract(String contractId) async {
    final rows = await _databaseService.fetchData(
      table: 'contracts',
      select: 'job_id',
      filters: {'id': contractId},
    );
    if (rows.isEmpty) return null;
    return rows.first['job_id'] as String?;
  }

  Future<Map<String, dynamic>> _mapChatRow(Map<String, dynamic> row) async {
    final contractId = row['contract_id'] as String?;
    final jobId = contractId == null ? null : await _resolveJobIdForContract(contractId);
    return {
      'id': row['id'],
      'jobId': jobId ?? '',
      'contractId': contractId,
      'lastMessageAt': _asIso(row['last_message_at']),
      'createdAt': _asIso(row['created_at']),
      'updatedAt': _asIso(row['updated_at']),
    };
  }

  Map<String, dynamic> _mapMessageRow(Map<String, dynamic> row) {
    return {
      'id': row['id'],
      'chatId': row['chat_id'],
      'senderId': row['sender_id'],
      'content': row['content'],
      'messageType': row['message_type'] ?? 'text',
      'isRead': row['is_read'] ?? false,
      'createdAt': _asIso(row['created_at']),
    };
  }

  /// Create chat for contract
  Future<ChatModel> createChat({
    required String contractId,
    required String clientId,
    required String providerId,
  }) async {
    try {
      if (clientId == providerId) {
        throw AppException(message: 'Client and provider must be different users');
      }

      final result = await _databaseService.insertData(
        table: 'chats',
        data: {
          'contract_id': contractId,
          'client_id': clientId,
          'provider_id': providerId,
        },
      );

      final chat = ChatModel.fromJson(await _mapChatRow(result));
      return chat;
    } catch (e) {
      AppLogger.logError('Create chat failed for contractId: $contractId', e);
      throw AppException(
        message: 'Create chat failed: $e',
        originalException: e,
      );
    }
  }

  Future<ChatModel> ensureContractChat({
    required String contractId,
    required String clientId,
    required String providerId,
  }) async {
    if (clientId == providerId) {
      throw AppException(message: 'Client and provider must be different users');
    }

    final existing = await getChatByContractId(contractId);
    if (existing != null) return existing;
    return createChat(
      contractId: contractId,
      clientId: clientId,
      providerId: providerId,
    );
  }

  /// Get chat by ID
  Future<ChatModel?> getChatById(String chatId) async {
    try {
      final result = await _databaseService.fetchData(
        table: 'chats',
        filters: {'id': chatId},
      );
      if (result.isEmpty) return null;
      return ChatModel.fromJson(await _mapChatRow(result.first));
    } catch (e) {
      AppLogger.logError('Get chat failed for chatId: $chatId', e);
      throw AppException(
        message: 'Get chat failed: $e',
        originalException: e,
      );
    }
  }

  /// Get chat by job ID
  Future<ChatModel?> getChatByJobId(String jobId) async {
    try {
      final contracts = await _databaseService.fetchData(
        table: 'contracts',
        select: 'id',
        filters: {'job_id': jobId},
      );
      if (contracts.isEmpty) return null;

      final contractId = contracts.first['id'] as String?;
      if (contractId == null) return null;

      final chatRows = await _databaseService.fetchData(
        table: 'chats',
        filters: {'contract_id': contractId},
      );
      if (chatRows.isEmpty) return null;
      return ChatModel.fromJson(await _mapChatRow(chatRows.first));
    } catch (e) {
      AppLogger.logError('Get chat by job failed for jobId: $jobId', e);
      throw AppException(
        message: 'Get chat by job failed: $e',
        originalException: e,
      );
    }
  }

  Future<ChatModel?> getChatByContractId(String contractId) async {
    try {
      final result = await _databaseService.fetchData(
        table: 'chats',
        filters: {'contract_id': contractId},
      );
      if (result.isEmpty) return null;
      return ChatModel.fromJson(await _mapChatRow(result.first));
    } catch (e) {
      AppLogger.logError('Get chat by contract failed for contractId: $contractId', e);
      throw AppException(
        message: 'Get chat by contract failed: $e',
        originalException: e,
      );
    }
  }

  /// Get user's chats filtered by role
  Future<List<ChatModel>> getUserChats(String userId, {String? role}) async {
    try {
      final result = await _databaseService.fetchData(
        table: 'chats',
        orderBy: 'last_message_at',
        descending: true,
      );

      final userChats = result.where((chat) {
        final clientId = chat['client_id'] as String?;
        final providerId = chat['provider_id'] as String?;
        if (role == 'client') return clientId == userId;
        if (role == 'provider') return providerId == userId;
        return clientId == userId || providerId == userId;
      }).toList();

      final mapped = await Future.wait(
        userChats.map((row) async => ChatModel.fromJson(await _mapChatRow(row))),
      );
      return mapped;
    } catch (e) {
      AppLogger.logError('Get user chats failed for userId: $userId', e);
      throw AppException(
        message: 'Get user chats failed: $e',
        originalException: e,
      );
    }
  }

  /// Send message
  Future<MessageModel> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
    String messageType = 'text',
  }) async {
    try {
      // Check if chat is closed
      final chatRows = await _databaseService.fetchData(
        table: 'chats',
        filters: {'id': chatId},
      );
      if (chatRows.isNotEmpty && chatRows.first['closed_at'] != null) {
        throw AppException(message: 'This chat is closed. No new messages can be sent.');
      }

      // Insert message
      final result = await _databaseService.insertData(
        table: 'messages',
        data: {
          'chat_id': chatId,
          'sender_id': senderId,
          'content': content,
          'message_type': messageType,
        },
      );

      final message = MessageModel.fromJson(_mapMessageRow(result));

      // Update chat's last_message_at
      await _databaseService.updateData(
        table: 'chats',
        data: {'last_message_at': DateTime.now().toIso8601String()},
        id: chatId,
      );

      return message;
    } catch (e) {
      AppLogger.logError('Send message failed for chatId: $chatId', e);
      throw AppException(
        message: 'Send message failed: $e',
        originalException: e,
      );
    }
  }

  /// Get messages for chat
  Future<List<MessageModel>> getChatMessages(String chatId, {int limit = 50, int offset = 0}) async {
    try {
      final result = await _databaseService.fetchData(
        table: 'messages',
        filters: {'chat_id': chatId},
        orderBy: 'created_at',
        descending: true,
        limit: limit,
        offset: offset,
      );
      // Reverse to get chronological order
      return result.map((e) => MessageModel.fromJson(_mapMessageRow(e))).toList().reversed.toList();
    } catch (e) {
      AppLogger.logError('Get chat messages failed for chatId: $chatId', e);
      throw AppException(
        message: 'Get chat messages failed: $e',
        originalException: e,
      );
    }
  }

  /// Mark message as read
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _databaseService.updateData(
        table: 'messages',
        data: {'is_read': true},
        id: messageId,
      );
    } catch (e) {
      AppLogger.logError('Mark message as read failed for messageId: $messageId', e);
      throw AppException(
        message: 'Mark message as read failed: $e',
        originalException: e,
      );
    }
  }

  /// Mark all messages in chat as read
  Future<void> markChatAsRead(String chatId, String userId) async {
    try {
      final messages = await getChatMessages(chatId);
      for (final message in messages) {
        if (!message.isRead && message.senderId != userId) {
          await markMessageAsRead(message.id);
        }
      }
    } catch (e) {
      AppLogger.logError('Mark chat as read failed for chatId: $chatId', e);
      throw AppException(
        message: 'Mark chat as read failed: $e',
        originalException: e,
      );
    }
  }

  /// Check if user is a participant (client or provider) in the chat
  Future<bool> isParticipant({
    required String chatId,
    required String userId,
  }) async {
    try {
      final result = await _databaseService.fetchData(
        table: 'chats',
        filters: {'id': chatId},
      );
      if (result.isEmpty) return false;
      
      final chat = result.first;
      final clientId = chat['client_id'] as String?;
      final providerId = chat['provider_id'] as String?;
      
      return clientId == userId || providerId == userId;
    } catch (e) {
      AppLogger.logError('Check participant failed for chatId: $chatId, userId: $userId', e);
      return false;
    }
  }

  /// Get a single chat overview for the current user
  Future<ChatOverviewModel?> getChatOverview({
    required String chatId,
    required String currentUserId,
  }) async {
    try {
      final chatRows = await _databaseService.fetchData(
        table: 'chats',
        filters: {'id': chatId},
      );
      if (chatRows.isEmpty) return null;
      
      final chatRow = chatRows.first;
      final clientId = chatRow['client_id'] as String?;
      final providerId = chatRow['provider_id'] as String?;
      final closedAtRaw = chatRow['closed_at'];
      DateTime? closedAt;
      if (closedAtRaw != null) {
        closedAt = closedAtRaw is DateTime ? closedAtRaw : DateTime.tryParse(closedAtRaw.toString());
      }
      
      // Determine who the "other" participant is
      final otherUserId = (clientId == currentUserId) ? providerId : clientId;
      if (otherUserId == null) return null;

      final chat = ChatModel.fromJson(await _mapChatRow(chatRow));
      
      String otherName = 'User';
      String? otherAvatar;
      final profileRows = await _databaseService.fetchData(
        table: 'profiles',
        select: 'full_name,avatar_url',
        filters: {'id': otherUserId},
      );
      if (profileRows.isNotEmpty) {
        otherName = (profileRows.first['full_name'] as String?) ?? 'User';
        otherAvatar = profileRows.first['avatar_url'] as String?;
      }

      // Fetch both participant names for display
      String clientName = 'Client';
      String providerName = 'Provider';
      if (clientId != null) {
        final cRows = await _databaseService.fetchData(
          table: 'profiles',
          select: 'full_name',
          filters: {'id': clientId},
        );
        if (cRows.isNotEmpty) {
          clientName = (cRows.first['full_name'] as String?) ?? 'Client';
        }
      }
      if (providerId != null) {
        final pRows = await _databaseService.fetchData(
          table: 'profiles',
          select: 'full_name',
          filters: {'id': providerId},
        );
        if (pRows.isNotEmpty) {
          providerName = (pRows.first['full_name'] as String?) ?? 'Provider';
        }
      }

      String? jobTitle;
      if (chat.jobId.isNotEmpty) {
        final jobRows = await _databaseService.fetchData(
          table: 'jobs',
          select: 'title',
          filters: {'id': chat.jobId},
        );
        if (jobRows.isNotEmpty) {
          jobTitle = jobRows.first['title'] as String?;
        }
      }

      final messageRows = await _databaseService.fetchData(
        table: 'messages',
        select: 'content,created_at',
        filters: {'chat_id': chat.id},
        orderBy: 'created_at',
        descending: true,
        limit: 1,
        offset: 0,
      );

      String? lastMessage;
      DateTime? lastMessageAt = chat.lastMessageAt;
      if (messageRows.isNotEmpty) {
        lastMessage = messageRows.first['content'] as String?;
        final rawDate = messageRows.first['created_at'] as String?;
        if (rawDate != null) {
          lastMessageAt = DateTime.tryParse(rawDate)?.toLocal();
        }
      }

      return ChatOverviewModel(
        chatId: chat.id,
        jobId: chat.jobId,
        contractId: chat.contractId,
        otherUserId: otherUserId,
        otherUserName: otherName,
        otherUserAvatarUrl: otherAvatar,
        jobTitle: jobTitle,
        lastMessage: lastMessage,
        lastMessageAt: lastMessageAt,
        clientName: clientName,
        providerName: providerName,
        closedAt: closedAt,
      );
    } catch (e) {
      AppLogger.logError('Get chat overview failed for chatId: $chatId', e);
      throw AppException(
        message: 'Get chat overview failed: $e',
        originalException: e,
      );
    }
  }

  /// Get all chat overviews for a user, optionally filtered by role
  Future<List<ChatOverviewModel>> getUserChatOverviews(String userId, {String? role}) async {
    try {
      final chats = await getUserChats(userId, role: role);
      if (chats.isEmpty) return const [];

      final List<ChatOverviewModel> overviews = [];
      for (final chat in chats) {
        final overview = await getChatOverview(
          chatId: chat.id,
          currentUserId: userId,
        );
        if (overview != null) {
          overviews.add(overview);
        }
      }

      overviews.sort((a, b) {
        final aTime = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      return overviews;
    } catch (e) {
      AppLogger.logError('Get chat overviews failed for userId: $userId', e);
      throw AppException(
        message: 'Get chat overviews failed: $e',
        originalException: e,
      );
    }
  }

  /// Close the chat associated with a contract
  Future<void> closeChatByContract(String contractId) async {
    try {
      final chatRows = await _databaseService.fetchData(
        table: 'chats',
        filters: {'contract_id': contractId},
      );
      if (chatRows.isEmpty) return;

      final chatId = chatRows.first['id'] as String;
      await _databaseService.updateData(
        table: 'chats',
        data: {'closed_at': DateTime.now().toIso8601String()},
        id: chatId,
      );
    } catch (e) {
      AppLogger.logError('Close chat by contract failed for contractId: $contractId', e);
    }
  }
}
