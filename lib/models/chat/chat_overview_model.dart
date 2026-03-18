class ChatOverviewModel {
  final String chatId;
  final String jobId;
  final String? contractId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatarUrl;
  final String? jobTitle;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? clientName;
  final String? providerName;
  final DateTime? closedAt;

  const ChatOverviewModel({
    required this.chatId,
    required this.jobId,
    required this.contractId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserAvatarUrl,
    required this.jobTitle,
    required this.lastMessage,
    required this.lastMessageAt,
    this.clientName,
    this.providerName,
    this.closedAt,
  });

  bool get isClosed => closedAt != null;
}
