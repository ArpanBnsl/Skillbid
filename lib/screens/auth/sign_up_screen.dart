import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../utils/validators.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(signUpProvider(
        (
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
        ),
      ).future);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign up successful. Please sign in.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/sign-in');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign up failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: _isLoading
              ? null
              : () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    context.go('/sign-in');
                  }
                },
        ),
        title: Text(
          'Create Account',
          style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Join SkillBid',
                  style: AppTypography.heading3.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your account to get started',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                CustomTextField(
                  labelText: 'Full Name',
                  controller: _nameController,
                  validator: Validators.validateName,
                  prefixIcon: const Icon(Icons.person_outlined,
                      color: AppColors.textHint),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  labelText: 'Email',
                  hintText: 'example@email.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                  prefixIcon: const Icon(Icons.email_outlined,
                      color: AppColors.textHint),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  labelText: 'Phone',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: Validators.validatePhone,
                  prefixIcon: const Icon(Icons.phone_outlined,
                      color: AppColors.textHint),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  labelText: 'Password',
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  validator: Validators.validatePassword,
                  prefixIcon: const Icon(Icons.lock_outlined,
                      color: AppColors.textHint),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textHint,
                    ),
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  labelText: 'Confirm Password',
                  controller: _confirmPasswordController,
                  obscureText: !_showConfirmPassword,
                  validator: _validateConfirmPassword,
                  prefixIcon: const Icon(Icons.lock_outlined,
                      color: AppColors.textHint),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textHint,
                    ),
                    onPressed: () => setState(
                        () => _showConfirmPassword = !_showConfirmPassword),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    label: 'Create Account',
                    onPressed: _handleSignUp,
                    isLoading: _isLoading,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: _isLoading ? null : () => context.go('/sign-in'),
                      child: Text(
                        'Sign In',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
