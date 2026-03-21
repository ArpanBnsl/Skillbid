import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contract_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/user_provider.dart' as userp;
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
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: profileAsync.when(
        loading: () => const LoadingWidget(message: 'Loading profile...'),
        error: (e, _) => Center(child: Text('Failed to load profile: $e')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profile not found'));
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
              Center(
                child: CircleAvatar(
                  radius: 34,
                  child: Text(_initials(profile.fullName)),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  profile.fullName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(profile.phone ?? 'No phone added'),
              ),
              if (email != null) ...[
                const SizedBox(height: 4),
                Center(
                  child: Text(email, style: TextStyle(color: Colors.grey.shade600)),
                ),
              ],
              const SizedBox(height: 12),
              Center(
                child: FilledButton.icon(
                  onPressed: () => _showEditProfileDialog(context, ref, profile.fullName, profile.phone),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Profile'),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _statRow('Posted Projects', '$postedCount'),
                      _statRow('Contracts', '$contractCount'),
                      _statRow('Completed', '$completedCount'),
                      if (profile.averageRating != null)
                        _statRow('Your Rating', '${profile.averageRating!.toStringAsFixed(1)}/5'),
                      _statRow('Immediate Requests Left', '${profile.immReqCnt}'),
                      _statRow('Member Since', Formatters.formatDate(profile.createdAt)),
                      const SizedBox(height: 4),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Immediate requests are urgent jobs broadcast quickly to nearby providers.',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Past Projects', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (pastContracts.isEmpty && pastJobs.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('No past projects yet.'),
                  ),
                )
              else ...[
                ...pastContracts.map((contract) {
                  final relatedJob = jobsById[contract.jobId];
                  final title = relatedJob?.title ?? 'Project ${contract.jobId.substring(0, 8)}';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ExpansionTile(
                      leading: const Icon(Icons.handshake_outlined),
                      title: Text(title),
                      subtitle: Text('Contract • ${_statusLabel(contract.status)}'),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Started: ${Formatters.formatDate(contract.startDate ?? contract.createdAt)}'),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Ended: ${Formatters.formatDate(contract.endDate ?? contract.updatedAt)}'),
                        ),
                        if (contract.terminatedBy != null) ...[
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Terminated by: ${contract.terminatedBy}'),
                          ),
                        ],
                        if (contract.providerRating != null) ...[
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Provider rating: ${contract.providerRating}/5'),
                          ),
                        ],
                        if (contract.clientRating != null) ...[
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Your rating from provider: ${contract.clientRating}/5'),
                          ),
                        ],
                        if (contract.reviewText?.trim().isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Review: ${contract.reviewText}'),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
                ...dedupPastJobs.map((job) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: const Icon(Icons.assignment_outlined),
                      title: Text(job.title),
                      subtitle: Text('Job • ${_statusLabel(job.status)}'),
                      trailing: Text(Formatters.formatDate(job.updatedAt)),
                    ),
                  );
                }),
              ],
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
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
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
            title: const Text('Edit Profile'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                    validator: Validators.validateName,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                    validator: Validators.validatePhone,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
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
