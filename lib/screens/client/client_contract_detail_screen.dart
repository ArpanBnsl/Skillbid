import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../config/app_constants.dart';
import '../../models/contract_model.dart';
import '../../providers/bid_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/contract_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/user_provider.dart' as userp;
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../utils/formatters.dart';
import 'client_shell.dart';
import 'live_tracking_screen.dart';

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
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        title: Text('Contract Details', style: AppTypography.heading4.copyWith(color: AppColors.textPrimary)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Job Information
          _SectionCard(
            title: 'Job Information',
            children: [
              Text(
                jobAsync.valueOrNull?.title ?? 'Project ${contract.jobId.substring(0, 8)}',
                style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary, fontSize: 16),
              ),
              if (jobAsync.valueOrNull?.description != null) ...[
                const SizedBox(height: 6),
                Text(
                  jobAsync.valueOrNull!.description,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: 6),
              if (jobAsync.valueOrNull != null) ...[
                _InfoRow(label: 'Location', value: jobAsync.valueOrNull!.location),
                _InfoRow(label: 'Budget', value: Formatters.formatCurrencyShort(jobAsync.valueOrNull!.budget)),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Bid Information
          if (bidAsync.valueOrNull != null)
            _SectionCard(
              title: 'Bid Information',
              children: [
                _InfoRow(label: 'Bid Amount', value: Formatters.formatCurrencyShort(bidAsync.valueOrNull!.amount), highlight: true),
                if (bidAsync.valueOrNull!.estimatedDays != null)
                  _InfoRow(label: 'Estimated Timeline', value: '${bidAsync.valueOrNull!.estimatedDays} days'),
                if (bidAsync.valueOrNull!.message?.trim().isNotEmpty == true)
                  _InfoRow(label: 'Note', value: bidAsync.valueOrNull!.message!),
                _InfoRow(label: 'Status', value: bidAsync.valueOrNull!.status),
              ],
            ),
          const SizedBox(height: 10),

          // Contract Status
          _SectionCard(
            title: 'Contract Status',
            children: [
              _StatusPill(status: contract.status),
              const SizedBox(height: 10),
              _InfoRow(label: 'Client', value: clientAsync.valueOrNull?.fullName ?? 'Client'),
              _InfoRow(label: 'Service Provider', value: providerAsync.valueOrNull?.fullName ?? 'Service Provider'),
              _InfoRow(label: 'Created', value: Formatters.formatDate(contract.createdAt)),
              if (contract.startDate != null)
                _InfoRow(label: 'Started', value: Formatters.formatDate(contract.startDate!)),
              if (contract.endDate != null)
                _InfoRow(label: 'Ended', value: Formatters.formatDate(contract.endDate!)),
              if (contract.workSubmittedAt != null)
                _InfoRow(label: 'Work Submitted', value: Formatters.formatDateTime(contract.workSubmittedAt!)),
              if (contract.providerRating != null) ...[
                const SizedBox(height: 6),
                _InfoRow(label: 'Your Rating For Provider', value: '${contract.providerRating}/5'),
              ],
              if (contract.clientRating != null)
                _InfoRow(label: 'Provider Rating For You', value: '${contract.clientRating}/5'),
              if (contract.reviewText != null && contract.reviewText!.trim().isNotEmpty)
                _InfoRow(label: 'Review', value: contract.reviewText!),
              if (contract.terminatedBy != null)
                _InfoRow(label: 'Terminated By', value: contract.terminatedBy!, isError: true),
            ],
          ),
          const SizedBox(height: 16),

          // Action buttons
          if (contract.status == AppConstants.contractStatusActive) ...[
            if (contract.trackingEnabled) ...[
              _ActionButton(
                icon: Icons.my_location_outlined,
                label: 'Track Provider',
                gradient: AppColors.primaryGradient,
                textColor: AppColors.textDark,
                onPressed: () {
                  final job = jobAsync.valueOrNull;
                  final jobLoc = (job?.jobLat != null && job?.jobLng != null)
                      ? LatLng(job!.jobLat!, job.jobLng!)
                      : null;
                  if (jobLoc == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Job location not available for tracking.')),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LiveTrackingScreen(
                        contract: contract,
                        jobLocation: jobLoc,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
            _ActionButton(
              icon: _processing ? null : Icons.verified_outlined,
              label: 'Mark Contract Completed',
              gradient: AppColors.primaryGradient,
              textColor: AppColors.textDark,
              isLoading: _processing,
              onPressed: (_processing || contract.workSubmittedAt == null)
                  ? null
                  : () => _completeContract(contract.id),
            ),
            if (contract.workSubmittedAt == null) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Provider must submit work before approval.',
                  style: AppTypography.captionSmall.copyWith(color: AppColors.textHint),
                ),
              ),
            ],
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _processing ? null : () => _confirmTerminate(contract.id),
              icon: const Icon(Icons.cancel_outlined),
              label: Text('Terminate Contract', style: AppTypography.buttonText.copyWith(color: AppColors.error)),
            ),
            const SizedBox(height: 10),
          ],
          if (contract.status == AppConstants.contractStatusCompleted && contract.providerRating == null) ...[
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.warning,
                side: const BorderSide(color: AppColors.warning),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _processing ? null : () => _showReviewDialog(contract),
              icon: const Icon(Icons.star_outline),
              label: Text('Rate And Review Provider', style: AppTypography.buttonText.copyWith(color: AppColors.warning)),
            ),
            const SizedBox(height: 10),
          ],
          _ActionButton(
            icon: Icons.chat_outlined,
            label: 'Open Chat',
            gradient: AppColors.purpleGradient,
            textColor: AppColors.textPrimary,
            onPressed: () => _openChat(contract, jobAsync.valueOrNull?.title),
          ),
        ],
      ),
    );
  }

  Future<void> _completeContract(String contractId) async {
    setState(() => _processing = true);
    try {
      await ref.read(completeContractProvider(contractId).future);
      ref.invalidate(contractProvider(contractId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contract marked as completed.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to complete contract: $e')),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _confirmTerminate(String contractId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: Text('Terminate Contract', style: AppTypography.heading4.copyWith(color: AppColors.textPrimary)),
        content: Text(
          'Are you sure you want to terminate this contract? This cannot be undone.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No', style: TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Terminate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _processing = true);
    try {
      await ref.read(
        terminateContractProvider(
          (
            contractId: contractId,
            terminatedBy: AppConstants.contractTerminatedByClient,
          ),
        ).future,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contract terminated successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to terminate contract: $e')),
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
          backgroundColor: AppColors.surfaceLight,
          title: Text('Rate This Provider', style: AppTypography.heading4.copyWith(color: AppColors.textPrimary)),
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
                      color: AppColors.warning,
                    ),
                  );
                }),
              ),
              TextField(
                controller: reviewController,
                maxLines: 4,
                style: const TextStyle(color: AppColors.textPrimary),
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
              child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.textDark,
              ),
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

  Future<void> _openChat(ContractModel contract, String? initialTitle) async {
    try {
      final existing = await ref.read(chatByContractProvider(contract.id).future);
      if (existing != null) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => ClientShell(
              initialIndex: 1,
              initialChatId: existing.id,
              initialChatTitle: initialTitle,
            ),
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
          builder: (_) => ClientShell(
            initialIndex: 1,
            initialChatId: created.id,
            initialChatTitle: initialTitle,
          ),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary, fontSize: 15)),
          const Divider(color: AppColors.divider),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final bool isError;

  const _InfoRow({
    required this.label,
    required this.value,
    this.highlight = false,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                color: isError
                    ? AppColors.error
                    : highlight
                        ? AppColors.primaryColor
                        : AppColors.textPrimary,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (background, foreground, label) = switch (status) {
      'active' => (AppColors.successLight, AppColors.success, 'Active'),
      'completed' => (AppColors.infoLight, AppColors.info, 'Completed'),
      'terminated' => (AppColors.errorLight, AppColors.error, 'Terminated'),
      _ => (AppColors.surfaceVariant, AppColors.textSecondary, status),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

class _ActionButton extends StatelessWidget {
  final IconData? icon;
  final String label;
  final LinearGradient gradient;
  final Color textColor;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _ActionButton({
    this.icon,
    required this.label,
    required this.gradient,
    required this.textColor,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Ink(
          decoration: BoxDecoration(
            gradient: onPressed != null ? gradient : null,
            color: onPressed == null ? AppColors.surfaceVariant : null,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: textColor),
                  )
                else if (icon != null)
                  Icon(icon, color: onPressed != null ? textColor : AppColors.textHint, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: AppTypography.buttonText.copyWith(
                    color: onPressed != null ? textColor : AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
