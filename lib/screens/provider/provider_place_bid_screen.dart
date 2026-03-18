import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/job/job_model.dart';
import '../../providers/bid_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';

class ProviderPlaceBidScreen extends ConsumerStatefulWidget {
  final JobModel job;

  const ProviderPlaceBidScreen({super.key, required this.job});

  @override
  ConsumerState<ProviderPlaceBidScreen> createState() => _ProviderPlaceBidScreenState();
}

class _ProviderPlaceBidScreenState extends ConsumerState<ProviderPlaceBidScreen> {
  final _amountController = TextEditingController();
  final _daysController = TextEditingController();
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _daysController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Place Bid')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.job.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('Budget: ${Formatters.formatCurrencyShort(widget.job.budget)}'),
                  const SizedBox(height: 4),
                  Text('Location: ${widget.job.location}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Your Bid Amount'),
                  validator: Validators.validateAmount,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _daysController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Estimated Days'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _messageController,
                  minLines: 4,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Proposal Message',
                    hintText: 'Explain your approach, experience, and timeline.',
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_outlined),
                  label: const Text('Submit Bid'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null) return;

    setState(() => _submitting = true);
    try {
      await ref.read(
        createBidProvider(
          (
            jobId: widget.job.id,
            amount: amount,
            estimatedDays: int.tryParse(_daysController.text.trim()),
            message: _messageController.text.trim().isEmpty ? null : _messageController.text.trim(),
          ),
        ).future,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place bid: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}