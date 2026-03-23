import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_constants.dart';
import '../../config/supabase_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../repositories/notification_repository.dart';
import '../../services/notification_service.dart';
import '../common/chat_detail_screen.dart';
import '../common/chat_screen.dart';
import 'provider_home_screen.dart';
import 'provider_profile_screen.dart';
import 'provider_projects_screen.dart';

class ProviderShell extends ConsumerStatefulWidget {
  final int initialIndex;
  final String? initialChatId;

  const ProviderShell({super.key, this.initialIndex = 0, this.initialChatId});

  @override
  ConsumerState<ProviderShell> createState() => _ProviderShellState();
}

class _ProviderShellState extends ConsumerState<ProviderShell>
    with WidgetsBindingObserver {
  late int _currentIndex;
  RealtimeChannel? _notifChannel;
  RealtimeChannel? _jobChannel;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupNotificationListener();
      _setupNewJobListener();
    });

    if (widget.initialChatId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(chatId: widget.initialChatId!),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notifChannel?.unsubscribe();
    _jobChannel?.unsubscribe();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(unreadNotificationCountProvider);
    }
  }

  // ---------------------------------------------------------------------------
  // Realtime: personal notification channel
  // ---------------------------------------------------------------------------
  void _setupNotificationListener() {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    _notifChannel = supabase
        .channel('provider_notifs_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: _handleIncomingNotification,
        )
        .subscribe();
  }

  void _handleIncomingNotification(PostgresChangePayload payload) {
    final row = payload.newRecord;
    final type = row['type'] as String?;

    Map<String, dynamic> parsedData = {};
    final rawData = row['data'];
    if (rawData is Map<String, dynamic>) {
      parsedData = rawData;
    } else if (rawData is Map) {
      parsedData = Map<String, dynamic>.from(rawData);
    }

    // Suppress message notification when that chat is already open
    if (type == AppConstants.notifNewMessage) {
      final chatId = parsedData['chat_id'] as String?;
      final activeChat = ref.read(activeChatIdProvider);
      if (chatId != null && chatId == activeChat) {
        NotificationRepository().markAsRead(row['id'] as String);
        return;
      }
    }

    NotificationService().show(
      title: row['title'] as String? ?? 'SkillBid',
      body: row['body'] as String? ?? '',
      payload: {
        ...parsedData,
        'type': type,
        'notification_id': row['id'],
      },
    );

    ref.invalidate(unreadNotificationCountProvider);
  }

  // ---------------------------------------------------------------------------
  // Realtime: broadcast channel for new open jobs
  // ---------------------------------------------------------------------------
  void _setupNewJobListener() {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    _jobChannel = supabase
        .channel('new_open_jobs')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'jobs',
          callback: (PostgresChangePayload payload) {
            final newJob = payload.newRecord;
            final status = newJob['status'] as String?;
            final clientId = newJob['client_id'] as String?;

            // Only notify about open jobs that aren't the user's own
            if (status == AppConstants.jobStatusOpen && clientId != userId) {
              NotificationService().show(
                title: 'New Project Available',
                body: (newJob['title'] as String?) ?? 'A new project was posted',
                payload: {
                  'type': AppConstants.notifNewJob,
                  'job_id': newJob['id'],
                  'role': 'provider',
                },
              );
            }
          },
        )
        .subscribe();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final unreadCount =
        ref.watch(unreadNotificationCountProvider).valueOrNull ?? 0;

    final screens = [
      const ProviderHomeScreen(),
      const ProviderProjectsScreen(),
      const ChatScreen(role: 'provider'),
      const ProviderProfileScreen(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return;
        }
        Navigator.of(context).pop();
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
        floatingActionButton: FloatingActionButton.small(
          heroTag: 'switchRole',
          onPressed: () => context.go('/role-selection'),
          backgroundColor: Colors.grey.shade200,
          elevation: 1,
          tooltip: 'Switch to Client',
          child: const Icon(Icons.swap_horiz, color: Colors.black87, size: 20),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.teal,
          unselectedItemColor: Colors.grey,
          items: [
            const BottomNavigationBarItem(
                icon: Icon(Icons.home), label: 'Home'),
            const BottomNavigationBarItem(
                icon: Icon(Icons.work_outline), label: 'Projects'),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: unreadCount > 0,
                label: Text('$unreadCount',
                    style: const TextStyle(fontSize: 10)),
                child: const Icon(Icons.chat_bubble_outline),
              ),
              label: 'Chat',
            ),
            const BottomNavigationBarItem(
                icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
