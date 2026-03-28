import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/user_provider.dart' as userp;
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
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
        SnackBar(
          content: Text('Unable to pick images: $e'),
          backgroundColor: AppColors.error,
        ),
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
        const SnackBar(
          content: Text('Select at least one skill.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are not signed in.'),
          backgroundColor: AppColors.error,
        ),
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
        const SnackBar(
          content: Text('Service Provider profile created.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to finish onboarding: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<bool> _handleBackNavigation() async {
    if (_submitting) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for the operation to complete.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return false;
    }
    return true;
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.surfaceLight,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderFocus, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
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
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            'Service Provider Setup',
            style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
          ),
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
          leading: _submitting
              ? const SizedBox(
                  width: 40,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppColors.primaryColor),
                      ),
                    ),
                  ),
                )
              : null,
        ),
        body: skillsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.primaryColor),
            ),
          ),
          error: (e, _) => Center(
            child: Text(
              'Failed to load skills: $e',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
            ),
          ),
          data: (skills) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Build your service provider profile to start receiving project bids.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Bio
                  TextFormField(
                    controller: _bioCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: AppColors.textPrimary),
                    cursorColor: AppColors.primaryColor,
                    decoration: _inputDecoration('Bio'),
                  ),
                  const SizedBox(height: 14),

                  // Experience
                  TextFormField(
                    controller: _expCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary),
                    cursorColor: AppColors.primaryColor,
                    decoration: _inputDecoration('Experience Years'),
                    validator: (value) {
                      final parsed = int.tryParse(value ?? '');
                      if (parsed == null || parsed < 0) return 'Enter valid experience years';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Hourly rate
                  TextFormField(
                    controller: _rateCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary),
                    cursorColor: AppColors.primaryColor,
                    decoration: _inputDecoration('Hourly Rate (optional)'),
                  ),
                  const SizedBox(height: 22),

                  // Skills section
                  Text(
                    'Skills',
                    style: AppTypography.heading4.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: skills
                        .map(
                          (skill) => FilterChip(
                            label: Text(
                              skill.name,
                              style: TextStyle(
                                color: _selectedSkillIds.contains(skill.id)
                                    ? AppColors.textDark
                                    : AppColors.textSecondary,
                              ),
                            ),
                            selected: _selectedSkillIds.contains(skill.id),
                            selectedColor: AppColors.primaryColor,
                            backgroundColor: AppColors.surfaceLight,
                            checkmarkColor: AppColors.textDark,
                            side: BorderSide(
                              color: _selectedSkillIds.contains(skill.id)
                                  ? AppColors.primaryColor
                                  : AppColors.border,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
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
                  const SizedBox(height: 24),

                  // Past Works section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Past Works',
                        style: AppTypography.heading4.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _submitting ? null : _addPastWorkDraft,
                        icon: const Icon(Icons.add, color: AppColors.primaryColor),
                        label: Text(
                          'Add More',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._portfolioDrafts.map(
                    (draft) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.cardGradient,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Past Work',
                                      style: AppTypography.labelLarge.copyWith(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (_portfolioDrafts.length > 1)
                                    IconButton(
                                      onPressed: _submitting
                                          ? null
                                          : () => _removePastWorkDraft(draft),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: AppColors.error,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: draft.titleCtrl,
                                style: const TextStyle(color: AppColors.textPrimary),
                                cursorColor: AppColors.primaryColor,
                                decoration: _inputDecoration('Title'),
                                validator: Validators.validateTitle,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: draft.descCtrl,
                                maxLines: 4,
                                style: const TextStyle(color: AppColors.textPrimary),
                                cursorColor: AppColors.primaryColor,
                                decoration: _inputDecoration('Description'),
                                validator: Validators.validateDescription,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: draft.costCtrl,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: AppColors.textPrimary),
                                cursorColor: AppColors.primaryColor,
                                decoration: _inputDecoration('Project Cost (optional)'),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) return null;
                                  return Validators.validateAmount(value);
                                },
                              ),
                              const SizedBox(height: 14),
                              OutlinedButton.icon(
                                onPressed: _submitting ? null : () => _pickImages(draft),
                                icon: const Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: AppColors.primaryColor,
                                ),
                                label: Text(
                                  'Add Work Images (${draft.images.length}/4)',
                                  style: const TextStyle(color: AppColors.primaryColor),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.border),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              if (draft.images.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 74,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: draft.images.length,
                                    separatorBuilder: (context, _) =>
                                        const SizedBox(width: 8),
                                    itemBuilder: (context, index) {
                                      final image = draft.images[index];
                                      return Stack(
                                        children: [
                                          GestureDetector(
                                            onTap: () => ImageViewer.showFile(
                                                context, image.path),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
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
                                              onTap: () => setState(
                                                  () => draft.images.removeAt(index)),
                                              child: Container(
                                                decoration: const BoxDecoration(
                                                  color: AppColors.surfaceVariant,
                                                  shape: BoxShape.circle,
                                                ),
                                                padding: const EdgeInsets.all(2),
                                                child: const Icon(
                                                  Icons.close,
                                                  color: AppColors.textPrimary,
                                                  size: 14,
                                                ),
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
                  const SizedBox(height: 24),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: _submitting ? null : AppColors.primaryGradient,
                        color: _submitting ? AppColors.surfaceVariant : null,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _submitting
                            ? null
                            : [
                                const BoxShadow(
                                  color: AppColors.glowTeal,
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                      ),
                      child: Material(
                        color: AppColors.transparent,
                        child: InkWell(
                          onTap: _submitting ? null : _submit,
                          borderRadius: BorderRadius.circular(12),
                          child: Center(
                            child: _submitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                          AppColors.textPrimary),
                                    ),
                                  )
                                : Text(
                                    'Complete Setup',
                                    style: AppTypography.buttonText.copyWith(
                                      color: AppColors.textDark,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
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
