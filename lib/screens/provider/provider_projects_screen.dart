import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/bid_provider.dart';
import '../../providers/contract_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/user_provider.dart' as userp;
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
  String _bidStatusFilter = 'all';
  String _contractStatusFilter = 'all';

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
    final bidsAsync = ref.watch(providerBidsProvider);
    final contractsAsync = ref.watch(providerContractsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Bids (${bidsAsync.valueOrNull?.length ?? 0})'),
            Tab(text: 'Contracts (${contractsAsync.valueOrNull?.length ?? 0})'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(providerBidsProvider);
          ref.invalidate(providerContractsProvider);
          await Future.wait([
            ref.read(providerBidsProvider.future),
            ref.read(providerContractsProvider.future),
          ]);
        },
        child: TabBarView(
          controller: _tabController,
          children: [
            bidsAsync.when(
              loading: () => const LoadingWidget(message: 'Loading bids...'),
              error: (e, _) => _ErrorList(message: 'Failed loading bids: $e'),
              data: (bids) {
                final filteredBids = bids.where((bid) {
                  return _bidStatusFilter == 'all' || bid.status == _bidStatusFilter;
                }).toList();

                if (bids.isEmpty) {
                  return const EmptyStateWidget(
                    message: 'No bids yet. Place bids from Fresh Opportunities.',
                    icon: Icons.assignment_outlined,
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _StatusFilterBar(
                      statuses: const [
                        ('all', 'All'),
                        ('pending', 'Pending'),
                        ('accepted', 'Accepted'),
                        ('rejected', 'Rejected'),
                        ('withdrawn', 'Withdrawn'),
                      ],
                      selected: _bidStatusFilter,
                      onSelected: (value) => setState(() => _bidStatusFilter = value),
                    ),
                    const SizedBox(height: 12),
                    if (filteredBids.isEmpty)
                      const SizedBox(
                        height: 220,
                        child: EmptyStateWidget(
                          message: 'No bids match this status.',
                          icon: Icons.filter_alt_off_outlined,
                        ),
                      )
                    else
                      ...filteredBids.map((bid) {
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
                final filteredContracts = contracts.where((contract) {
                  return _contractStatusFilter == 'all' || contract.status == _contractStatusFilter;
                }).toList();

                if (contracts.isEmpty) {
                  return const EmptyStateWidget(
                    message: 'No contracts yet.',
                    icon: Icons.handshake_outlined,
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _StatusFilterBar(
                      statuses: const [
                        ('all', 'All'),
                        ('active', 'Active'),
                        ('work_submitted', 'Work Submitted'),
                        ('completed', 'Completed'),
                        ('cancelled', 'Cancelled'),
                      ],
                      selected: _contractStatusFilter,
                      onSelected: (value) => setState(() => _contractStatusFilter = value),
                    ),
                    const SizedBox(height: 12),
                    if (filteredContracts.isEmpty)
                      const SizedBox(
                        height: 220,
                        child: EmptyStateWidget(
                          message: 'No contracts match this status.',
                          icon: Icons.filter_alt_off_outlined,
                        ),
                      )
                    else
                      ...filteredContracts.map((contract) {
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
      'withdrawn' => 'Withdrawn',
      'active' => 'Active',
      'work_submitted' => 'Work Submitted',
      'completed' => 'Completed',
      'cancelled' => 'Cancelled',
      _ => status,
    };
  }
}

class _StatusFilterBar extends StatelessWidget {
  final List<(String, String)> statuses;
  final String selected;
  final ValueChanged<String> onSelected;

  const _StatusFilterBar({
    required this.statuses,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: statuses.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (value, label) = statuses[index];
          return ChoiceChip(
            label: Text(label),
            selected: selected == value,
            onSelected: (_) => onSelected(value),
          );
        },
      ),
    );
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
          border: Border.all(color: const Color(0xFFE5ECEC)),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFFE6F4F3),
                  child: Icon(icon, size: 17, color: const Color(0xFF0B6E6E)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                _StatusPill(status: status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade700),
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
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
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
      'accepted' => (const Color(0xFFDCFCE7), const Color(0xFF166534), 'Accepted'),
      'active' => (const Color(0xFFDCFCE7), const Color(0xFF166534), 'Active'),
      'work_submitted' => (const Color(0xFFFEF3C7), const Color(0xFF92400E), 'Work Submitted'),
      'completed' => (const Color(0xFFDBEAFE), const Color(0xFF1D4ED8), 'Completed'),
      'rejected' => (const Color(0xFFFEE2E2), const Color(0xFF991B1B), 'Rejected'),
      'cancelled' => (const Color(0xFFFEE2E2), const Color(0xFF991B1B), 'Cancelled'),
      'withdrawn' => (const Color(0xFFE5E7EB), const Color(0xFF374151), 'Withdrawn'),
      _ => (const Color(0xFFFEF3C7), const Color(0xFF92400E), 'Pending'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: foreground, fontSize: 11, fontWeight: FontWeight.w700),
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
              child: Text(message, textAlign: TextAlign.center),
            ),
          ),
        ),
      ],
    );
  }
}
