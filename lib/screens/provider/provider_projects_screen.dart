import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/bid_provider.dart';
import '../../providers/contract_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/user_provider.dart' as userp;
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';
import 'provider_contract_detail_screen.dart';
import 'provider_job_detail_screen.dart';

class ProviderProjectsScreen extends ConsumerStatefulWidget {
  const ProviderProjectsScreen({super.key});

  @override
  ConsumerState<ProviderProjectsScreen> createState() => _ProviderProjectsScreenState();
}

class _ProviderProjectsScreenState extends ConsumerState<ProviderProjectsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bidsAsync = ref.watch(providerPendingBidsProvider);
    final contractsAsync = ref.watch(providerActiveContractsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Projects', style: AppTypography.heading4.copyWith(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryColor,
          indicatorWeight: 3,
          labelColor: AppColors.primaryColor,
          unselectedLabelColor: AppColors.textHint,
          labelStyle: AppTypography.labelLarge,
          tabs: [
            Tab(text: 'Bids (${bidsAsync.valueOrNull?.length ?? 0})'),
            Tab(text: 'Contracts (${contractsAsync.valueOrNull?.length ?? 0})'),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryColor,
        backgroundColor: AppColors.surfaceLight,
        onRefresh: () async {
          ref.invalidate(providerBidsProvider);
          ref.invalidate(providerPendingBidsProvider);
          ref.invalidate(providerContractsProvider);
          ref.invalidate(providerActiveContractsProvider);
          await Future.wait([
            ref.read(providerPendingBidsProvider.future),
            ref.read(providerActiveContractsProvider.future),
          ]);
        },
        child: TabBarView(
          controller: _tabController,
          children: [
            bidsAsync.when(
              loading: () => const LoadingWidget(message: 'Loading bids...'),
              error: (e, _) => _ErrorList(message: 'Failed loading bids: $e'),
              data: (bids) {
                if (bids.isEmpty) {
                  return const EmptyStateWidget(
                    message: 'No open bids right now.',
                    icon: Icons.assignment_outlined,
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ...bids.map((bid) {
                        final jobAsync = ref.watch(jobProvider(bid.jobId));
                        final job = jobAsync.valueOrNull;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ProjectCard(
                            icon: Icons.assignment_outlined,
                            title: job?.title ?? 'Job ${bid.jobId.substring(0, 8)}',
                            subtitle: job == null
                                ? 'Bid status: ${_statusLabel(bid.status)}'
                                : '${job.location} • ${_statusLabel(bid.status)}',
                            status: bid.status,
                            metaLeft: 'Your bid',
                            metaLeftValue: Formatters.formatCurrencyShort(bid.amount),
                            metaRight: 'Submitted',
                            metaRightValue: Formatters.formatDate(bid.createdAt),
                            onTap: job == null
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProviderJobDetailScreen(job: job),
                                      ),
                                    );
                                  },
                          ),
                        );
                      }),
                  ],
                );
              },
            ),
            contractsAsync.when(
              loading: () => const LoadingWidget(message: 'Loading contracts...'),
              error: (e, _) => _ErrorList(message: 'Failed loading contracts: $e'),
              data: (contracts) {
                if (contracts.isEmpty) {
                  return const EmptyStateWidget(
                    message: 'No active contracts yet.',
                    icon: Icons.handshake_outlined,
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ...contracts.map((contract) {
                        final bidAsync = ref.watch(bidProvider(contract.bidId));
                        final jobAsync = ref.watch(jobProvider(contract.jobId));
                        final clientAsync = ref.watch(userp.userProfileProvider(contract.clientId));
                        final bidAmount = bidAsync.valueOrNull == null
                            ? 'Pending'
                            : Formatters.formatCurrencyShort(bidAsync.valueOrNull!.amount);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ProjectCard(
                            icon: Icons.handshake_outlined,
                            title: jobAsync.valueOrNull?.title ?? 'Project ${contract.jobId.substring(0, 8)}',
                            subtitle: 'Client: ${clientAsync.valueOrNull?.fullName ?? 'Client'}\nStatus: ${_statusLabel(contract.status)}',
                            status: contract.status,
                            metaLeft: 'Bid',
                            metaLeftValue: bidAmount,
                            metaRight: 'Started',
                            metaRightValue: Formatters.formatDate(contract.createdAt),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProviderContractDetailScreen(contract: contract),
                                ),
                              );
                            },
                          ),
                        );
                      }),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    return switch (status) {
      'pending' => 'Pending',
      'accepted' => 'Accepted',
      'rejected' => 'Rejected',
      'cancelled' => 'Cancelled',
      'active' => 'Active',
      'completed' => 'Completed',
      'terminated' => 'Terminated',
      _ => status,
    };
  }
}

class _ProjectCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final String metaLeft;
  final String metaLeftValue;
  final String metaRight;
  final String metaRightValue;
  final VoidCallback? onTap;

  const _ProjectCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.metaLeft,
    required this.metaLeftValue,
    required this.metaRight,
    required this.metaRightValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          color: AppColors.surfaceLight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.surfaceVariant,
                  child: Icon(icon, size: 17, color: AppColors.primaryColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                  ),
                ),
                _StatusPill(status: status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _CardMeta(label: metaLeft, value: metaLeftValue)),
                Expanded(child: _CardMeta(label: metaRight, value: metaRightValue)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CardMeta extends StatelessWidget {
  final String label;
  final String value;

  const _CardMeta({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption.copyWith(color: AppColors.textHint)),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary)),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (background, foreground, label) = switch (status) {
      'accepted' => (AppColors.successLight, AppColors.success, 'Accepted'),
      'active' => (AppColors.successLight, AppColors.success, 'Active'),
      'completed' => (AppColors.infoLight, AppColors.info, 'Completed'),
      'rejected' => (AppColors.errorLight, AppColors.error, 'Rejected'),
      'cancelled' => (AppColors.errorLight, AppColors.error, 'Cancelled'),
      'terminated' => (AppColors.errorLight, AppColors.error, 'Terminated'),
      _ => (AppColors.warningLight, AppColors.warning, 'Pending'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(color: foreground),
      ),
    );
  }
}

class _ErrorList extends StatelessWidget {
  final String message;

  const _ErrorList({required this.message});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 500,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(message, textAlign: TextAlign.center, style: TextStyle(color: AppColors.error)),
            ),
          ),
        ),
      ],
    );
  }
}
