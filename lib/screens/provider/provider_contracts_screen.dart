import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/contract_provider.dart';
import '../../providers/job_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';
import 'provider_contract_detail_screen.dart';

class ProviderContractsScreen extends ConsumerWidget {
  const ProviderContractsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contractsAsync = ref.watch(providerContractsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Active Contracts', style: AppTypography.heading4.copyWith(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryColor,
        backgroundColor: AppColors.surfaceLight,
        onRefresh: () async {
          ref.invalidate(providerContractsProvider);
          await ref.read(providerContractsProvider.future);
        },
        child: contractsAsync.when(
          loading: () => const LoadingWidget(message: 'Loading contracts...'),
          error: (e, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: 500,
                child: Center(child: Text('Failed to load contracts:\n$e', textAlign: TextAlign.center, style: TextStyle(color: AppColors.error))),
              ),
            ],
          ),
          data: (contracts) {
            if (contracts.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(
                    height: 500,
                    child: EmptyStateWidget(
                      message: 'No contracts yet. Accepted bids become contracts here.',
                      icon: Icons.handshake_outlined,
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: contracts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final contract = contracts[index];
                final jobAsync = ref.watch(jobProvider(contract.jobId));
                final title = jobAsync.valueOrNull?.title ?? 'Project ${contract.jobId.substring(0, 8)}';

                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProviderContractDetailScreen(contract: contract),
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
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.surfaceVariant,
                          child: Icon(Icons.handshake_outlined, color: AppColors.primaryColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Text(_labelStatus(contract.status), style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              Text(
                                'Started ${Formatters.formatDate(contract.createdAt)}',
                                style: AppTypography.caption.copyWith(color: AppColors.textHint),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: AppColors.textHint),
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

  String _labelStatus(String status) {
    return switch (status) {
      'work_submitted' => 'Work submitted for approval',
      'completed' => 'Completed',
      'cancelled' => 'Cancelled',
      _ => 'Active',
    };
  }
}
