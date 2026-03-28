import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/job_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';
import 'provider_job_detail_screen.dart';

class ProviderJobsScreen extends ConsumerWidget {
  const ProviderJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(availableJobsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Browse Jobs', style: AppTypography.heading4.copyWith(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryColor,
        backgroundColor: AppColors.surfaceLight,
        onRefresh: () async {
          ref.invalidate(availableJobsProvider);
          await ref.read(availableJobsProvider.future);
        },
        child: jobsAsync.when(
          loading: () => const LoadingWidget(message: 'Loading available jobs...'),
          error: (e, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: 500,
                child: Center(
                  child: Text('Failed to load jobs:\n$e', textAlign: TextAlign.center, style: TextStyle(color: AppColors.error)),
                ),
              ),
            ],
          ),
          data: (jobs) {
            if (jobs.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(
                    height: 500,
                    child: EmptyStateWidget(
                      message: 'No open jobs right now.',
                      icon: Icons.work_off_outlined,
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: jobs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final job = jobs[i];

                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
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
                      borderRadius: BorderRadius.circular(20),
                      color: AppColors.surfaceLight,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                job.title,
                                style: AppTypography.bodyLarge.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                Formatters.formatCurrencyShort(job.budget),
                                style: AppTypography.labelMedium.copyWith(color: AppColors.primaryColor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          job.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.35),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _MetaChip(icon: Icons.location_on_outlined, label: job.location),
                            if (job.desiredCompletionDays != null)
                              _MetaChip(
                                icon: Icons.schedule_outlined,
                                label: '${job.desiredCompletionDays} days',
                              ),
                            _MetaChip(
                              icon: Icons.access_time_outlined,
                              label: Formatters.formatTimeAgo(job.createdAt),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Spacer(),
                            Text(
                              'View details',
                              style: AppTypography.labelMedium.copyWith(color: AppColors.primaryColor),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.arrow_forward, size: 18, color: AppColors.primaryColor),
                          ],
                        ),
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

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryColor),
          const SizedBox(width: 6),
          Text(label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
