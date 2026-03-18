import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/contract_provider.dart';
import '../../providers/job_provider.dart';
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
      appBar: AppBar(title: const Text('Active Contracts')),
      body: RefreshIndicator(
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
                child: Center(child: Text('Failed to load contracts:\n$e', textAlign: TextAlign.center)),
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE4ECEC)),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Color(0xFFD7F3F1),
                          child: Icon(Icons.handshake_outlined, color: Color(0xFF0F766E)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                              const SizedBox(height: 6),
                              Text(_labelStatus(contract.status)),
                              const SizedBox(height: 4),
                              Text(
                                'Started ${Formatters.formatDate(contract.createdAt)}',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
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