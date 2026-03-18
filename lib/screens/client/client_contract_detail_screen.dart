import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/contract_model.dart';
import '../../providers/bid_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/contract_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/user_provider.dart' as userp;
import '../../utils/formatters.dart';
import 'client_shell.dart';

class ClientContractDetailScreen extends ConsumerStatefulWidget {
  final ContractModel contract;

  const ClientContractDetailScreen({super.key, required this.contract});

  @override
  ConsumerState<ClientContractDetailScreen> createState() => _ClientContractDetailScreenState();
}

class _ClientContractDetailScreenState extends ConsumerState<ClientContractDetailScreen> {
  bool _processing = false;

  @override
  Widget build(BuildContext context) {
    final liveContractAsync = ref.watch(contractProvider(widget.contract.id));
    final contract = liveContractAsync.valueOrNull ?? widget.contract;
    final jobAsync = ref.watch(jobProvider(contract.jobId));
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
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Job Information', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const Divider(),
                  Text(jobAsync.valueOrNull?.title ?? 'Project ${contract.jobId.substring(0, 8)}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
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
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bid Information', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const Divider(),
                    Text('Bid Amount: ${Formatters.formatCurrencyShort(bidAsync.valueOrNull!.amount)}'),
                    if (bidAsync.valueOrNull!.estimatedDays != null) ...[
                      const SizedBox(height: 4),
                      Text('Estimated Timeline: ${bidAsync.valueOrNull!.estimatedDays} days'),
                    ],
                    if (bidAsync.valueOrNull!.message?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text('Note: ${bidAsync.valueOrNull!.message!}'),
                    ],
                    const SizedBox(height: 4),
                    Text('Status: ${bidAsync.valueOrNull!.status}'),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 10),

          // ── Contract Status ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Contract Status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const Divider(),
                  _StatusPill(status: contract.status),
                  const SizedBox(height: 8),
                  Text('Client: ${clientAsync.valueOrNull?.fullName ?? 'Client'}'),
                  const SizedBox(height: 4),
                  Text('Service Provider: ${providerAsync.valueOrNull?.fullName ?? 'Service Provider'}'),
                  const SizedBox(height: 4),
                  Text('Created: ${Formatters.formatDate(contract.createdAt)}'),
                  if (contract.startDate != null) ...[
                    const SizedBox(height: 4),
                    Text('Started: ${Formatters.formatDate(contract.startDate!)}'),
                  ],
                  if (contract.endDate != null) ...[
                    const SizedBox(height: 4),
                    Text('Ended: ${Formatters.formatDate(contract.endDate!)}'),
                  ],
                  if (contract.rating != null) ...[
                    const SizedBox(height: 8),
                    Text('Rating: ${contract.rating}/5'),
                  ],
                  if (contract.reviewText != null && contract.reviewText!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Review: ${contract.reviewText}'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (contract.status == 'work_submitted') ...[
            FilledButton.icon(
              onPressed: _processing ? null : () => _approveWork(contract.id),
              icon: _processing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.verified_outlined),
              label: const Text('Approve Submitted Work'),
            ),
            const SizedBox(height: 10),
          ],
          if (contract.status == 'completed' && contract.rating == null) ...[
            OutlinedButton.icon(
              onPressed: _processing ? null : () => _showReviewDialog(contract),
              icon: const Icon(Icons.star_outline),
              label: const Text('Rate And Review Provider'),
            ),
            const SizedBox(height: 10),
          ],
          FilledButton.icon(
            onPressed: () => _openChat(contract),
            icon: const Icon(Icons.chat_outlined),
            label: const Text('Open Chat'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveWork(String contractId) async {
    setState(() => _processing = true);
    try {
      await ref.read(approveSubmittedWorkProvider(contractId).future);
      ref.invalidate(contractProvider(contractId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Work approved. Contract marked as completed.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to approve work: $e')),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _showReviewDialog(ContractModel contract) async {
    final reviewController = TextEditingController();
    var selectedRating = 5;

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Rate This Provider'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 4,
                children: List.generate(5, (index) {
                  final star = index + 1;
                  return IconButton(
                    onPressed: () => setDialogState(() => selectedRating = star),
                    icon: Icon(
                      star <= selectedRating ? Icons.star : Icons.star_border,
                      color: const Color(0xFFCA8A04),
                    ),
                  );
                }),
              ),
              TextField(
                controller: reviewController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Review',
                  hintText: 'Share how the work went',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );

    if (submitted != true) return;

    setState(() => _processing = true);
    try {
      await ref.read(
        addReviewProvider(
          (
            contractId: contract.id,
            rating: selectedRating,
            reviewText: reviewController.text.trim(),
          ),
        ).future,
      );
      ref.invalidate(contractProvider(contract.id));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review added successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to add review: $e')),
      );
    } finally {
      reviewController.dispose();
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
            builder: (_) => ClientShell(initialIndex: 1, initialChatId: existing.id),
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
          builder: (_) => ClientShell(initialIndex: 1, initialChatId: created.id),
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

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (background, foreground, label) = switch (status) {
      'active' => (const Color(0xFFDCFCE7), const Color(0xFF166534), 'Active'),
      'work_submitted' => (const Color(0xFFFEF3C7), const Color(0xFF92400E), 'Work Submitted'),
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
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
