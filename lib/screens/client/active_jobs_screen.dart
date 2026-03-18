import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/bid_provider.dart';
import '../../providers/contract_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/user_provider.dart' as userp;
import '../../utils/formatters.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';
import 'client_contract_detail_screen.dart';
import 'client_job_detail_screen.dart';

class ClientActiveJobsScreen extends ConsumerStatefulWidget {
  const ClientActiveJobsScreen({super.key});

  @override
  ConsumerState<ClientActiveJobsScreen> createState() => _ClientActiveJobsScreenState();
}

class _ClientActiveJobsScreenState extends ConsumerState<ClientActiveJobsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _jobStatusFilter = 'all';
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
    final jobsAsync = ref.watch(clientJobsProvider);
    final contractsAsync = ref.watch(clientContractsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Projects'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Posted (${jobsAsync.valueOrNull?.length ?? 0})'),
            Tab(text: 'Contracts (${contractsAsync.valueOrNull?.length ?? 0})'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(clientJobsProvider);
          ref.invalidate(clientContractsProvider);
          await Future.wait([
            ref.read(clientJobsProvider.future),
            ref.read(clientContractsProvider.future),
          ]);
        },
        child: TabBarView(
          controller: _tabController,
          children: [
            jobsAsync.when(
              loading: () => const LoadingWidget(message: 'Loading posted jobs...'),
              error: (e, _) => _ErrorList(message: 'Failed loading jobs: $e'),
              data: (jobs) {
                final filteredJobs = jobs.where((job) {
                  return _jobStatusFilter == 'all' || job.status == _jobStatusFilter;
                }).toList();

                if (jobs.isEmpty) {
                  return const EmptyStateWidget(
                    message: 'No projects posted yet.',
                    icon: Icons.work_outline,
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _StatusFilterBar(
                      statuses: const [
                        ('all', 'All'),
                        ('open', 'Out For Bid'),
                        ('in_progress', 'In Progress'),
                        ('completed', 'Completed'),
                        ('cancelled', 'Cancelled'),
                      ],
                      selected: _jobStatusFilter,
                      onSelected: (value) => setState(() => _jobStatusFilter = value),
                    ),
                    const SizedBox(height: 12),
                    if (filteredJobs.isEmpty)
                      const SizedBox(
                        height: 220,
                        child: EmptyStateWidget(
                          message: 'No posted projects match this status.',
                          icon: Icons.filter_alt_off_outlined,
                        ),
                      )
                    else
                      ...filteredJobs.map((job) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ProjectCard(
                              icon: Icons.assignment_outlined,
                              title: job.title,
                              subtitle: '${job.location} • ${_statusLabel(job.status)}',
                              status: job.status,
                              metaLeft: 'Budget',
                              metaLeftValue: Formatters.formatCurrencyShort(job.budget),
                              metaRight: 'Posted',
                              metaRightValue: Formatters.formatDate(job.createdAt),
                              onTap: () async {
                                final changed = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ClientJobDetailScreen(job: job),
                                  ),
                                );

                                if (changed == true) {
                                  ref.invalidate(clientJobsProvider);
                                  ref.invalidate(clientContractsProvider);
                                }
                              },
                            ),
                          )),
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
                        final jobAsync = ref.watch(jobProvider(contract.jobId));
                        final bidAsync = ref.watch(bidProvider(contract.bidId));
                        final providerProfileAsync = ref.watch(userp.userProfileProvider(contract.providerId));

                        final title = jobAsync.valueOrNull?.title ?? 'Project ${contract.jobId.substring(0, 8)}';
                        final providerName = providerProfileAsync.valueOrNull?.fullName ?? 'Provider';
                        final bidAmount = bidAsync.valueOrNull == null
                            ? 'Pending'
                            : Formatters.formatCurrencyShort(bidAsync.valueOrNull!.amount);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ProjectCard(
                            icon: Icons.handshake_outlined,
                            title: title,
                            subtitle: 'Provider: $providerName\nStatus: ${_statusLabel(contract.status)}',
                            status: contract.status,
                            metaLeft: 'Bid',
                            metaLeftValue: bidAmount,
                            metaRight: 'Started',
                            metaRightValue: Formatters.formatDate(contract.createdAt),
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
      'open' => 'Out for Bid',
      'in_progress' => 'In Progress',
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
  final VoidCallback onTap;

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
      'open' => (const Color(0xFFFEF3C7), const Color(0xFF92400E), 'Out For Bid'),
      'in_progress' => (const Color(0xFFDCFCE7), const Color(0xFF166534), 'In Progress'),
      'active' => (const Color(0xFFDCFCE7), const Color(0xFF166534), 'Active'),
      'work_submitted' => (const Color(0xFFFEF3C7), const Color(0xFF92400E), 'Work Submitted'),
      'completed' => (const Color(0xFFDBEAFE), const Color(0xFF1D4ED8), 'Completed'),
      'cancelled' => (const Color(0xFFFEE2E2), const Color(0xFF991B1B), 'Cancelled'),
      _ => (const Color(0xFFE5E7EB), const Color(0xFF374151), status),
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
