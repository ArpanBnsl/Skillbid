import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contract_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/user_provider.dart' as userp;
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/common/loading_widget.dart';

class ClientProfileScreen extends ConsumerWidget {
  const ClientProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userp.currentUserProvider);
    final jobsAsync = ref.watch(clientJobsProvider);
    final contractsAsync = ref.watch(clientContractsProvider);
    final email = ref.watch(currentUserEmailProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Profile', style: AppTypography.heading4.copyWith(color: AppColors.textPrimary)),
      ),
      body: profileAsync.when(
        loading: () => const LoadingWidget(message: 'Loading profile...'),
        error: (e, _) => Center(child: Text('Failed to load profile: $e', style: const TextStyle(color: AppColors.error))),
        data: (profile) {
          if (profile == null) {
            return Center(child: Text('Profile not found', style: TextStyle(color: AppColors.textSecondary)));
          }

          final postedCount = jobsAsync.valueOrNull?.length ?? 0;
          final contractCount = contractsAsync.valueOrNull?.length ?? 0;
          final completedCount = contractsAsync.valueOrNull?.where((c) => c.status == 'completed').length ?? 0;
          final pastJobs = (jobsAsync.valueOrNull ?? const [])
              .where((j) => j.status == 'completed' || j.status == 'cancelled' || j.status == 'deleted')
              .toList();
          final pastContracts = (contractsAsync.valueOrNull ?? const [])
              .where((c) => c.status == 'completed' || c.status == 'terminated')
              .toList();
          final pastContractJobIds = pastContracts.map((c) => c.jobId).toSet();
          final jobsById = {
            for (final job in (jobsAsync.valueOrNull ?? const [])) job.id: job,
          };
          final dedupPastJobs = pastJobs.where((j) => !pastContractJobIds.contains(j.id)).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile header card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                      ),
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.surfaceLight,
                        child: Text(
                          _initials(profile.fullName),
                          style: AppTypography.heading3.copyWith(color: AppColors.primaryColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      profile.fullName,
                      style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.phone ?? 'No phone added',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                    if (email != null) ...[
                      const SizedBox(height: 4),
                      Text(email, style: AppTypography.caption.copyWith(color: AppColors.textHint)),
                    ],
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: AppColors.textDark,
                      ),
                      onPressed: () => _showEditProfileDialog(context, ref, profile.fullName, profile.phone),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: Text('Edit Profile', style: AppTypography.buttonText.copyWith(color: AppColors.textDark)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Stats grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.6,
                children: [
                  _StatCard(label: 'Posted Projects', value: '$postedCount', icon: Icons.work_outline),
                  _StatCard(label: 'Contracts', value: '$contractCount', icon: Icons.handshake_outlined),
                  _StatCard(label: 'Completed', value: '$completedCount', icon: Icons.check_circle_outline),
                  _StatCard(
                    label: 'Your Rating',
                    value: profile.averageRating != null
                        ? '${profile.averageRating!.toStringAsFixed(1)}/5'
                        : 'N/A',
                    icon: Icons.star_outline,
                  ),
                  _StatCard(label: 'Imm. Requests', value: '${profile.immReqCnt}', icon: Icons.bolt_outlined),
                  _StatCard(
                    label: 'Member Since',
                    value: Formatters.formatDate(profile.createdAt),
                    icon: Icons.calendar_today_outlined,
                    smallValue: true,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Immediate requests are urgent jobs broadcast quickly to nearby providers.',
                  style: AppTypography.captionSmall.copyWith(color: AppColors.textHint),
                ),
              ),
              const SizedBox(height: 20),
              Text('Past Projects', style: AppTypography.heading4.copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: 10),
              if (pastContracts.isEmpty && pastJobs.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'No past projects yet.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                )
              else ...[
                ...pastContracts.map((contract) {
                  final relatedJob = jobsById[contract.jobId];
                  final title = relatedJob?.title ?? 'Project ${contract.jobId.substring(0, 8)}';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: AppColors.transparent),
                      child: ExpansionTile(
                        leading: const Icon(Icons.handshake_outlined, color: AppColors.primaryColor),
                        title: Text(title, style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary)),
                        subtitle: Text(
                          'Contract • ${_statusLabel(contract.status)}',
                          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                        ),
                        iconColor: AppColors.textHint,
                        collapsedIconColor: AppColors.textHint,
                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Started: ${Formatters.formatDate(contract.startDate ?? contract.createdAt)}',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Ended: ${Formatters.formatDate(contract.endDate ?? contract.updatedAt)}',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                          if (contract.terminatedBy != null) ...[
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Terminated by: ${contract.terminatedBy}',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                              ),
                            ),
                          ],
                          if (contract.providerRating != null) ...[
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Provider rating: ${contract.providerRating}/5',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.warning),
                              ),
                            ),
                          ],
                          if (contract.clientRating != null) ...[
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Your rating from provider: ${contract.clientRating}/5',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.warning),
                              ),
                            ),
                          ],
                          if (contract.reviewText?.trim().isNotEmpty == true) ...[
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Review: ${contract.reviewText}',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
                ...dedupPastJobs.map((job) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.assignment_outlined, color: AppColors.primaryColor),
                      title: Text(job.title, style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary)),
                      subtitle: Text(
                        'Job • ${_statusLabel(job.status)}',
                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                      ),
                      trailing: Text(
                        Formatters.formatDate(job.updatedAt),
                        style: AppTypography.captionSmall.copyWith(color: AppColors.textHint),
                      ),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 20),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
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
                icon: const Icon(Icons.logout),
                label: Text('Sign Out', style: AppTypography.buttonText.copyWith(color: AppColors.error)),
              ),
            ],
          );
        },
      ),
    );
  }

  String _statusLabel(String status) {
    return switch (status) {
      'completed' => 'Completed',
      'cancelled' => 'Cancelled',
      'terminated' => 'Terminated',
      'deleted' => 'Deleted',
      _ => status,
    };
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Future<void> _showEditProfileDialog(
    BuildContext context,
    WidgetRef ref,
    String currentName,
    String? currentPhone,
  ) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: currentName);
    final phoneCtrl = TextEditingController(text: currentPhone ?? '');

    final shouldSave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surfaceLight,
            title: Text('Edit Profile', style: AppTypography.heading4.copyWith(color: AppColors.textPrimary)),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                    style: const TextStyle(color: AppColors.textPrimary),
                    validator: Validators.validateName,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    style: const TextStyle(color: AppColors.textPrimary),
                    keyboardType: TextInputType.phone,
                    validator: Validators.validatePhone,
                  ),
                ],
              ),
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
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(context, true);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldSave) return;

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

      ref.invalidate(userp.currentUserProvider);
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
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool smallValue;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.smallValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primaryColor),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: smallValue
                  ? AppTypography.labelLarge.copyWith(color: AppColors.textPrimary)
                  : AppTypography.statValue.copyWith(color: AppColors.textPrimary, fontSize: 22),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.captionSmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
