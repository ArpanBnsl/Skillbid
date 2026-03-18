import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/portfolio/portfolio_image_model.dart';
import '../../models/portfolio/portfolio_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bid_provider.dart';
import '../../providers/contract_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/user_provider.dart' as userp;
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
    final portfolioAsync = ref.watch(providerPortfolioProvider);
    final ratingAsync = userId == null
      ? const AsyncValue.data(null)
      : ref.watch(providerAverageRatingProvider(userId));
    final email = ref.watch(currentUserEmailProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileAsync.when(
        loading: () => const LoadingWidget(message: 'Loading profile...'),
        error: (e, _) => Center(child: Text('Failed to load profile: $e')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profile not found'));
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
              const SizedBox(height: 6),
              Center(child: Text(profile.phone ?? 'No phone added')),
              if (email != null) ...[
                const SizedBox(height: 4),
                Center(
                  child: Text(email, style: TextStyle(color: Colors.grey.shade600)),
                ),
              ],
              const SizedBox(height: 12),
              Center(
                child: FilledButton.icon(
                  onPressed: () => _showEditProfileDialog(
                    context,
                    profile.fullName,
                    profile.phone,
                    providerBio,
                    experience,
                    hourlyRate,
                  ),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Profile'),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (averageRating != null) ...[
                        _statRow('Average Rating', '${averageRating.toStringAsFixed(1)}/5'),
                      ],
                      _statRow('Bids', '$bidsCount'),
                      _statRow('Contracts', '$contractsCount'),
                      _statRow('Completed', '$completedCount'),
                      _statRow('Experience', '$experience years'),
                      _statRow('Hourly Rate', Formatters.formatCurrencyShort(hourlyRate)),
                      _statRow('Member Since', Formatters.formatDate(profile.createdAt)),
                      if (providerBio != null && providerBio.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        const Text('Bio', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(providerBio),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Past Works', style: Theme.of(context).textTheme.titleMedium),
                  FilledButton.icon(
                    onPressed: () => _showPortfolioDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
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
                  child: Text('Failed to load past works: $e'),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No past works added yet.'),
                      ),
                    );
                  }

                  return Column(
                    children: items.map((portfolio) {
                      final imagesAsync = ref.watch(portfolioImagesProvider(portfolio.id));
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      portfolio.title,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _showPortfolioDialog(context, portfolio: portfolio),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    onPressed: () => _deletePortfolioItem(context, portfolio.id),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ],
                              ),
                              if (portfolio.description?.trim().isNotEmpty == true) ...[
                                const SizedBox(height: 6),
                                Text(portfolio.description!),
                              ],
                              if (portfolio.cost != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  Formatters.formatCurrencyShort(portfolio.cost!),
                                  style: const TextStyle(fontWeight: FontWeight.w700),
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
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
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
            title: const Text('Edit Provider Profile'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
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
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: bioCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Bio'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: expCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Experience Years'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: rateCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Hourly Rate'),
                    ),
                  ],
                ),
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
              title: Text(portfolio == null ? 'Add Past Work' : 'Edit Past Work'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(labelText: 'Title'),
                        validator: Validators.validateTitle,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: descCtrl,
                        maxLines: 4,
                        decoration: const InputDecoration(labelText: 'Description'),
                        validator: Validators.validateDescription,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: costCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Project Cost'),
                        validator: Validators.validateAmount,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Images selected: ${existingImages.length + newImages.length}/4'),
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
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: Text('Add Images (${existingImages.length + newImages.length}/4)'),
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
}
