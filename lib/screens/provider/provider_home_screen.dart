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
import 'provider_job_detail_screen.dart';

class ProviderHomeScreen extends ConsumerWidget {
  const ProviderHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userp.currentUserProvider);
    final bidsAsync = ref.watch(providerBidsProvider);
    final jobsAsync = ref.watch(availableJobsProvider);
    final userId = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Provider Dashboard')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(providerBidsProvider);
          ref.invalidate(availableJobsProvider);
          await Future.wait([
            ref.read(providerBidsProvider.future),
            ref.read(availableJobsProvider.future),
          ]);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            profileAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (profile) => _ProviderHeroCard(
                firstName: profile == null ? 'there' : profile.fullName.split(' ').first,
              ),
            ),
            const SizedBox(height: 16),
            _DashboardStats(
              bidsAsync: bidsAsync,
              jobsAsync: jobsAsync,
              currentUserId: userId,
            ),
            const SizedBox(height: 18),
            Text('Fresh Opportunities', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _FreshOpportunities(
              jobsAsync: jobsAsync,
              bidsAsync: bidsAsync,
              currentUserId: userId,
            ),
          ],
        ),
      ),
    );
  }
}

class _FreshOpportunities extends ConsumerWidget {
  final AsyncValue<List<BidModel>> bidsAsync;
  final AsyncValue<List<JobModel>> jobsAsync;
  final String? currentUserId;

  const _FreshOpportunities({
    required this.jobsAsync,
    required this.bidsAsync,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return jobsAsync.when(
              loading: () => const LoadingWidget(message: 'Loading open jobs...'),
              error: (e, _) => Text('Failed to load jobs: $e'),
              data: (jobs) {
                final myBids = (bidsAsync.valueOrNull ?? const []);
                final bidJobIds = myBids.map((bid) => bid.jobId).toSet();

                final freshJobs = jobs.where((job) {
                  if (currentUserId == null) return false;
                  final isOwnJob = job.clientId == currentUserId;
                  final hasBid = bidJobIds.contains(job.id);
                  return !isOwnJob && !hasBid;
                }).toList();

                if (freshJobs.isEmpty) {
                  return const SizedBox(
                    height: 180,
                    child: EmptyStateWidget(
                      message: 'No fresh opportunities right now.',
                      icon: Icons.work_off_outlined,
                    ),
                  );
                }

                return Column(
                  children: freshJobs.map((job) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProviderJobDetailScreen(job: job),
                            ),
                          );
                        },
                        leading: const Icon(Icons.work_outline),
                        title: Text(job.title),
                        subtitle: Text('${job.location} • ${Formatters.formatTimeAgo(job.createdAt)}'),
                        trailing: Text(
                          Formatters.formatCurrencyShort(job.budget),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            );
  }
}

class _ProviderHeroCard extends StatelessWidget {
  final String firstName;

  const _ProviderHeroCard({required this.firstName});

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
                'Welcome, $firstName',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Track your bidding activity and discover matching opportunities from clients.',
                style: TextStyle(
                  color: Colors.white,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardStats extends StatelessWidget {
  final AsyncValue bidsAsync;
  final AsyncValue jobsAsync;
  final String? currentUserId;

  const _DashboardStats({
    required this.bidsAsync,
    required this.jobsAsync,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final bids = (bidsAsync.valueOrNull as List<BidModel>?) ?? const [];
    final jobs = (jobsAsync.valueOrNull as List<JobModel>?) ?? const [];
    final bidJobIds = bids.map((bid) => bid.jobId).toSet();
    final freshOpportunities = jobs.where((job) {
      if (currentUserId == null) return false;
      return job.clientId != currentUserId && !bidJobIds.contains(job.id);
    }).length;
    final pendingBids = bids.where((bid) => bid.status == 'pending').length;
    final acceptedBids = bids.where((bid) => bid.status == 'accepted').length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = constraints.maxWidth < 360 ? 6.0 : 10.0;
        return Row(
          children: [
            Expanded(
              child: _DashboardTile(label: 'Fresh Opportunities', value: '$freshOpportunities', icon: Icons.travel_explore_outlined),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _DashboardTile(label: 'Pending Bids', value: '$pendingBids', icon: Icons.hourglass_bottom_outlined),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _DashboardTile(label: 'Accepted', value: '$acceptedBids', icon: Icons.verified_outlined),
            ),
          ],
        );
      },
    );
  }
}

class _DashboardTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DashboardTile({required this.label, required this.value, required this.icon});

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
