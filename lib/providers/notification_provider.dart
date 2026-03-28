import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/notification_service.dart';
import 'auth_provider.dart';

final notificationServiceProvider = Provider((ref) => NotificationService());

/// Registers (or re-registers) the device's FCM token whenever a user is
/// signed in.  Watching [currentUserIdProvider] ensures this runs again after
/// sign-in / account-switch and is skipped when signed out.
final notificationInitProvider = FutureProvider<void>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return;

  final service = ref.watch(notificationServiceProvider);
  final token = await service.getToken();
  if (token != null) {
    await service.saveToken(userId: userId, token: token);
  }
});
