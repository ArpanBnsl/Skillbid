import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../config/supabase_config.dart';
import '../routes/app_router.dart';
import '../utils/app_logger.dart';
import 'database_service.dart';

/// Top-level background handler – MUST be a top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Background notifications are automatically shown by the system tray.
}

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final DatabaseService _db = DatabaseService();

  bool _initialized = false;

  /// Call once at app startup (before runApp).
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _setupLocalNotifications();
    await _requestPermissions();
    _setupForegroundHandler();
    _setupTokenRefresh();
  }

  // ---------------------------------------------------------------------------
  // Permissions
  // ---------------------------------------------------------------------------

  Future<void> _requestPermissions() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // ---------------------------------------------------------------------------
  // Local notifications (foreground display)
  // ---------------------------------------------------------------------------

  Future<void> _setupLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create the high-importance channel.
    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'skillbid_notifications',
          'SkillBid Notifications',
          description: 'Notifications for new jobs, bids, and messages',
          importance: Importance.high,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Foreground messages
  // ---------------------------------------------------------------------------

  void _setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'skillbid_notifications',
          'SkillBid Notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  // ---------------------------------------------------------------------------
  // Notification tap handling
  // ---------------------------------------------------------------------------

  /// Call in _MyAppState.initState() after the widget tree is ready.
  void setupInteractionHandlers() {
    // App launched from terminated state by tapping a notification.
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) _navigateFromNotification(message.data);
    });

    // App brought to foreground from background by tapping a notification.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _navigateFromNotification(message.data);
    });
  }

  /// Tap on a foreground local notification.
  void _onNotificationTap(NotificationResponse response) {
    if (response.payload == null) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      _navigateFromNotification(data);
    } catch (e) {
      AppLogger.logError('Failed to parse notification payload', e);
    }
  }

  /// Central routing logic for all notification taps.
  void _navigateFromNotification(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final targetId = data['target_id'] as String?;
    if (type == null || targetId == null) return;

    switch (type) {
      case 'new_job':
        // Provider taps → open job detail (bidding window)
        AppRouter.router.go('/provider?jobId=$targetId');
        break;
      case 'new_bid':
        // Client taps → open job detail showing bids
        AppRouter.router.go('/client?tab=2&jobId=$targetId');
        break;
      case 'new_message':
        // Navigate to chat detail
        final role = data['role'] as String? ?? 'client';
        AppRouter.router.go('/$role?chatId=$targetId');
        break;
      case 'bid_accepted':
        // Provider taps → open the new contract
        AppRouter.router.go('/provider?contractId=$targetId');
        break;
      case 'contract_terminated':
        // Provider taps → go to provider home
        AppRouter.router.go('/provider');
        break;
      case 'work_submitted':
        // Client taps → open the contract detail
        AppRouter.router.go('/client?contractId=$targetId');
        break;
      case 'work_approved':
        // Provider taps → open the contract detail
        AppRouter.router.go('/provider?contractId=$targetId');
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // FCM token management
  // ---------------------------------------------------------------------------

  Future<String?> getToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      AppLogger.logError('Failed to get FCM token', e);
      return null;
    }
  }

  void _setupTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      final userId = getCurrentUserId();
      if (userId != null) {
        saveToken(userId: userId, token: newToken);
      }
    });
  }

  /// Upsert the device's FCM token into Supabase.
  Future<void> saveToken({
    required String userId,
    required String token,
  }) async {
    try {
      await _db.upsertData(
        table: 'device_tokens',
        data: {
          'user_id': userId,
          'fcm_token': token,
          'device_id': token.hashCode.toString(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'user_id,device_id',
      );
    } catch (e) {
      AppLogger.logError('Failed to save FCM token', e);
    }
  }

  /// Remove the current device's token on sign-out.
  Future<void> removeToken({required String userId}) async {
    try {
      final token = await getToken();
      if (token != null) {
        await _db.deleteWhere(
          table: 'device_tokens',
          filters: {
            'user_id': userId,
            'fcm_token': token,
          },
        );
      }
    } catch (e) {
      AppLogger.logError('Failed to remove FCM token', e);
    }
  }
}
