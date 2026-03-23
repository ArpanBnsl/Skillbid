import '../config/supabase_config.dart';
import '../models/notification_model.dart';
import '../services/database_service.dart';
import '../utils/app_logger.dart';

class NotificationRepository {
  final _db = DatabaseService();

  /// Insert a notification row for a specific user.
  /// Failures are swallowed so callers can fire-and-forget.
  Future<void> createNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
  }) async {
    try {
      await _db.insertData(
        table: 'notifications',
        data: {
          'user_id': userId,
          'type': type,
          'title': title,
          'body': body,
          'data': data,
        },
      );
    } catch (e) {
      AppLogger.logError('Create notification failed', e);
    }
  }

  Future<List<NotificationModel>> getUnreadNotifications(String userId) async {
    try {
      final rows = await _db.fetchData(
        table: 'notifications',
        filters: {'user_id': userId, 'is_read': false},
        orderBy: 'created_at',
        descending: true,
        limit: 50,
      );
      return rows.map((r) => NotificationModel.fromJson(r)).toList();
    } catch (e) {
      AppLogger.logError('Get unread notifications failed', e);
      return [];
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _db.updateData(
        table: 'notifications',
        data: {'is_read': true},
        id: notificationId,
      );
    } catch (e) {
      AppLogger.logError('Mark notification as read failed', e);
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      AppLogger.logError('Mark all notifications as read failed', e);
    }
  }
}
