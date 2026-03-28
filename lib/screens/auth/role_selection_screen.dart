import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  Future<void> _selectRole(BuildContext context, WidgetRef ref, String role) async {
    try {
      await ref.read(selectUserRoleProvider(role).future);

      if (!context.mounted) return;

      if (role == 'provider') {
        final completed = await ref.read(providerOnboardingCompleteProvider.future);
        if (!context.mounted) return;

        if (!completed) {
          context.go('/provider-onboarding');
          return;
        }
      }

      context.go(role == 'client' ? '/client' : '/provider');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to set role: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.surfaceGradient,
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with glow
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.glowTeal,
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.handshake_outlined,
                      size: 72,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'SkillBid',
                    style: AppTypography.heading1.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 42,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your skills. Your price.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 56),

                  // "I am a..." label
                  Text(
                    'I am a...',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textHint,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Client card
                  _RoleCard(
                    icon: Icons.person_outline,
                    title: 'Client',
                    subtitle: 'Post jobs and find skilled professionals',
                    gradient: AppColors.primaryGradient,
                    glowColor: AppColors.glowTeal,
                    onTap: () => _selectRole(context, ref, 'client'),
                  ),
                  const SizedBox(height: 16),

                  // Provider card
                  _RoleCard(
                    icon: Icons.construction_outlined,
                    title: 'Service Provider',
                    subtitle: 'Bid on projects and showcase your skills',
                    gradient: AppColors.purpleGradient,
                    glowColor: AppColors.glowPurple,
                    onTap: () => _selectRole(context, ref, 'provider'),
                  ),

                  const SizedBox(height: 36),
                  Text(
                    'You can switch roles anytime from settings',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textHint,
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

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final Color glowColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.glowColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: glowColor,
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.whiteOverlay,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 32, color: AppColors.textPrimary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.heading4.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: AppColors.textPrimary,
            ),
          ],
        ),
      ),
    );
  }
}
