import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/user_provider.dart' as userp;
import '../../utils/validators.dart';
import '../../widgets/common/image_viewer.dart';

class ProviderOnboardingScreen extends ConsumerStatefulWidget {
  const ProviderOnboardingScreen({super.key});

  @override
  ConsumerState<ProviderOnboardingScreen> createState() => _ProviderOnboardingScreenState();
}

class _ProviderOnboardingScreenState extends ConsumerState<ProviderOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bioCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();

  final Set<int> _selectedSkillIds = {};
  final List<_PortfolioDraft> _portfolioDrafts = [_PortfolioDraft()];
  bool _submitting = false;

  @override
  void dispose() {
    _bioCtrl.dispose();
    _expCtrl.dispose();
    _rateCtrl.dispose();
    for (final draft in _portfolioDrafts) {
      draft.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages(_PortfolioDraft draft) async {
    try {
      final files = await ImagePicker().pickMultiImage();
      if (!mounted || files.isEmpty) return;
      setState(() {
        draft.images
          ..clear()
          ..addAll([...draft.images, ...files].take(4));
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to pick images: $e')),
      );
    }
  }

  void _addPastWorkDraft() {
    setState(() => _portfolioDrafts.add(_PortfolioDraft()));
  }

  void _removePastWorkDraft(_PortfolioDraft draft) {
    if (_portfolioDrafts.length == 1) return;
    setState(() => _portfolioDrafts.remove(draft));
    draft.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSkillIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one skill.')),
      );
      return;
    }

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are not signed in.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final years = int.tryParse(_expCtrl.text.trim()) ?? 0;
      final rate = double.tryParse(_rateCtrl.text.trim()) ?? 0;

      final userRepo = ref.read(userp.userRepositoryProvider);
      final portfolioRepo = ref.read(portfolioRepositoryProvider);
      await userRepo.upsertProviderProfile(
        providerId: userId,
        bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        experienceYears: years,
        hourlyRate: rate,
      );

      await userRepo.setProviderSkills(
        providerId: userId,
        skillIds: _selectedSkillIds.toList(),
      );

      for (final draft in _portfolioDrafts) {
        final portfolio = await portfolioRepo.createPortfolioItem(
          providerId: userId,
          title: draft.titleCtrl.text.trim(),
          description: draft.descCtrl.text.trim().isEmpty ? null : draft.descCtrl.text.trim(),
          cost: double.tryParse(draft.costCtrl.text.trim()),
        );

        for (final image in draft.images.take(4)) {
          await portfolioRepo.addPortfolioImage(
            portfolioId: portfolio.id,
            imageFile: image,
          );
        }
      }

      ref.invalidate(userp.providerProfileProvider(userId));
      ref.invalidate(providerPortfolioProvider);
      ref.invalidate(providerOnboardingCompleteProvider);

      if (!mounted) return;
      context.go('/provider');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service Provider profile created.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to finish onboarding: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<bool> _handleBackNavigation() async {
    // Prevent back navigation while submitting
    if (_submitting) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for the operation to complete.')),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final skillsAsync = ref.watch(skillsProvider);

    return PopScope(
      canPop: !_submitting,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || !_submitting) return;
        await _handleBackNavigation();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Service Provider Setup'),
          leading: _submitting
              ? const SizedBox(
                  width: 40,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : null,
        ),
        body: skillsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Failed to load skills: $e')),
          data: (skills) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Build your service provider profile to start receiving project bids.'),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _bioCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Bio'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _expCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Experience Years'),
                    validator: (value) {
                      final parsed = int.tryParse(value ?? '');
                      if (parsed == null || parsed < 0) return 'Enter valid experience years';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _rateCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Hourly Rate (optional)'),
                  ),
                  const SizedBox(height: 16),
                  Text('Skills', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: skills
                        .map(
                          (skill) => FilterChip(
                            label: Text(skill.name),
                            selected: _selectedSkillIds.contains(skill.id),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedSkillIds.add(skill.id);
                                } else {
                                  _selectedSkillIds.remove(skill.id);
                                }
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Past Works', style: Theme.of(context).textTheme.titleMedium),
                      TextButton.icon(
                        onPressed: _submitting ? null : _addPastWorkDraft,
                        icon: const Icon(Icons.add),
                        label: const Text('Add More'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._portfolioDrafts.map(
                    (draft) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Past Work',
                                      style: TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  if (_portfolioDrafts.length > 1)
                                    IconButton(
                                      onPressed: _submitting ? null : () => _removePastWorkDraft(draft),
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                ],
                              ),
                              TextFormField(
                                controller: draft.titleCtrl,
                                decoration: const InputDecoration(labelText: 'Title'),
                                validator: Validators.validateTitle,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: draft.descCtrl,
                                maxLines: 4,
                                decoration: const InputDecoration(labelText: 'Description'),
                                validator: Validators.validateDescription,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: draft.costCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Project Cost (optional)'),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) return null;
                                  return Validators.validateAmount(value);
                                },
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: _submitting ? null : () => _pickImages(draft),
                                icon: const Icon(Icons.add_photo_alternate_outlined),
                                label: Text('Add Work Images (${draft.images.length}/4)'),
                              ),
                              if (draft.images.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 74,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: draft.images.length,
                                    separatorBuilder: (context, _) => const SizedBox(width: 8),
                                    itemBuilder: (context, index) {
                                      final image = draft.images[index];
                                      return Stack(
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
                                              onTap: () => setState(() => draft.images.removeAt(index)),
                                              child: Container(
                                                decoration: const BoxDecoration(
                                                  color: Colors.black54,
                                                  shape: BoxShape.circle,
                                                ),
                                                padding: const EdgeInsets.all(2),
                                                child: const Icon(Icons.close, color: Colors.white, size: 14),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Complete Setup'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PortfolioDraft {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final costCtrl = TextEditingController();
  final List<XFile> images = [];

  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    costCtrl.dispose();
  }
}
