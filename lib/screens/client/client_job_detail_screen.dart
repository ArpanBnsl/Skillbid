import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/supabase_config.dart';
import '../../models/job/job_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bid_provider.dart';
import '../../providers/contract_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/user_provider.dart' as userp;
import '../../services/realtime_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/image_viewer.dart';
import '../../widgets/common/loading_widget.dart';
import 'client_contract_detail_screen.dart';
import '../../providers/job_provider.dart';

class ClientJobDetailScreen extends ConsumerStatefulWidget {
  final JobModel job;

  const ClientJobDetailScreen({super.key, required this.job});

  @override
  ConsumerState<ClientJobDetailScreen> createState() => _ClientJobDetailScreenState();
}

class _ClientJobDetailScreenState extends ConsumerState<ClientJobDetailScreen> {
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;
  late final RealtimeService _realtimeService;
  dynamic _bidChannel;

  JobModel get job => widget.job;

  @override
  void initState() {
    super.initState();
    _realtimeService = RealtimeService();

    if (job.isImmediate && job.expiresAt != null) {
      _updateRemaining();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateRemaining());
    }

    if (job.isImmediate && job.status == 'open') {
      _bidChannel = _realtimeService.subscribeToBids(
        job.id,
        onChange: (_) => ref.invalidate(jobBidsProvider(job.id)),
      );
    }
  }

  void _updateRemaining() {
    final diff = job.expiresAt!.difference(DateTime.now());
    if (!mounted) return;
    setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    if (_bidChannel != null) {
      supabase.removeChannel(_bidChannel);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bidsAsync = ref.watch(jobBidsProvider(job.id));
    final contractAsync = ref.watch(contractByJobProvider(job.id));
    final imagesAsync = ref.watch(jobImagesProvider(job.id));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        title: Text('Job Details', style: AppTypography.heading4.copyWith(color: AppColors.textPrimary)),
        actions: [
          IconButton(
            tooltip: 'Delete job',
            onPressed: (job.status == 'open' && contractAsync.valueOrNull == null)
                ? () => _deleteJob(context, ref)
                : null,
            icon: Icon(
              Icons.delete_outline,
              color: (job.status == 'open' && contractAsync.valueOrNull == null)
                  ? AppColors.error
                  : AppColors.textHint,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryColor,
        backgroundColor: AppColors.surfaceLight,
        onRefresh: () async {
          ref.invalidate(jobBidsProvider(job.id));
          ref.invalidate(contractByJobProvider(job.id));
          await Future.wait([
            ref.read(jobBidsProvider(job.id).future),
            ref.read(contractByJobProvider(job.id).future),
          ]);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _jobCard(job, imagesAsync),
            if (job.isImmediate) ...[
              const SizedBox(height: 10),
              _immediateInfoCard(),
            ],
            const SizedBox(height: 14),
            contractAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (contract) {
                if (contract == null) {
                  return const SizedBox.shrink();
                }
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.handshake_outlined, color: AppColors.primaryColor),
                    title: Text(
                      'Contract is ${contract.status}',
                      style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary),
                    ),
                    subtitle: Text(
                      'Created on ${Formatters.formatDate(contract.createdAt)}',
                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClientContractDetailScreen(contract: contract),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text('Bids', style: AppTypography.heading4.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            bidsAsync.when(
              loading: () => const SizedBox(height: 180, child: LoadingWidget(message: 'Loading bids...')),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(12),
                child: Text('Failed to load bids: $e', style: const TextStyle(color: AppColors.error)),
              ),
              data: (bids) {
                if (bids.isEmpty) {
                  return const SizedBox(
                    height: 180,
                    child: EmptyStateWidget(
                      message: 'No bids yet. Job is currently out for bid.',
                      icon: Icons.gavel,
                    ),
                  );
                }

                return Column(
                  children: bids.map((bid) {
                    final providerProfileAsync = ref.watch(userp.userProfileProvider(bid.providerId));
                    final providerName = providerProfileAsync.valueOrNull?.fullName ?? 'Service Provider';
                    final contract = contractAsync.valueOrNull;
                    final isAcceptedContract = contract != null && contract.providerId == bid.providerId;

                    final statusColor = switch (bid.status) {
                      'pending' => AppColors.warning,
                      'accepted' => AppColors.success,
                      'rejected' => AppColors.error,
                      _ => AppColors.info,
                    };
                    final statusBg = switch (bid.status) {
                      'pending' => AppColors.warningLight,
                      'accepted' => AppColors.successLight,
                      'rejected' => AppColors.errorLight,
                      _ => AppColors.infoLight,
                    };

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.surfaceVariant,
                                child: Text(
                                  _bidInitials(providerName),
                                  style: AppTypography.labelMedium.copyWith(color: AppColors.primaryColor),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  providerName,
                                  style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  bid.status,
                                  style: AppTypography.labelSmall.copyWith(color: statusColor),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            Formatters.formatCurrencyShort(bid.amount),
                            style: AppTypography.bidAmount.copyWith(color: AppColors.primaryColor),
                          ),
                          if (bid.estimatedDays != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Estimated: ${bid.estimatedDays} days',
                              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                          if (bid.message != null && bid.message!.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              bid.message!,
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primaryColor,
                                    side: const BorderSide(color: AppColors.border),
                                  ),
                                  onPressed: () => _showBidderProfile(context, bid.providerId),
                                  icon: const Icon(Icons.person_outline, size: 18),
                                  label: Text('View Profile', style: AppTypography.labelMedium.copyWith(color: AppColors.primaryColor)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: isAcceptedContract
                                        ? AppColors.successLight
                                        : AppColors.primaryColor,
                                    foregroundColor: isAcceptedContract
                                        ? AppColors.success
                                        : AppColors.textDark,
                                    disabledBackgroundColor: AppColors.surfaceVariant,
                                    disabledForegroundColor: AppColors.textHint,
                                  ),
                                  onPressed: (bid.status != 'pending' || isAcceptedContract)
                                      ? null
                                      : () => _acceptBid(context, ref, bid.id, bid.providerId),
                                  child: Text(
                                    isAcceptedContract ? 'Accepted' : 'Accept',
                                    style: AppTypography.labelMedium,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  String _bidInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'SP';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Widget _jobCard(JobModel job, AsyncValue imagesAsync) {
    final uiStatus = switch (job.status) {
      'open' => 'Out for Bid',
      'in_progress' => 'In Progress',
      'completed' => 'Completed',
      'cancelled' => 'Cancelled',
      'deleted' => 'Deleted',
      _ => job.status,
    };

    final statusColor = switch (job.status) {
      'open' => AppColors.warning,
      'in_progress' => AppColors.info,
      'completed' => AppColors.success,
      'cancelled' || 'deleted' => AppColors.error,
      _ => AppColors.textSecondary,
    };
    final statusBg = switch (job.status) {
      'open' => AppColors.warningLight,
      'in_progress' => AppColors.infoLight,
      'completed' => AppColors.successLight,
      'cancelled' || 'deleted' => AppColors.errorLight,
      _ => AppColors.surfaceVariant,
    };

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: AppColors.cardGradient,
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    job.title,
                    style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        uiStatus,
                        style: AppTypography.labelSmall.copyWith(color: statusColor),
                      ),
                    ),
                    if (job.isImmediate) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.glowOrange,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt, size: 14, color: AppColors.accent),
                            const SizedBox(width: 4),
                            Text(
                              'Immediate',
                              style: AppTypography.labelSmall.copyWith(color: AppColors.accent),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _DetailChip(icon: Icons.currency_rupee_outlined, label: Formatters.formatCurrencyShort(job.budget)),
                _DetailChip(icon: Icons.location_on_outlined, label: job.location),
                if (job.desiredCompletionDays != null)
                  _DetailChip(icon: Icons.schedule_outlined, label: '${job.desiredCompletionDays} days'),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              job.description,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            imagesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (images) {
                if ((images as List).isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reference Images',
                      style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 88,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final image = images[index];
                          return GestureDetector(
                            onTap: () => ImageViewer.showNetwork(context, image.imageUrl),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                image.imageUrl,
                                width: 88,
                                height: 88,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _immediateInfoCard() {
    final expired = _remaining == Duration.zero && job.expiresAt != null;
    final hours = _remaining.inHours;
    final minutes = _remaining.inMinutes.remainder(60);
    final seconds = _remaining.inSeconds.remainder(60);
    final timeText = expired
        ? 'Expired'
        : '${hours}h ${minutes}m ${seconds}s remaining';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: expired ? AppColors.errorLight : AppColors.glowOrange,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: expired ? AppColors.error.withValues(alpha: 0.3) : AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            expired ? Icons.timer_off_outlined : Icons.bolt,
            color: expired ? AppColors.error : AppColors.accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Immediate Service',
                  style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  timeText,
                  style: AppTypography.labelMedium.copyWith(
                    color: expired ? AppColors.error : AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptBid(BuildContext context, WidgetRef ref, String bidId, String providerId) async {
    final clientId = ref.read(currentUserIdProvider);
    if (clientId == null) return;

    try {
      await ref.read(
        acceptBidAndCreateContractProvider((bidId: bidId, jobId: job.id, clientId: clientId)).future,
      );

      ref.invalidate(jobBidsProvider(job.id));
      ref.invalidate(contractByJobProvider(job.id));
      ref.invalidate(clientJobsProvider);
      ref.invalidate(clientContractsProvider);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bid accepted. Contract created and chat enabled.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept bid: $e')),
      );
    }
  }

  Future<void> _deleteJob(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surfaceLight,
            title: Text('Delete Job', style: AppTypography.heading4.copyWith(color: AppColors.textPrimary)),
            content: Text(
              'Are you sure you want to delete this job?',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      await ref.read(deleteJobProvider(job.id).future);
      if (!context.mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete job: $e')),
      );
    }
  }

  Future<void> _showBidderProfile(BuildContext context, String providerId) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.9,
        child: _BidderProfileSheet(providerId: providerId),
      ),
    );
  }
}

class _BidderProfileSheet extends ConsumerWidget {
  final String providerId;

  const _BidderProfileSheet({required this.providerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userp.userProfileProvider(providerId));
    final providerProfileAsync = ref.watch(userp.providerProfileProvider(providerId));
    final ratingAsync = ref.watch(providerAverageRatingProvider(providerId));
    final portfolioAsync = ref.watch(providerPortfolioByUserProvider(providerId));
    final skillIdsAsync = ref.watch(userp.providerSkillIdsProvider(providerId));
    final contractsAsync = ref.watch(providerContractsByUserProvider(providerId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        title: Text('Bidder Profile', style: AppTypography.heading4.copyWith(color: AppColors.textPrimary)),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryColor)),
        error: (e, _) => Center(child: Text('Failed to load profile: $e', style: const TextStyle(color: AppColors.error))),
        data: (profile) {
          if (profile == null) {
            return Center(child: Text('Profile not found', style: TextStyle(color: AppColors.textSecondary)));
          }

          final providerProfile = providerProfileAsync.valueOrNull;
          final rating = ratingAsync.valueOrNull;
            final completedContracts = (contractsAsync.valueOrNull ?? const [])
              .where((c) => c.status == 'completed')
              .toList();
            final completedCount = completedContracts.length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                      ),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.surfaceLight,
                        child: Text(
                          _initials(profile.fullName),
                          style: AppTypography.heading4.copyWith(color: AppColors.primaryColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      profile.fullName,
                      textAlign: TextAlign.center,
                      style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Member since ${Formatters.formatDate(profile.createdAt)}',
                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Provider Details', style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary)),
                    const Divider(color: AppColors.divider),
                    if (rating != null) ...[
                      _row('Average Rating', '${rating.toStringAsFixed(1)}/5'),
                    ],
                    _row('Reliability Score', '${(providerProfile?.relScore ?? 5.0).toStringAsFixed(1)}/10'),
                    _row('Experience', '${providerProfile?.experienceYears ?? 0} years'),
                    _row('Hourly Rate', Formatters.formatCurrencyShort(providerProfile?.hourlyRate ?? 0)),
                    _row('Completed Projects', '$completedCount'),
                    _row('Verified', (providerProfile?.verified ?? false) ? 'Yes' : 'No'),
                    if (providerProfile?.bio?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 10),
                      Text('Bio', style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text(providerProfile!.bio!, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Skills
              skillIdsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (skillIds) {
                  if (skillIds.isEmpty) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Skills', style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary)),
                        const Divider(color: AppColors.divider),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: skillIds.map((id) {
                            final skillAsync = ref.watch(skillProvider(id));
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                skillAsync.valueOrNull?.name ?? 'Skill $id',
                                style: AppTypography.labelSmall.copyWith(color: AppColors.primaryColor),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text('Completed Contracts', style: AppTypography.heading4.copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              if (completedContracts.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text('No completed contracts yet.', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                )
              else
                Column(
                  children: completedContracts.map((contract) {
                    final jobAsync = ref.watch(jobProvider(contract.jobId));
                    final title = jobAsync.valueOrNull?.title ?? 'Project ${contract.jobId.substring(0, 8)}';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary)),
                          if (contract.providerRating != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Client Rating: ${contract.providerRating}/5',
                              style: AppTypography.caption.copyWith(color: AppColors.warning),
                            ),
                          ],
                          if (contract.reviewText?.trim().isNotEmpty == true) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Review: ${contract.reviewText}',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),
              Text('Past Works', style: AppTypography.heading4.copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              portfolioAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primaryColor)),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('Failed to load past works: $e', style: const TextStyle(color: AppColors.error)),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text('No past works shared yet.', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                    );
                  }

                  return Column(
                    children: items.map((portfolio) {
                      final imagesAsync = ref.watch(portfolioImagesProvider(portfolio.id));
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              portfolio.title,
                              style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary),
                            ),
                            if (portfolio.description?.trim().isNotEmpty == true) ...[
                              const SizedBox(height: 6),
                              Text(portfolio.description!, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                            ],
                            if (portfolio.cost != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                Formatters.formatCurrencyShort(portfolio.cost!),
                                style: AppTypography.labelLarge.copyWith(color: AppColors.primaryColor),
                              ),
                            ],
                            const SizedBox(height: 8),
                            imagesAsync.when(
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                              data: (images) {
                                if (images.isEmpty) return const SizedBox.shrink();
                                return SizedBox(
                                  height: 84,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: images.length,
                                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                                    itemBuilder: (context, index) {
                                      final image = images[index];
                                      return GestureDetector(
                                        onTap: () => ImageViewer.showNetwork(context, image.imageUrl),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(
                                            image.imageUrl,
                                            width: 84,
                                            height: 84,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  static Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
          Text(value, style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryColor),
          const SizedBox(width: 6),
          Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
