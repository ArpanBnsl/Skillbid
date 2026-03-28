import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/job_provider.dart';
import '../../theme/app_colors.dart';
import 'home_screen.dart';
import '../common/chat_screen.dart';
import '../common/chat_detail_screen.dart';
import 'active_jobs_screen.dart';
import 'client_job_detail_screen.dart';
import 'profile_screen.dart';

class ClientShell extends ConsumerStatefulWidget {
  final int initialIndex;
  final String? initialChatId;
  final String? initialChatTitle;
  final String? initialJobId;

  const ClientShell({
    super.key,
    this.initialIndex = 0,
    this.initialChatId,
    this.initialChatTitle,
    this.initialJobId,
  });

  @override
  ConsumerState<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends ConsumerState<ClientShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    if (widget.initialChatId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              chatId: widget.initialChatId!,
              initialTitle: widget.initialChatTitle,
            ),
          ),
        );
      });
    }

    if (widget.initialJobId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final job = await ref.read(jobProvider(widget.initialJobId!).future);
        if (job != null && mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ClientJobDetailScreen(job: job),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const ClientHomeScreen(),
      const ChatScreen(role: 'client'),
      const ClientActiveJobsScreen(),
      const ClientProfileScreen(),
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
          backgroundColor: AppColors.secondaryColor,
          elevation: 2,
          tooltip: 'Switch to Service Provider',
          child: const Icon(Icons.swap_horiz, color: AppColors.textPrimary, size: 20),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surfaceLight,
          selectedItemColor: AppColors.primaryColor,
          unselectedItemColor: AppColors.textHint,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
            BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Projects'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
