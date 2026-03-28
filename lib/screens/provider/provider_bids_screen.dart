import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/bid_provider.dart';
import '../../providers/job_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
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
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('My Bids', style: AppTypography.heading4.copyWith(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryColor,
        backgroundColor: AppColors.surfaceLight,
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
                  child: Text('Failed to load bids:\n$e', textAlign: TextAlign.center, style: TextStyle(color: AppColors.error)),
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
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                jobTitle,
                                style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
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
                            _BidMeta(label: 'Your bid', value: Formatters.formatCurrencyShort(bid.amount), valueColor: AppColors.primaryColor),
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
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textHint),
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
      'accepted' => (AppColors.successLight, AppColors.success),
      'rejected' => (AppColors.errorLight, AppColors.error),
      'withdrawn' => (AppColors.surfaceVariant, AppColors.textHint),
      _ => (AppColors.warningLight, AppColors.warning),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(color: foreground),
      ),
    );
  }
}

class _BidMeta extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _BidMeta({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.textHint),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.labelLarge.copyWith(color: valueColor ?? AppColors.textPrimary),
        ),
      ],
    );
  }
}
