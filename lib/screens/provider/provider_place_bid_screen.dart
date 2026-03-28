import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/job/job_model.dart';
import '../../providers/bid_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
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

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: AppTypography.caption.copyWith(color: AppColors.textSecondary),
      hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textHint),
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.borderFocus, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.error),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Place Bid', style: AppTypography.heading4.copyWith(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Job summary card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.job.title, style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  'Budget: ${Formatters.formatCurrencyShort(widget.job.budget)}',
                  style: AppTypography.labelMedium.copyWith(color: AppColors.primaryColor),
                ),
                const SizedBox(height: 4),
                Text(
                  'Location: ${widget.job.location}',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _inputDecoration('Your Bid Amount'),
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                  validator: Validators.validateAmount,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _daysController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Estimated Days'),
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _messageController,
                  minLines: 4,
                  maxLines: 6,
                  decoration: _inputDecoration(
                    'Proposal Message',
                    hint: 'Explain your approach, experience, and timeline.',
                  ),
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: _submitting ? null : AppColors.primaryGradient,
                      color: _submitting ? AppColors.surfaceVariant : null,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: MaterialButton(
                      onPressed: _submitting ? null : _submit,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: _submitting
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryColor,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.send_outlined, color: AppColors.textDark),
                                const SizedBox(width: 8),
                                Text('Submit Bid', style: AppTypography.buttonText.copyWith(color: AppColors.textDark)),
                              ],
                            ),
                    ),
                  ),
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
