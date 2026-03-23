import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/contract_model.dart';
import '../models/job/job_model.dart';
import '../repositories/contract_repository.dart';
import '../repositories/job_repository.dart';
import '../repositories/notification_repository.dart';
import '../routes/app_router.dart';
import '../screens/client/client_contract_detail_screen.dart';
import '../screens/client/client_job_detail_screen.dart';
import '../screens/common/chat_detail_screen.dart';
import '../screens/provider/provider_contract_detail_screen.dart';
import '../screens/provider/provider_job_detail_screen.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'skillbid_notifications';
  static const _channelName = 'SkillBid Notifications';
  static const _channelDesc =
      'Notifications for bids, messages, and project updates';

  /// Call once at app start.
  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onTapped,
    );

    // Request runtime permission on Android 13+ / Android 15
    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
    }
  }

  /// Show a heads-up notification on the device.
  Future<void> show({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const notifDetails = NotificationDetails(
      android: androidDetails,
      macOS: DarwinNotificationDetails(),
    );

    // Use hash of payload or timestamp as unique id
    final id =
        payload?.hashCode.abs() ?? DateTime.now().millisecondsSinceEpoch % 100000;

    await _plugin.show(
      id,
      title,
      body,
      notifDetails,
      payload: payload != null ? jsonEncode(payload) : null,
    );
  }

  // ---------------------------------------------------------------------------
  // Tap handling
  // ---------------------------------------------------------------------------

  static void _onTapped(NotificationResponse response) {
    if (response.payload == null) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      _navigateFromPayload(data);
    } catch (_) {}
  }

  static Future<void> _navigateFromPayload(Map<String, dynamic> data) async {
    final nav = AppRouter.navigatorKey.currentState;
    if (nav == null) return;

    final type = data['type'] as String?;
    final role = data['role'] as String?;

    // Mark notification as read in Supabase
    final notifId = data['notification_id'] as String?;
    if (notifId != null) {
      NotificationRepository().markAsRead(notifId);
    }

    switch (type) {
      // ── Chat-based notifications ───────────────────────────────────────
      case 'new_message':
      case 'bid_approved_confirmation':
      case 'proposal_accepted':
        final chatId = data['chat_id'] as String?;
        if (chatId != null) {
          nav.push(MaterialPageRoute(
            builder: (_) => ChatDetailScreen(chatId: chatId),
          ));
        }
        break;

      // ── New bid (client sees job detail with bids) ─────────────────────
      case 'new_bid':
        await _pushJobDetail(data, nav, isClient: true);
        break;

      // ── New job (provider sees job detail) ─────────────────────────────
      case 'new_job':
        await _pushJobDetail(data, nav, isClient: false);
        break;

      // ── Contract status change / completion ────────────────────────────
      case 'status_change':
      case 'project_completed':
        await _pushContractDetail(data, nav, role: role);
        break;
    }
  }

  static Future<void> _pushJobDetail(
    Map<String, dynamic> data,
    NavigatorState nav, {
    required bool isClient,
  }) async {
    final jobId = data['job_id'] as String?;
    if (jobId == null) return;

    final JobModel? job = await JobRepository().getJobById(jobId);
    if (job == null) return;

    if (isClient) {
      nav.push(MaterialPageRoute(
        builder: (_) => ClientJobDetailScreen(job: job),
      ));
    } else {
      nav.push(MaterialPageRoute(
        builder: (_) => ProviderJobDetailScreen(job: job),
      ));
    }
  }

  static Future<void> _pushContractDetail(
    Map<String, dynamic> data,
    NavigatorState nav, {
    String? role,
  }) async {
    final contractId = data['contract_id'] as String?;
    if (contractId == null) return;

    final ContractModel? contract =
        await ContractRepository().getContractById(contractId);
    if (contract == null) return;

    if (role == 'provider') {
      nav.push(MaterialPageRoute(
        builder: (_) => ProviderContractDetailScreen(contract: contract),
      ));
    } else {
      nav.push(MaterialPageRoute(
        builder: (_) => ClientContractDetailScreen(contract: contract),
      ));
    }
  }
}
