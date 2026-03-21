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
      appBar: AppBar(
        title: const Text('Job Details'),
        actions: [
          IconButton(
            tooltip: 'Delete job',
            onPressed: (job.status == 'open' && contractAsync.valueOrNull == null)
                ? () => _deleteJob(context, ref)
                : null,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: RefreshIndicator(
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
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.handshake_outlined),
                    title: Text('Contract is ${contract.status}'),
                    subtitle: Text('Created on ${Formatters.formatDate(contract.createdAt)}'),
                    trailing: const Icon(Icons.chevron_right),
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
            const SizedBox(height: 8),
            Text('Bids', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            bidsAsync.when(
              loading: () => const SizedBox(height: 180, child: LoadingWidget(message: 'Loading bids...')),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(12),
                child: Text('Failed to load bids: $e'),
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

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    providerName,
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                Text(
                                  Formatters.formatCurrencyShort(bid.amount),
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('Status: ${bid.status}'),
                            if (bid.estimatedDays != null) ...[
                              const SizedBox(height: 2),
                              Text('Estimated days: ${bid.estimatedDays}'),
                            ],
                            if (bid.message != null && bid.message!.trim().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(bid.message!),
                            ],
                            const SizedBox(height: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _showBidderProfile(context, bid.providerId),
                                  icon: const Icon(Icons.person_outline),
                                  label: const Text('View Profile'),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 8,
                                  children: [
                                    FilledButton(
                                      onPressed: (bid.status != 'pending' || isAcceptedContract)
                                          ? null
                                          : () => _acceptBid(context, ref, bid.id, bid.providerId),
                                      child: Text(isAcceptedContract ? 'Accepted' : 'Accept'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
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

  Widget _jobCard(JobModel job, AsyncValue imagesAsync) {
    final uiStatus = switch (job.status) {
      'open' => 'Out for Bid',
      'in_progress' => 'In Progress',
      'completed' => 'Completed',
      'cancelled' => 'Cancelled',
      'deleted' => 'Deleted',
      _ => job.status,
    };

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFF7FBFB), Color(0xFFE7F6F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 24),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _JobStatusPill(label: uiStatus),
                    if (job.isImmediate) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt, size: 14, color: Colors.orange.shade800),
                            const SizedBox(width: 4),
                            Text(
                              'Immediate',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
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
            Text(job.description, style: TextStyle(color: Colors.grey.shade800, height: 1.45)),
            const SizedBox(height: 16),
            imagesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (images) {
                if ((images as List).isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Reference Images', style: TextStyle(fontWeight: FontWeight.w700)),
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

    return Card(
      color: expired ? Colors.red.shade50 : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              expired ? Icons.timer_off_outlined : Icons.bolt,
              color: expired ? Colors.red : Colors.orange.shade800,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Immediate Service',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeText,
                    style: TextStyle(
                      color: expired ? Colors.red : Colors.orange.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
            title: const Text('Delete Job'),
            content: const Text('Are you sure you want to delete this job?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
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
      backgroundColor: const Color(0xFFF7FAFA),
      appBar: AppBar(title: const Text('Bidder Profile')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load profile: $e')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profile not found'));
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    CircleAvatar(radius: 32, child: Text(_initials(profile.fullName))),
                    const SizedBox(height: 12),
                    Text(
                      profile.fullName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Member since ${Formatters.formatDate(profile.createdAt)}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Provider Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const Divider(),
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
                        const Text('Bio', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(providerProfile!.bio!),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Skills
              skillIdsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (skillIds) {
                  if (skillIds.isEmpty) return const SizedBox.shrink();
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Skills', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          const Divider(),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: skillIds.map((id) {
                              final skillAsync = ref.watch(skillProvider(id));
                              return Chip(
                                label: Text(skillAsync.valueOrNull?.name ?? 'Skill $id'),
                                visualDensity: VisualDensity.compact,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Text('Completed Contracts', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (completedContracts.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('No completed contracts yet.'),
                  ),
                )
              else
                Column(
                  children: completedContracts.map((contract) {
                    final jobAsync = ref.watch(jobProvider(contract.jobId));
                    final title = jobAsync.valueOrNull?.title ?? 'Project ${contract.jobId.substring(0, 8)}';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                            if (contract.providerRating != null) ...[
                              const SizedBox(height: 4),
                              Text('Client Rating: ${contract.providerRating}/5'),
                            ],
                            if (contract.reviewText?.trim().isNotEmpty == true) ...[
                              const SizedBox(height: 4),
                              Text('Review: ${contract.reviewText}'),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 12),
              Text('Past Works', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              portfolioAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('Failed to load past works: $e'),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(14),
                        child: Text('No past works shared yet.'),
                      ),
                    );
                  }

                  return Column(
                    children: items.map((portfolio) {
                      final imagesAsync = ref.watch(portfolioImagesProvider(portfolio.id));
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                portfolio.title,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              if (portfolio.description?.trim().isNotEmpty == true) ...[
                                const SizedBox(height: 6),
                                Text(portfolio.description!),
                              ],
                              if (portfolio.cost != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  Formatters.formatCurrencyShort(portfolio.cost!),
                                  style: const TextStyle(fontWeight: FontWeight.w600),
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
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.teal.shade700),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

class _JobStatusPill extends StatelessWidget {
  final String label;

  const _JobStatusPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFD7F3F1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF0B6E6E),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
