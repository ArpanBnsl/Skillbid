import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/bid_model.dart';
import '../../models/contract_model.dart';
import '../../models/portfolio/portfolio_image_model.dart';
import '../../models/portfolio/portfolio_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bid_provider.dart';
import '../../providers/contract_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/user_provider.dart' as userp;
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/common/image_viewer.dart';
import '../../widgets/common/loading_widget.dart';

class ProviderProfileScreen extends ConsumerStatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  ConsumerState<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends ConsumerState<ProviderProfileScreen> {

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userp.currentUserProvider);
    final userId = ref.watch(currentUserIdProvider);
    final providerProfileAsync = userId == null
        ? const AsyncValue.data(null)
        : ref.watch(userp.providerProfileProvider(userId));
    final bidsAsync = ref.watch(providerBidsProvider);
    final contractsAsync = ref.watch(providerContractsProvider);
    final pastBidsAsync = ref.watch(providerPastBidsProvider);
    final pastContractsAsync = ref.watch(providerPastContractsProvider);
    final portfolioAsync = ref.watch(providerPortfolioProvider);
    final ratingAsync = userId == null
      ? const AsyncValue.data(null)
      : ref.watch(providerAverageRatingProvider(userId));
    final email = ref.watch(currentUserEmailProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Profile', style: AppTypography.heading4.copyWith(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: profileAsync.when(
        loading: () => const LoadingWidget(message: 'Loading profile...'),
        error: (e, _) => Center(child: Text('Failed to load profile: $e', style: TextStyle(color: AppColors.error))),
        data: (profile) {
          if (profile == null) {
            return Center(child: Text('Profile not found', style: AppTypography.bodyMedium.copyWith(color: AppColors.textHint)));
          }

          final providerProfile = providerProfileAsync.valueOrNull;
          final providerBio = providerProfile?.bio;
          final experience = providerProfile?.experienceYears ?? 0;
          final hourlyRate = providerProfile?.hourlyRate ?? 0;
          final bidsCount = bidsAsync.valueOrNull?.length ?? 0;
          final contractsCount = contractsAsync.valueOrNull?.length ?? 0;
          final completedCount = contractsAsync.valueOrNull?.where((c) => c.status == 'completed').length ?? 0;
          final averageRating = ratingAsync.valueOrNull;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile header card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.cardGradient,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: AppColors.surfaceVariant,
                      child: Text(
                        _initials(profile.fullName),
                        style: AppTypography.heading4.copyWith(color: AppColors.primaryColor),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      profile.fullName,
                      style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      profile.phone ?? 'No phone added',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                    if (email != null) ...[
                      const SizedBox(height: 4),
                      Text(email, style: AppTypography.caption.copyWith(color: AppColors.textHint)),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showEditProfileDialog(
                          context,
                          profile.fullName,
                          profile.phone,
                          providerBio,
                          experience,
                          hourlyRate,
                        ),
                        icon: Icon(Icons.edit_outlined, color: AppColors.primaryColor, size: 18),
                        label: Text('Edit Profile', style: AppTypography.labelMedium.copyWith(color: AppColors.primaryColor)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.primaryColor.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Stats card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (averageRating != null) ...[
                      _statRow('Average Rating', '${averageRating.toStringAsFixed(1)}/5'),
                    ],
                    _statRow('Reliability Score', '${(providerProfile?.relScore ?? 5.0).toStringAsFixed(1)}/10'),
                    _statRow('Bids', '$bidsCount'),
                    _statRow('Contracts', '$contractsCount'),
                    _statRow('Completed', '$completedCount'),
                    _statRow('Experience', '$experience years'),
                    _statRow('Hourly Rate', Formatters.formatCurrencyShort(hourlyRate)),
                    _statRow('Member Since', Formatters.formatDate(profile.createdAt)),
                    if (providerBio != null && providerBio.trim().isNotEmpty) ...[
                      Divider(color: AppColors.divider),
                      const SizedBox(height: 4),
                      Text('Bio', style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text(providerBio, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Past Works', style: AppTypography.heading4.copyWith(color: AppColors.textPrimary)),
                  OutlinedButton.icon(
                    onPressed: () => _showPortfolioDialog(context),
                    icon: Icon(Icons.add, color: AppColors.primaryColor, size: 18),
                    label: Text('Add', style: AppTypography.labelMedium.copyWith(color: AppColors.primaryColor)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primaryColor.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              portfolioAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: LoadingWidget(message: 'Loading past works...'),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text('Failed to load past works: $e', style: TextStyle(color: AppColors.error)),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text('No past works added yet.', style: AppTypography.bodySmall.copyWith(color: AppColors.textHint)),
                    );
                  }

                  return Column(
                    children: items.map((portfolio) {
                      final imagesAsync = ref.watch(portfolioImagesProvider(portfolio.id));
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    portfolio.title,
                                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _showPortfolioDialog(context, portfolio: portfolio),
                                  icon: Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20),
                                ),
                                IconButton(
                                  onPressed: () => _deletePortfolioItem(context, portfolio.id),
                                  icon: Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                                ),
                              ],
                            ),
                            if (portfolio.description?.trim().isNotEmpty == true) ...[
                              const SizedBox(height: 6),
                              Text(portfolio.description!, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                            ],
                            if (portfolio.cost != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                Formatters.formatCurrencyShort(portfolio.cost!),
                                style: AppTypography.labelLarge.copyWith(color: AppColors.primaryColor),
                              ),
                            ],
                            const SizedBox(height: 10),
                            imagesAsync.when(
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                              data: (images) {
                                if (images.isEmpty) return const SizedBox.shrink();
                                return SizedBox(
                                  height: 78,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: images.length,
                                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                                    itemBuilder: (context, index) {
                                      final image = images[index];
                                      return Stack(
                                        children: [
                                          GestureDetector(
                                            onTap: () => ImageViewer.showNetwork(context, image.imageUrl),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: Image.network(
                                                image.imageUrl,
                                                width: 78,
                                                height: 78,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            right: 4,
                                            top: 4,
                                            child: GestureDetector(
                                              onTap: () => _deletePortfolioImage(
                                                context,
                                                portfolioId: portfolio.id,
                                                image: image,
                                              ),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: AppColors.errorLight,
                                                  shape: BoxShape.circle,
                                                ),
                                                padding: const EdgeInsets.all(2),
                                                child: Icon(Icons.close, color: AppColors.error, size: 14),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text('Past Projects', style: AppTypography.heading4.copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: 10),
              ..._buildPastProjectCards(
                context: context,
                pastContracts: pastContractsAsync.valueOrNull ?? const [],
                pastBids: pastBidsAsync.valueOrNull ?? const [],
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () async {
                  try {
                    await ref.read(signOutProvider.future);
                    if (context.mounted) {
                      context.go('/sign-in');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Sign out failed: $e')),
                      );
                    }
                  }
                },
                icon: Icon(Icons.logout, color: AppColors.error),
                label: Text('Sign Out', style: AppTypography.labelLarge.copyWith(color: AppColors.error)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildPastProjectCards({
    required BuildContext context,
    required List<ContractModel> pastContracts,
    required List<BidModel> pastBids,
  }) {
    if (pastContracts.isEmpty && pastBids.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Text('No past projects yet.', style: AppTypography.bodySmall.copyWith(color: AppColors.textHint)),
        ),
      ];
    }

    final widgets = <Widget>[];
    final contractedJobIds = pastContracts.map((c) => c.jobId).toSet();

    for (final contract in pastContracts) {
      widgets.add(
        Consumer(
          builder: (context, ref, _) {
            final jobAsync = ref.watch(jobProvider(contract.jobId));
            final title = jobAsync.valueOrNull?.title ?? 'Project ${contract.jobId.substring(0, 8)}';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: AppColors.transparent,
                  expansionTileTheme: ExpansionTileThemeData(
                    iconColor: AppColors.textSecondary,
                    collapsedIconColor: AppColors.textHint,
                  ),
                ),
                child: ExpansionTile(
                  leading: Icon(Icons.handshake_outlined, color: AppColors.primaryColor),
                  title: Text(title, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  subtitle: Text('Contract • ${_statusLabel(contract.status)}', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Started: ${Formatters.formatDate(contract.startDate ?? contract.createdAt)}', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Ended: ${Formatters.formatDate(contract.endDate ?? contract.updatedAt)}', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                    ),
                    if (contract.terminatedBy != null) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Terminated by: ${contract.terminatedBy}', style: AppTypography.bodySmall.copyWith(color: AppColors.error)),
                      ),
                    ],
                    if (contract.clientRating != null) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Your rating for client: ${contract.clientRating}/5', style: AppTypography.bodySmall.copyWith(color: AppColors.warning)),
                      ),
                    ],
                    if (contract.providerRating != null) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Client rating for you: ${contract.providerRating}/5', style: AppTypography.bodySmall.copyWith(color: AppColors.warning)),
                      ),
                    ],
                    if (contract.reviewText?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Client review: ${contract.reviewText}', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                      ),
                    ],
                    if (contract.status == 'completed' && contract.clientRating == null) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: () => _rateClientFromHistory(context, ref, contract.id),
                          icon: Icon(Icons.star_outline, color: AppColors.warning),
                          label: Text('Rate Client', style: AppTypography.labelMedium.copyWith(color: AppColors.warning)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.warning.withValues(alpha: 0.5)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    for (final bid in pastBids.where((b) => !contractedJobIds.contains(b.jobId))) {
      widgets.add(
        Consumer(
          builder: (context, ref, _) {
            final jobAsync = ref.watch(jobProvider(bid.jobId));
            final title = jobAsync.valueOrNull?.title ?? 'Job ${bid.jobId.substring(0, 8)}';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: ListTile(
                leading: Icon(Icons.assignment_outlined, color: AppColors.secondaryColor),
                title: Text(title, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                subtitle: Text('Bid • ${_statusLabel(bid.status)}', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                trailing: Text(Formatters.formatDate(bid.updatedAt), style: AppTypography.caption.copyWith(color: AppColors.textHint)),
              ),
            );
          },
        ),
      );
    }

    return widgets;
  }

  String _statusLabel(String status) {
    return switch (status) {
      'completed' => 'Completed',
      'terminated' => 'Terminated',
      'rejected' => 'Rejected',
      'cancelled' => 'Cancelled',
      _ => status,
    };
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
          Text(value, style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Future<void> _showEditProfileDialog(
    BuildContext context,
    String fullName,
    String? phone,
    String? bio,
    int experienceYears,
    double hourlyRate,
  ) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: fullName);
    final phoneCtrl = TextEditingController(text: phone ?? '');
    final bioCtrl = TextEditingController(text: bio ?? '');
    final expCtrl = TextEditingController(text: '$experienceYears');
    final rateCtrl = TextEditingController(text: hourlyRate == 0 ? '' : hourlyRate.toStringAsFixed(0));

    final shouldSave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surfaceLight,
            title: Text('Edit Provider Profile', style: AppTypography.heading4.copyWith(color: AppColors.textPrimary)),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: _dialogInputDecoration('Full Name'),
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                      validator: Validators.validateName,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: phoneCtrl,
                      decoration: _dialogInputDecoration('Phone'),
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                      keyboardType: TextInputType.phone,
                      validator: Validators.validatePhone,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: bioCtrl,
                      maxLines: 3,
                      decoration: _dialogInputDecoration('Bio'),
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: expCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _dialogInputDecoration('Experience Years'),
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: rateCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _dialogInputDecoration('Hourly Rate'),
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: TextStyle(color: AppColors.textHint)),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(context, true);
                  }
                },
                style: FilledButton.styleFrom(backgroundColor: AppColors.primaryColor),
                child: Text('Save', style: TextStyle(color: AppColors.textDark)),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldSave) return;

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      await ref.read(
        userp.updateUserProfileProvider(
          (
            fullName: nameCtrl.text.trim(),
            phone: phoneCtrl.text.trim(),
            avatarUrl: null,
          ),
        ).future,
      );

      await ref.read(
        userp.updateProviderProfileProvider(
          (
            bio: bioCtrl.text.trim().isEmpty ? null : bioCtrl.text.trim(),
            experienceYears: int.tryParse(expCtrl.text.trim()) ?? 0,
            hourlyRate: double.tryParse(rateCtrl.text.trim()) ?? 0,
          ),
        ).future,
      );

      ref.invalidate(userp.currentUserProvider);
      ref.invalidate(userp.providerProfileProvider(userId));

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    }
  }

  InputDecoration _dialogInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTypography.caption.copyWith(color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.borderFocus),
      ),
    );
  }

  Future<void> _showPortfolioDialog(BuildContext context, {PortfolioModel? portfolio}) async {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: portfolio?.title ?? '');
    final descCtrl = TextEditingController(text: portfolio?.description ?? '');
    final costCtrl = TextEditingController(
      text: portfolio?.cost == null ? '' : portfolio!.cost!.toStringAsFixed(0),
    );
    List<PortfolioImageModel> existingImages = [];
    if (portfolio != null) {
      try {
        existingImages = List<PortfolioImageModel>.from(
          await ref.read(portfolioImagesProvider(portfolio.id).future),
        );
      } catch (_) {
        existingImages = [];
      }
    }
    final List<XFile> newImages = [];
    final Set<String> removedExistingImageIds = <String>{};

    final shouldSave = await showDialog<bool>(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              backgroundColor: AppColors.surfaceLight,
              title: Text(
                portfolio == null ? 'Add Past Work' : 'Edit Past Work',
                style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleCtrl,
                        decoration: _dialogInputDecoration('Title'),
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                        validator: Validators.validateTitle,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: descCtrl,
                        maxLines: 4,
                        decoration: _dialogInputDecoration('Description'),
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                        validator: Validators.validateDescription,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: costCtrl,
                        keyboardType: TextInputType.number,
                        decoration: _dialogInputDecoration('Project Cost'),
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                        validator: Validators.validateAmount,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Images selected: ${existingImages.length + newImages.length}/4',
                          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (existingImages.isNotEmpty) ...[
                        SizedBox(
                          height: 74,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: List.generate(existingImages.length, (index) {
                                final image = existingImages[index];
                                return Padding(
                                  padding: EdgeInsets.only(right: index == existingImages.length - 1 ? 0 : 8),
                                  child: Stack(
                                    children: [
                                      GestureDetector(
                                        onTap: () => ImageViewer.showNetwork(context, image.imageUrl),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(
                                            image.imageUrl,
                                            width: 74,
                                            height: 74,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        right: 4,
                                        top: 4,
                                        child: GestureDetector(
                                          onTap: () => setDialogState(() {
                                            removedExistingImageIds.add(image.id);
                                            existingImages.removeAt(index);
                                          }),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: AppColors.errorLight,
                                              shape: BoxShape.circle,
                                            ),
                                            padding: const EdgeInsets.all(2),
                                            child: Icon(Icons.close, color: AppColors.error, size: 14),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ],
                      OutlinedButton.icon(
                        onPressed: () async {
                          final maxNewImages = 4 - existingImages.length - newImages.length;
                          if (maxNewImages <= 0) return;
                          final picked = await ImagePicker().pickMultiImage();
                          if (!context.mounted) return;
                          if (picked.isEmpty) return;
                          setDialogState(() {
                            newImages.addAll(picked.take(maxNewImages));
                          });
                        },
                        icon: Icon(Icons.add_photo_alternate_outlined, color: AppColors.primaryColor),
                        label: Text(
                          'Add Images (${existingImages.length + newImages.length}/4)',
                          style: TextStyle(color: AppColors.primaryColor),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.primaryColor.withValues(alpha: 0.5)),
                        ),
                      ),
                      if (newImages.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 74,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: List.generate(newImages.length, (index) {
                                final image = newImages[index];
                                return Padding(
                                  padding: EdgeInsets.only(right: index == newImages.length - 1 ? 0 : 8),
                                  child: Stack(
                                    children: [
                                      GestureDetector(
                                        onTap: () => ImageViewer.showFile(context, image.path),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.file(
                                            File(image.path),
                                            width: 74,
                                            height: 74,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        right: 4,
                                        top: 4,
                                        child: GestureDetector(
                                          onTap: () => setDialogState(() => newImages.removeAt(index)),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: AppColors.errorLight,
                                              shape: BoxShape.circle,
                                            ),
                                            padding: const EdgeInsets.all(2),
                                            child: Icon(Icons.close, color: AppColors.error, size: 14),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancel', style: TextStyle(color: AppColors.textHint)),
                ),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(context, true);
                    }
                  },
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primaryColor),
                  child: Text('Save', style: TextStyle(color: AppColors.textDark)),
                ),
              ],
            ),
          ),
        ) ??
        false;

    if (!shouldSave) return;

    try {
      final repo = ref.read(portfolioRepositoryProvider);
      final savedPortfolio = portfolio == null
          ? await repo.createPortfolioItem(
              providerId: ref.read(currentUserIdProvider)!,
              title: titleCtrl.text.trim(),
              description: descCtrl.text.trim(),
              cost: double.parse(costCtrl.text.trim()),
            )
          : portfolio;

      if (portfolio != null) {
        await repo.updatePortfolioItem(
          portfolioId: portfolio.id,
          title: titleCtrl.text.trim(),
          description: descCtrl.text.trim(),
          cost: double.parse(costCtrl.text.trim()),
        );

        final originalImages = await repo.getPortfolioImages(portfolio.id);
        for (final image in originalImages.where((img) => removedExistingImageIds.contains(img.id))) {
          await repo.deletePortfolioImage(
            imageId: image.id,
            imageUrl: image.imageUrl,
          );
        }
      }

      for (final image in newImages.take(4 - existingImages.length)) {
        await repo.addPortfolioImage(
          portfolioId: savedPortfolio.id,
          imageFile: image,
        );
      }

      ref.invalidate(providerPortfolioProvider);
      ref.invalidate(portfolioImagesProvider(savedPortfolio.id));

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(portfolio == null ? 'Past work added successfully' : 'Past work updated successfully')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save past work: $e')),
      );
    }
  }

  Future<void> _deletePortfolioImage(
    BuildContext context, {
    required String portfolioId,
    required PortfolioImageModel image,
  }) async {
    try {
      final repo = ref.read(portfolioRepositoryProvider);
      await repo.deletePortfolioImage(
        imageId: image.id,
        imageUrl: image.imageUrl,
      );

      ref.invalidate(portfolioImagesProvider(portfolioId));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image deleted successfully')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete image: $e')),
      );
    }
  }

  Future<void> _deletePortfolioItem(BuildContext context, String portfolioId) async {
    try {
      await ref.read(deletePortfolioProvider(portfolioId).future);
      ref.invalidate(providerPortfolioProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Past work deleted successfully')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete past work: $e')),
      );
    }
  }

  Future<void> _rateClientFromHistory(
    BuildContext context,
    WidgetRef ref,
    String contractId,
  ) async {
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
        ) ??
        false;

    if (!submitted) return;

    try {
      await ref.read(
        addProviderRatingProvider((contractId: contractId, rating: selectedRating)).future,
      );
      ref.invalidate(providerContractsProvider);
      ref.invalidate(providerPastContractsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Client rating submitted.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to rate client: $e')),
      );
    }
  }
}
