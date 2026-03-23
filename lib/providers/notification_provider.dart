import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/notification_repository.dart';
import 'auth_provider.dart';

final notificationRepositoryProvider =
    Provider((ref) => NotificationRepository());

/// Tracks which chat is currently open.
/// When non-null, message notifications for this chat are suppressed.
final activeChatIdProvider = StateProvider<String?>((ref) => null);

/// Number of unread notifications for the current user.
final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return 0;

  final repo = ref.watch(notificationRepositoryProvider);
  final notifications = await repo.getUnreadNotifications(userId);
  return notifications.length;
});
