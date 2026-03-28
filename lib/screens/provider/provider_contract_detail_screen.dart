import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_constants.dart';
import '../../models/contract_model.dart';
import '../../providers/bid_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/contract_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/user_provider.dart' as userp;
import '../../services/tracking_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/image_viewer.dart';
import 'provider_tracking_screen.dart';
import 'provider_shell.dart';

class ProviderContractDetailScreen extends ConsumerStatefulWidget {
  final ContractModel contract;

  const ProviderContractDetailScreen({super.key, required this.contract});

  @override
  ConsumerState<ProviderContractDetailScreen> createState() => _ProviderContractDetailScreenState();
}

class _ProviderContractDetailScreenState extends ConsumerState<ProviderContractDetailScreen> {
  bool _processing = false;
  TrackingService? _trackingService;
  String? _trackingContractId;

  @override
  void initState() {
    super.initState();
    if (widget.contract.trackingEnabled &&
        widget.contract.status == AppConstants.contractStatusActive) {
      _trackingService = TrackingService();
      _trackingService!.startProviderTracking(contractId: widget.contract.id);
      _trackingContractId = widget.contract.id;
    }
  }

  @override
  void dispose() {
    _trackingService?.stopProviderTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liveContractAsync = ref.watch(contractProvider(widget.contract.id));
    final contract = liveContractAsync.valueOrNull ?? widget.contract;
    if (contract.trackingEnabled &&
        contract.status == AppConstants.contractStatusActive &&
        _trackingContractId != contract.id) {
      _trackingService ??= TrackingService();
      _trackingService!.startProviderTracking(contractId: contract.id);
      _trackingContractId = contract.id;
    }

    final jobAsync = ref.watch(jobProvider(contract.jobId));
    final jobImagesAsync = ref.watch(jobImagesProvider(contract.jobId));
    final clientAsync = ref.watch(userp.userProfileProvider(contract.clientId));
    final providerAsync = ref.watch(userp.userProfileProvider(contract.providerId));
    final bidAsync = ref.watch(bidProvider(contract.bidId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Contract Details', style: AppTypography.heading4.copyWith(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Job Information
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Job Information', style: AppTypography.labelLarge.copyWith(color: AppColors.primaryColor)),
                Divider(color: AppColors.divider),
                Text(
                  jobAsync.valueOrNull?.title ?? 'Project ${contract.jobId.substring(0, 8)}',
                  style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                ),
                if (jobAsync.valueOrNull?.description != null) ...[
                  const SizedBox(height: 6),
                  Text(jobAsync.valueOrNull!.description, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                ],
                const SizedBox(height: 6),
                if (jobAsync.valueOrNull != null) ...[
                  Text('Location: ${jobAsync.valueOrNull!.location}', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    'Budget: ${Formatters.formatCurrencyShort(jobAsync.valueOrNull!.budget)}',
                    style: AppTypography.labelMedium.copyWith(color: AppColors.primaryColor),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Bid Information
          if (bidAsync.valueOrNull != null)
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bid Information', style: AppTypography.labelLarge.copyWith(color: AppColors.secondaryColor)),
                  Divider(color: AppColors.divider),
                  Text(
                    'Agreed Amount: ${Formatters.formatCurrencyShort(bidAsync.valueOrNull!.amount)}',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                  ),
                  if (bidAsync.valueOrNull!.estimatedDays != null) ...[
                    const SizedBox(height: 4),
                    Text('Timeline: ${bidAsync.valueOrNull!.estimatedDays} days', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                  ],
                  if (bidAsync.valueOrNull!.message?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text('Bid Note: ${bidAsync.valueOrNull!.message!}', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 10),

          // Contract Status
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Contract Status', style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary)),
                Divider(color: AppColors.divider),
                _ContractStatusPill(status: contract.status),
                const SizedBox(height: 10),
                Text('Provider: ${providerAsync.valueOrNull?.fullName ?? 'Provider'}', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Text('Client: ${clientAsync.valueOrNull?.fullName ?? 'Client'}', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Text('Started: ${Formatters.formatDate(contract.createdAt)}', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                if (contract.workSubmittedAt != null) ...[
                  const SizedBox(height: 6),
                  Text('Work Submitted: ${Formatters.formatDateTime(contract.workSubmittedAt!)}', style: AppTypography.bodySmall.copyWith(color: AppColors.success)),
                ],
                if (contract.providerRating != null) ...[
                  const SizedBox(height: 10),
                  Text('Client Rating You Gave Provider: ${contract.providerRating}/5', style: AppTypography.bodySmall.copyWith(color: AppColors.warning)),
                ],
                if (contract.clientRating != null) ...[
                  const SizedBox(height: 6),
                  Text('Your Rating For Client: ${contract.clientRating}/5', style: AppTypography.bodySmall.copyWith(color: AppColors.warning)),
                ],
                if (contract.reviewText?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 6),
                  Text('Review: ${contract.reviewText}', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                ],
                if (contract.terminatedBy != null) ...[
                  const SizedBox(height: 6),
                  Text('Terminated By: ${contract.terminatedBy}', style: AppTypography.bodySmall.copyWith(color: AppColors.error)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (contract.trackingEnabled)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: AppColors.info),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Live tracking is active — your location is being shared with the client.',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.info, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: MaterialButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProviderTrackingScreen(contract: contract),
                            ),
                          );
                        },
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.navigation_outlined, color: AppColors.textDark),
                            const SizedBox(width: 8),
                            Text('Open Navigation', style: AppTypography.buttonText.copyWith(color: AppColors.textDark)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (contract.trackingEnabled) const SizedBox(height: 10),
          jobImagesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (images) {
              if (images.isEmpty) return const SizedBox.shrink();
              return _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Client Reference Images', style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary)),
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
              );
            },
          ),
          const SizedBox(height: 14),
          if (contract.status == AppConstants.contractStatusActive) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: MaterialButton(
                  onPressed: _processing ? null : () => _submitWork(contract.id),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: _processing
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textDark))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.upload_file_outlined, color: AppColors.textDark),
                            const SizedBox(width: 8),
                            Text('Submit Work For Approval', style: AppTypography.buttonText.copyWith(color: AppColors.textDark)),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _processing ? null : () => _confirmTerminate(contract.id),
                icon: Icon(Icons.cancel_outlined, color: AppColors.error),
                label: Text('Terminate Contract', style: AppTypography.buttonText.copyWith(color: AppColors.error)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (contract.status == AppConstants.contractStatusCompleted && contract.clientRating == null) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _processing ? null : () => _rateClient(contract.id),
                icon: Icon(Icons.star_outline, color: AppColors.warning),
                label: Text('Rate Client', style: AppTypography.buttonText.copyWith(color: AppColors.warning)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.warning.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.purpleGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: MaterialButton(
                onPressed: () => _openChat(contract, jobAsync.valueOrNull?.title),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_outlined, color: AppColors.textPrimary),
                    const SizedBox(width: 8),
                    Text('Open Contract Chat', style: AppTypography.buttonText.copyWith(color: AppColors.textPrimary)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
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
            child: Text('No', style: TextStyle(color: AppColors.textHint)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('Terminate', style: TextStyle(color: AppColors.textPrimary)),
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
            terminatedBy: AppConstants.contractTerminatedByProvider,
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

  Future<void> _rateClient(String contractId) async {
    var selectedRating = 5;
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceLight,
          title: Text('Rate Client', style: AppTypography.heading4.copyWith(color: AppColors.textPrimary)),
          content: Wrap(
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: AppColors.textHint)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primaryColor),
              child: Text('Submit', style: TextStyle(color: AppColors.textDark)),
            ),
          ],
        ),
      ),
    );

    if (submitted != true) return;

    setState(() => _processing = true);
    try {
      await ref.read(
        addProviderRatingProvider(
          (
            contractId: contractId,
            rating: selectedRating,
          ),
        ).future,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Client rated successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to rate client: $e')),
      );
    } finally {
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
            builder: (_) => ProviderShell(
              initialIndex: 2,
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
          builder: (_) => ProviderShell(
            initialIndex: 2,
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

class _ContractStatusPill extends StatelessWidget {
  final String status;

  const _ContractStatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (background, foreground, label) = switch (status) {
      'active' => (AppColors.successLight, AppColors.success, 'Active'),
      'completed' => (AppColors.infoLight, AppColors.info, 'Completed'),
      'terminated' => (AppColors.errorLight, AppColors.error, 'Terminated'),
      _ => (AppColors.surfaceVariant, AppColors.textHint, status),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
