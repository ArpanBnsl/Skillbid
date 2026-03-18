import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/bid_provider.dart';
import '../../providers/job_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';
import 'provider_job_detail_screen.dart';

class ProviderBidsScreen extends ConsumerWidget {
  const ProviderBidsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bidsAsync = ref.watch(providerBidsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Bids')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(providerBidsProvider);
          await ref.read(providerBidsProvider.future);
        },
        child: bidsAsync.when(
          loading: () => const LoadingWidget(message: 'Loading bids...'),
          error: (e, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: 500,
                child: Center(
                  child: Text('Failed to load bids:\n$e', textAlign: TextAlign.center),
                ),
              ),
            ],
          ),
          data: (bids) {
            if (bids.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(
                    height: 500,
                    child: EmptyStateWidget(
                      message: 'No bids yet. Place bids from the Jobs tab.',
                      icon: Icons.assignment_outlined,
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: bids.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final bid = bids[i];
                final jobAsync = ref.watch(jobProvider(bid.jobId));
                final job = jobAsync.valueOrNull;
                final jobTitle = job?.title ?? 'Job ${bid.jobId.substring(0, 8)}';

                return InkWell(
                  borderRadius: BorderRadius.circular(18),
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
                  child: Ink(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE4ECEC)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                jobTitle,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                              ),
                            ),
                            _BidStatusBadge(status: bid.status),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _BidMeta(label: 'Your bid', value: Formatters.formatCurrencyShort(bid.amount)),
                            if (bid.estimatedDays != null)
                              _BidMeta(label: 'Timeline', value: '${bid.estimatedDays} days'),
                            _BidMeta(label: 'Submitted', value: Formatters.formatDate(bid.createdAt)),
                          ],
                        ),
                        if (bid.message?.trim().isNotEmpty == true) ...[
                          const SizedBox(height: 12),
                          Text(
                            bid.message!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _BidStatusBadge extends StatelessWidget {
  final String status;

  const _BidStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      'accepted' => (const Color(0xFFDCFCE7), const Color(0xFF166534)),
      'rejected' => (const Color(0xFFFEE2E2), const Color(0xFF991B1B)),
      'withdrawn' => (const Color(0xFFE5E7EB), const Color(0xFF374151)),
      _ => (const Color(0xFFFEF3C7), const Color(0xFF92400E)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _BidMeta extends StatelessWidget {
  final String label;
  final String value;

  const _BidMeta({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
