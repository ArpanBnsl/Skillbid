import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/supabase_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart' as userp;
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _navigate();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final isAuthenticated =
        supabase.auth.currentSession != null || ref.read(isAuthenticatedProvider);
    if (!isAuthenticated) {
      context.go('/sign-up');
      return;
    }

    try {
      final userId =
          supabase.auth.currentUser?.id ?? ref.read(currentUserIdProvider);
      if (userId == null) {
        context.go('/sign-in');
        return;
      }

      final userRepo = ref.read(userp.userRepositoryProvider);
      final authRepo = ref.read(authRepositoryProvider);
      final role = (await userRepo.getUserRole(userId))?.trim().toLowerCase();
      if (!mounted) return;

      if (role == 'client') {
        context.go('/client');
      } else if (role == 'provider') {
        final completed = await authRepo.isProviderOnboardingComplete(userId);
        if (!mounted) return;
        context.go(completed ? '/provider' : '/provider-onboarding');
      } else {
        context.go('/role-selection');
      }
    } catch (_) {
      if (mounted) {
        context.go('/role-selection');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.surfaceGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor
                              .withValues(alpha: 0.3 * _glowAnimation.value),
                          blurRadius: 40 * _glowAnimation.value,
                          spreadRadius: 10 * _glowAnimation.value,
                        ),
                        BoxShadow(
                          color: AppColors.secondaryColor
                              .withValues(alpha: 0.15 * _glowAnimation.value),
                          blurRadius: 60 * _glowAnimation.value,
                          spreadRadius: 20 * _glowAnimation.value,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.handshake_outlined,
                      size: 100,
                      color: AppColors.primaryColor,
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),
              Text(
                'SkillBid',
                style: AppTypography.heading1.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 52,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your skills. Your price.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 48),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(AppColors.primaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
