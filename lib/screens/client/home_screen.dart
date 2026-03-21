import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/bid_model.dart';
import '../../models/job/job_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bid_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/user_provider.dart' as userp;
import '../../utils/formatters.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';
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

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userp.currentUserProvider);
    final myJobsAsync = ref.watch(clientPostedJobsProvider);
    final recentBidsAsync = ref.watch(clientRecentBidsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Home'),
        actions: [
          IconButton(
            tooltip: 'Post New Job',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _openCreateJob,
          ),
        ],
      ),
      body: RefreshIndicator(
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
            const SizedBox(height: 16),
            _ActivityStats(
              jobsAsync: myJobsAsync,
              recentBidsAsync: recentBidsAsync,
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Recent Bids On Your Projects',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            recentBidsAsync.when(
              loading: () => const SizedBox(height: 220, child: LoadingWidget(message: 'Loading recent bids...')),
              error: (e, _) => Text('Failed to load bids: $e'),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF0B6E6E), Color(0xFF1F9E9A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14,
            top: -14,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
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
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, $userFirstName',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Need a task done? Post your project in minutes and get quality bids from service providers.',
                style: TextStyle(
                  color: Colors.white,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0B6E6E),
                ),
                onPressed: onPostJob,
                icon: const Icon(Icons.add_task_outlined),
                label: const Text('Post A New Job'),
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
    return SizedBox(
      height: 98,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE6EFEF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 17, color: const Color(0xFF0B6E6E)),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            const Spacer(),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
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
    return Card(
      margin: margin,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE6F4F3),
          foregroundColor: const Color(0xFF0B6E6E),
          child: Text(_initials(item.providerName)),
        ),
        title: Text(item.job.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${item.providerName} • ${Formatters.formatTimeAgo(item.bid.createdAt)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              Formatters.formatCurrencyShort(item.bid.amount),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(item.bid.status, style: const TextStyle(fontSize: 11, color: Colors.black54)),
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
