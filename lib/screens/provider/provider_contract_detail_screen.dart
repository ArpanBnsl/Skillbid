import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/contract_model.dart';
import '../../providers/bid_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/contract_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/user_provider.dart' as userp;
import '../../utils/formatters.dart';
import '../../widgets/common/image_viewer.dart';
import 'provider_shell.dart';

class ProviderContractDetailScreen extends ConsumerStatefulWidget {
  final ContractModel contract;

  const ProviderContractDetailScreen({super.key, required this.contract});

  @override
  ConsumerState<ProviderContractDetailScreen> createState() => _ProviderContractDetailScreenState();
}

class _ProviderContractDetailScreenState extends ConsumerState<ProviderContractDetailScreen> {
  bool _processing = false;

  @override
  Widget build(BuildContext context) {
    final liveContractAsync = ref.watch(contractProvider(widget.contract.id));
    final contract = liveContractAsync.valueOrNull ?? widget.contract;
    final jobAsync = ref.watch(jobProvider(contract.jobId));
    final jobImagesAsync = ref.watch(jobImagesProvider(contract.jobId));
    final clientAsync = ref.watch(userp.userProfileProvider(contract.clientId));
    final providerAsync = ref.watch(userp.userProfileProvider(contract.providerId));
    final bidAsync = ref.watch(bidProvider(contract.bidId));

    return Scaffold(
      appBar: AppBar(title: const Text('Contract Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Job Information ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Job Information', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const Divider(),
                  Text(
                    jobAsync.valueOrNull?.title ?? 'Project ${contract.jobId.substring(0, 8)}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                  ),
                  if (jobAsync.valueOrNull?.description != null) ...[
                    const SizedBox(height: 6),
                    Text(jobAsync.valueOrNull!.description, style: TextStyle(color: Colors.grey.shade700)),
                  ],
                  const SizedBox(height: 6),
                  if (jobAsync.valueOrNull != null) ...[
                    Text('Location: ${jobAsync.valueOrNull!.location}'),
                    const SizedBox(height: 4),
                    Text('Budget: ${Formatters.formatCurrencyShort(jobAsync.valueOrNull!.budget)}'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── Bid Information ──
          if (bidAsync.valueOrNull != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bid Information', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const Divider(),
                    Text('Agreed Amount: ${Formatters.formatCurrencyShort(bidAsync.valueOrNull!.amount)}'),
                    if (bidAsync.valueOrNull!.estimatedDays != null) ...[
                      const SizedBox(height: 4),
                      Text('Timeline: ${bidAsync.valueOrNull!.estimatedDays} days'),
                    ],
                    if (bidAsync.valueOrNull!.message?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text('Bid Note: ${bidAsync.valueOrNull!.message!}'),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 10),

          // ── Contract Status ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Contract Status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const Divider(),
                  _ContractStatusPill(status: contract.status),
                  const SizedBox(height: 10),
                  Text('Provider: ${providerAsync.valueOrNull?.fullName ?? 'Provider'}'),
                  const SizedBox(height: 6),
                  Text('Client: ${clientAsync.valueOrNull?.fullName ?? 'Client'}'),
                  const SizedBox(height: 6),
                  Text('Started: ${Formatters.formatDate(contract.createdAt)}'),
                  if (contract.rating != null) ...[
                    const SizedBox(height: 10),
                    Text('Client Rating: ${contract.rating}/5'),
                  ],
                  if (contract.reviewText?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 6),
                    Text('Review: ${contract.reviewText}'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          jobImagesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (images) {
              if (images.isEmpty) return const SizedBox.shrink();
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Client Reference Images', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 90,
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
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          if (contract.status == 'active') ...[
            FilledButton.icon(
              onPressed: _processing ? null : () => _submitWork(contract.id),
              icon: _processing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file_outlined),
              label: const Text('Submit Work For Approval'),
            ),
            const SizedBox(height: 10),
          ],
          FilledButton.icon(
            onPressed: () => _openChat(contract),
            icon: const Icon(Icons.chat_outlined),
            label: const Text('Open Contract Chat'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitWork(String contractId) async {
    setState(() => _processing = true);
    try {
      await ref.read(submitWorkProvider(contractId).future);
      ref.invalidate(contractProvider(contractId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Work submitted. The client can now approve it.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to submit work: $e')),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _openChat(ContractModel contract) async {
    try {
      final existing = await ref.read(chatByContractProvider(contract.id).future);
      if (existing != null) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => ProviderShell(initialIndex: 2, initialChatId: existing.id),
          ),
          (route) => false,
        );
        return;
      }

      final created = await ref.read(
        createChatProvider(
          (
            contractId: contract.id,
            clientId: contract.clientId,
            providerId: contract.providerId,
          ),
        ).future,
      );

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => ProviderShell(initialIndex: 2, initialChatId: created.id),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open chat: $e')),
      );
    }
  }
}

class _ContractStatusPill extends StatelessWidget {
  final String status;

  const _ContractStatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (background, foreground, label) = switch (status) {
      'active' => (const Color(0xFFDCFCE7), const Color(0xFF166534), 'Active'),
      'work_submitted' => (const Color(0xFFFEF3C7), const Color(0xFF92400E), 'Awaiting Approval'),
      'completed' => (const Color(0xFFDBEAFE), const Color(0xFF1D4ED8), 'Completed'),
      'cancelled' => (const Color(0xFFFEE2E2), const Color(0xFF991B1B), 'Cancelled'),
      _ => (const Color(0xFFE5E7EB), const Color(0xFF374151), status),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
      ),
    );
  }
}