import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../models/skill_model.dart';
import '../../providers/job_provider.dart';
import '../../providers/user_provider.dart' as userp;
import '../../utils/validators.dart';
import '../../widgets/common/image_viewer.dart';
import '../../widgets/common/map_picker_screen.dart';

class CreateJobScreen extends ConsumerStatefulWidget {
  final List<SkillModel> skills;

  const CreateJobScreen({super.key, required this.skills});

  @override
  ConsumerState<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends ConsumerState<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _daysCtrl = TextEditingController();
  final List<XFile> _referenceImages = [];

  int? _selectedSkillId;
  bool _submitting = false;
  bool _isImmediate = false;
  int _immediateHours = 2;
  LatLng? _selectedLatLng;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _budgetCtrl.dispose();
    _locationCtrl.dispose();
    _daysCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final files = await ImagePicker().pickMultiImage();
      if (!mounted || files.isEmpty) return;

      final nextImages = [..._referenceImages, ...files].take(4).toList();
      setState(() {
        _referenceImages
          ..clear()
          ..addAll(nextImages);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to pick images: $e')),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSkillId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a skill/category')),
      );
      return;
    }

    final budget = double.tryParse(_budgetCtrl.text.trim());
    if (budget == null || budget <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid budget')),
      );
      return;
    }

    if (_selectedLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location on the map')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final DateTime? expiresAt = _isImmediate
          ? DateTime.now().add(Duration(hours: _immediateHours))
          : null;

      await ref.read(
        createJobProvider(
          (
            title: _titleCtrl.text.trim(),
            description: _descriptionCtrl.text.trim(),
            budget: budget,
            location: _locationCtrl.text.trim(),
            skillId: _selectedSkillId!,
            desiredCompletionDays: int.tryParse(_daysCtrl.text.trim()),
            images: _referenceImages,
            isImmediate: _isImmediate,
            expiresAt: expiresAt,
            jobLat: _selectedLatLng!.latitude,
            jobLng: _selectedLatLng!.longitude,
          ),
        ).future,
      );

      ref.invalidate(clientJobsProvider);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post job: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userp.currentUserProvider).valueOrNull;
    final immediateLeft = profile?.immReqCnt ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Post New Job')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8F8F7), Color(0xFFDDF3F2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.auto_awesome_outlined, color: Color(0xFF0B6E6E)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Describe your work clearly and providers will send accurate bids. Posting flow stays the same, now with a friendlier UI.',
                        style: TextStyle(fontSize: 13, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Project Details',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                initialValue: _selectedSkillId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Skill/Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: widget.skills
                    .map((s) => DropdownMenuItem<int>(
                          value: s.id,
                          child: Text(s.name),
                        ))
                    .toList(),
                onChanged: _submitting ? null : (value) => setState(() => _selectedSkillId = value),
                validator: (value) => value == null ? 'Skill/category is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Job Title',
                  prefixIcon: Icon(Icons.title_outlined),
                ),
                validator: Validators.validateTitle,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionCtrl,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Description & Specifications',
                  prefixIcon: Icon(Icons.notes_outlined),
                  hintText:
                      'Include dimensions, material preference, finish quality, site constraints, timeline expectations, and any mandatory requirements.',
                ),
                validator: Validators.validateDescription,
              ),
              const SizedBox(height: 18),
              Text(
                'Budget & Location',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _budgetCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Budget',
                  prefixIcon: Icon(Icons.currency_rupee_outlined),
                ),
                validator: Validators.validateAmount,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Location (area / landmark)',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Location is required' : null,
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _submitting
                    ? null
                    : () async {
                        final picked = await Navigator.push<LatLng>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MapPickerScreen(
                              initialCenter: _selectedLatLng,
                            ),
                          ),
                        );
                        if (picked != null) {
                          setState(() => _selectedLatLng = picked);
                        }
                      },
                icon: const Icon(Icons.map_outlined),
                label: Text(
                  _selectedLatLng != null
                      ? 'Location: ${_selectedLatLng!.latitude.toStringAsFixed(4)}, ${_selectedLatLng!.longitude.toStringAsFixed(4)}'
                      : 'Pick Location on Map',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _daysCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Desired Completion Days (optional)',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Immediate Service',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Request Immediate Service'),
                subtitle: Text(
                  'Nearby providers will be notified instantly and your post will auto-expire. Remaining: $immediateLeft',
                ),
                value: _isImmediate,
                onChanged: (_submitting || immediateLeft <= 0)
                    ? null
                    : (v) => setState(() => _isImmediate = v),
              ),
              if (immediateLeft <= 0)
                const Text(
                  'Immediate request balance exhausted. Post a normal request or wait for reset.',
                  style: TextStyle(fontSize: 12, color: Colors.redAccent),
                ),
              if (_isImmediate) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 20),
                    const SizedBox(width: 8),
                    const Text('Expires in'),
                    const SizedBox(width: 12),
                    DropdownButton<int>(
                      value: _immediateHours,
                      items: [1, 2, 3, 4, 6]
                          .map((h) => DropdownMenuItem(
                                value: h,
                                child: Text('$h hour${h > 1 ? 's' : ''}'),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _immediateHours = v);
                      },
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _submitting ? null : _pickImages,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text('Add Reference Images (${_referenceImages.length}/4)'),
              ),
              if (_referenceImages.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 74,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _referenceImages.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final image = _referenceImages[index];
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
                              onTap: () => setState(() => _referenceImages.removeAt(index)),
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
                      : const Text('Post Job'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
