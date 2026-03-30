import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/contract_provider.dart';
import '../../providers/job_provider.dart';
import '../../theme/app_colors.dart';
import '../common/chat_screen.dart';
import '../common/chat_detail_screen.dart';
import 'provider_contract_detail_screen.dart';
import 'provider_home_screen.dart';
import 'provider_job_detail_screen.dart';
import 'provider_projects_screen.dart';
import 'provider_profile_screen.dart';

class ProviderShell extends ConsumerStatefulWidget {
  final int initialIndex;
  final String? initialChatId;
  final String? initialChatTitle;
  final String? initialJobId;
  final String? initialContractId;

  const ProviderShell({
    super.key,
    this.initialIndex = 0,
    this.initialChatId,
    this.initialChatTitle,
    this.initialJobId,
    this.initialContractId,
  });

  @override
  ConsumerState<ProviderShell> createState() => _ProviderShellState();
}

class _ProviderShellState extends ConsumerState<ProviderShell> {
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
              builder: (_) => ProviderJobDetailScreen(job: job),
            ),
          );
        }
      });
    }

    if (widget.initialContractId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final contract = await ref.read(contractProvider(widget.initialContractId!).future);
        if (contract != null && mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProviderContractDetailScreen(contract: contract),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
        backgroundColor: AppColors.surface,
        body: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
        floatingActionButton: FloatingActionButton.small(
          heroTag: 'switchRole',
          onPressed: () => context.go('/role-selection'),
          backgroundColor: AppColors.secondaryColor,
          elevation: 2,
          tooltip: 'Switch to Client',
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
            BottomNavigationBarItem(icon: Icon(Icons.work_outline), label: 'Projects'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
