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
import 'provider_bids_screen.dart';
import 'provider_job_detail_screen.dart';
import 'provider_jobs_screen.dart';

class ProviderHomeScreen extends ConsumerWidget {
  const ProviderHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userp.currentUserProvider);
    final bidsAsync = ref.watch(providerBidsProvider);
    final jobsAsync = ref.watch(availableJobsProvider);
    final userId = ref.watch(currentUserIdProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Provider Dashboard', style: AppTypography.heading4.copyWith(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryColor,
        backgroundColor: AppColors.surfaceLight,
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
            const SizedBox(height: 12),
            // Quick action chips
            Row(
              children: [
                _QuickActionChip(
                  label: 'Browse Jobs',
                  icon: Icons.search,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProviderJobsScreen()),
                  ),
                ),
                const SizedBox(width: 10),
                _QuickActionChip(
                  label: 'My Bids',
                  icon: Icons.gavel,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProviderBidsScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _DashboardStats(
              bidsAsync: bidsAsync,
              jobsAsync: jobsAsync,
              currentUserId: userId,
            ),
            const SizedBox(height: 18),
            // Immediate Jobs Section
            jobsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (jobs) {
                final myBids = bidsAsync.valueOrNull ?? const [];
                final bidJobIds = myBids.map((bid) => bid.jobId).toSet();
                final immediateJobs = jobs.where((job) {
                  if (userId == null) return false;
                  if (job.clientId == userId) return false;
                  if (bidJobIds.contains(job.id)) return false;
                  return job.isImmediate && job.status == 'open';
                }).toList();

                if (immediateJobs.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bolt, color: AppColors.accent, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          'Urgent — Immediate Service',
                          style: AppTypography.labelLarge.copyWith(color: AppColors.accent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...immediateJobs.map((job) {
                      final remaining = job.expiresAt != null
                          ? job.expiresAt!.difference(DateTime.now())
                          : Duration.zero;
                      final expired = remaining.isNegative || remaining == Duration.zero;
                      final timeLabel = expired
                          ? 'Expired'
                          : '${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m left';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppColors.warningLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                        ),
                        child: ListTile(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProviderJobDetailScreen(job: job),
                            ),
                          ),
                          leading: Icon(Icons.bolt, color: AppColors.warning),
                          title: Text(job.title, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${job.location} • $timeLabel',
                            style: AppTypography.caption.copyWith(color: AppColors.warning),
                          ),
                          trailing: Text(
                            Formatters.formatCurrencyShort(job.budget),
                            style: AppTypography.labelLarge.copyWith(color: AppColors.warning),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 14),
                  ],
                );
              },
            ),
            Text('Fresh Opportunities', style: AppTypography.heading4.copyWith(color: AppColors.textPrimary)),
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

class _QuickActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionChip({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primaryColor),
            const SizedBox(width: 6),
            Text(label, style: AppTypography.labelMedium.copyWith(color: AppColors.primaryColor)),
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
              error: (e, _) => Text('Failed to load jobs: $e', style: TextStyle(color: AppColors.error)),
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
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProviderJobDetailScreen(job: job),
                            ),
                          );
                        },
                        leading: Icon(Icons.work_outline, color: AppColors.primaryColor),
                        title: Text(job.title, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${job.location} • ${Formatters.formatTimeAgo(job.createdAt)}',
                          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                        ),
                        trailing: Text(
                          Formatters.formatCurrencyShort(job.budget),
                          style: AppTypography.labelLarge.copyWith(color: AppColors.primaryColor),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: AppColors.purpleGradient,
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
                color: AppColors.whiteOverlay,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, $firstName',
                style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Track your bidding activity and discover matching opportunities from clients.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary.withValues(alpha: 0.85)),
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
              child: _DashboardTile(
                label: 'Fresh Opportunities',
                value: '$freshOpportunities',
                icon: Icons.travel_explore_outlined,
                iconColor: AppColors.primaryColor,
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _DashboardTile(
                label: 'Pending Bids',
                value: '$pendingBids',
                icon: Icons.hourglass_bottom_outlined,
                iconColor: AppColors.secondaryColor,
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _DashboardTile(
                label: 'Accepted',
                value: '$acceptedBids',
                icon: Icons.verified_outlined,
                iconColor: AppColors.success,
              ),
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
  final Color iconColor;

  const _DashboardTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 98,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 17, color: iconColor),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
              ),
            ),
            const Spacer(),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.captionSmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
