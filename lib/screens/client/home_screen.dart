import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/bid_model.dart';
import '../../models/job/job_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bid_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/user_provider.dart' as userp;
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';
import 'client_job_detail_screen.dart';
import 'create_job_screen.dart';

class ClientRecentBidItem {
  final JobModel job;
  final BidModel bid;
  final String providerName;

  const ClientRecentBidItem({
    required this.job,
    required this.bid,
    required this.providerName,
  });
}

final clientRecentBidsProvider = FutureProvider<List<ClientRecentBidItem>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];

  final jobs = await ref.read(clientPostedJobsProvider.future);
  if (jobs.isEmpty) return const [];

  final bidRepo = ref.read(bidRepositoryProvider);
  final userRepo = ref.read(userp.userRepositoryProvider);

  final bidsPerJob = await Future.wait(
    jobs.map((job) async {
      final bids = await bidRepo.getJobBids(job.id);
      return MapEntry(job, bids);
    }),
  );

  final providerIds = <String>{};
  for (final pair in bidsPerJob) {
    for (final bid in pair.value) {
      providerIds.add(bid.providerId);
    }
  }

  final providerProfiles = await Future.wait(
    providerIds.map((id) async => MapEntry(id, await userRepo.getUserProfile(id))),
  );
  final providerNameById = {
    for (final pair in providerProfiles)
      pair.key: pair.value?.fullName ?? 'Service Provider',
  };

  final items = <ClientRecentBidItem>[];
  for (final pair in bidsPerJob) {
    for (final bid in pair.value) {
      items.add(
        ClientRecentBidItem(
          job: pair.key,
          bid: bid,
          providerName: providerNameById[bid.providerId] ?? 'Service Provider',
        ),
      );
    }
  }

  items.sort((a, b) => b.bid.createdAt.compareTo(a.bid.createdAt));
  return items.take(12).toList();
});

class ClientHomeScreen extends ConsumerStatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  ConsumerState<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends ConsumerState<ClientHomeScreen> {
  final _bidsKey = GlobalKey();

  Future<void> _openCreateJob() async {
    try {
      final skills = await ref.read(skillsProvider.future);
      if (!mounted) return;

      final posted = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => CreateJobScreen(skills: skills),
        ),
      );

      if (posted == true) {
        ref.invalidate(clientJobsProvider);
        ref.invalidate(clientPostedJobsProvider);
        ref.invalidate(clientRecentBidsProvider);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open job form: $e')),
      );
    }
  }

  void _scrollToBids() {
    final ctx = _bidsKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 400));
    }
  }

  void _navigateToTab(int index) {
    // Find the ClientShell ancestor and switch tab
    final shellState = context.findAncestorStateOfType<State>();
    // Use a simpler approach: we set the bottom nav index via callback
    // The shell exposes _currentIndex via setState, so we navigate by
    // rebuilding with the correct index
    if (shellState != null && shellState.mounted) {
      // Walk up to find the scaffold with bottom nav
      final scaffoldState = context.findAncestorStateOfType<ScaffoldState>();
      if (scaffoldState != null) {
        // Navigate by tapping the bottom nav programmatically
        final bottomNav = scaffoldState.widget.bottomNavigationBar;
        if (bottomNav is BottomNavigationBar) {
          bottomNav.onTap?.call(index);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userp.currentUserProvider);
    final myJobsAsync = ref.watch(clientPostedJobsProvider);
    final recentBidsAsync = ref.watch(clientRecentBidsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Client Home', style: AppTypography.heading4.copyWith(color: AppColors.textPrimary)),
        actions: [
          IconButton(
            tooltip: 'Post New Job',
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryColor),
            onPressed: _openCreateJob,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryColor,
        backgroundColor: AppColors.surfaceLight,
        onRefresh: () async {
          ref.invalidate(clientJobsProvider);
          ref.invalidate(clientPostedJobsProvider);
          ref.invalidate(clientRecentBidsProvider);
          await Future.wait([
            ref.read(clientPostedJobsProvider.future),
            ref.read(clientRecentBidsProvider.future),
          ]);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            profileAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (profile) => _HeroPostCard(
                userFirstName: profile == null ? 'there' : profile.fullName.split(' ').first,
                onPostJob: _openCreateJob,
              ),
            ),
            const SizedBox(height: 14),
            // Quick action row
            Row(
              children: [
                _QuickAction(
                  icon: Icons.add_task_outlined,
                  label: 'Post Job',
                  onTap: _openCreateJob,
                ),
                const SizedBox(width: 8),
                _QuickAction(
                  icon: Icons.gavel_outlined,
                  label: 'View Bids',
                  onTap: _scrollToBids,
                ),
                const SizedBox(width: 8),
                _QuickAction(
                  icon: Icons.work_outline,
                  label: 'Projects',
                  onTap: () => _navigateToTab(2),
                ),
                const SizedBox(width: 8),
                _QuickAction(
                  icon: Icons.chat_outlined,
                  label: 'Messages',
                  onTap: () => _navigateToTab(1),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ActivityStats(
              jobsAsync: myJobsAsync,
              recentBidsAsync: recentBidsAsync,
            ),
            const SizedBox(height: 22),
            Row(
              key: _bidsKey,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Recent Bids On Your Projects',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            recentBidsAsync.when(
              loading: () => const SizedBox(height: 220, child: LoadingWidget(message: 'Loading recent bids...')),
              error: (e, _) => Text('Failed to load bids: $e', style: const TextStyle(color: AppColors.error)),
              data: (items) {
                if (items.isEmpty) {
                  return const SizedBox(
                    height: 240,
                    child: EmptyStateWidget(
                      message: 'No bids yet. Post a job and providers will start bidding.',
                      icon: Icons.gavel,
                    ),
                  );
                }

                return Column(
                  children: items.map((item) {
                    return _RecentBidCard(
                      margin: const EdgeInsets.only(bottom: 10),
                      item: item,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: AppColors.primaryColor),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.captionSmall.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroPostCard extends StatelessWidget {
  final String userFirstName;
  final VoidCallback onPostJob;

  const _HeroPostCard({
    required this.userFirstName,
    required this.onPostJob,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: AppColors.primaryGradient,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14,
            top: -14,
            child: Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.whiteOverlay,
              ),
            ),
          ),
          Positioned(
            right: 34,
            bottom: -28,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.whiteOverlay.withValues(alpha: 0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, $userFirstName',
                style: AppTypography.heading3.copyWith(color: AppColors.textDark),
              ),
              const SizedBox(height: 8),
              Text(
                'Need a task done? Post your project in minutes and get quality bids from service providers.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textDark.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.primaryColor,
                ),
                onPressed: onPostJob,
                icon: const Icon(Icons.add_task_outlined),
                label: Text('Post A New Job', style: AppTypography.buttonText.copyWith(color: AppColors.primaryColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityStats extends StatelessWidget {
  final AsyncValue<List<JobModel>> jobsAsync;
  final AsyncValue<List<ClientRecentBidItem>> recentBidsAsync;

  const _ActivityStats({
    required this.jobsAsync,
    required this.recentBidsAsync,
  });

  @override
  Widget build(BuildContext context) {
    final jobs = jobsAsync.valueOrNull ?? const <JobModel>[];
    final bids = recentBidsAsync.valueOrNull ?? const <ClientRecentBidItem>[];
    final openJobs = jobs.where((j) => j.status == 'open').length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = constraints.maxWidth < 360 ? 6.0 : 10.0;
        return Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Jobs Posted',
                value: '${jobs.length}',
                icon: Icons.work_outline,
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _StatTile(
                label: 'Out For Bid',
                value: '$openJobs',
                icon: Icons.campaign_outlined,
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _StatTile(
                label: 'Recent Bids',
                value: '${bids.length}',
                icon: Icons.gavel_outlined,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.primaryColor),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: AppTypography.statValue.copyWith(color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.captionSmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
    );
  }
}

class _RecentBidCard extends StatelessWidget {
  final EdgeInsetsGeometry margin;
  final ClientRecentBidItem item;

  const _RecentBidCard({
    required this.margin,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (item.bid.status) {
      'pending' => AppColors.warning,
      'accepted' => AppColors.success,
      'rejected' => AppColors.error,
      _ => AppColors.info,
    };
    final statusBg = switch (item.bid.status) {
      'pending' => AppColors.warningLight,
      'accepted' => AppColors.successLight,
      'rejected' => AppColors.errorLight,
      _ => AppColors.infoLight,
    };

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.surfaceVariant,
                  child: Text(
                    _initials(item.providerName),
                    style: AppTypography.labelMedium.copyWith(color: AppColors.primaryColor),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.job.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.providerName} • ${Formatters.formatTimeAgo(item.bid.createdAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.formatCurrencyShort(item.bid.amount),
                      style: AppTypography.bidAmount.copyWith(color: AppColors.primaryColor, fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.bid.status,
                        style: AppTypography.captionSmall.copyWith(color: statusColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryColor,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClientJobDetailScreen(job: item.job),
                    ),
                  );
                },
                child: Text('View Job', style: AppTypography.labelMedium.copyWith(color: AppColors.primaryColor)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'SP';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
