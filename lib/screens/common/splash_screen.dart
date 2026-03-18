import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/supabase_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart' as userp;
import '../../theme/app_colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final isAuthenticated = supabase.auth.currentSession != null || ref.read(isAuthenticatedProvider);
    if (!isAuthenticated) {
      context.go('/sign-up');
      return;
    }

    try {
      final userId = supabase.auth.currentUser?.id ?? ref.read(currentUserIdProvider);
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
      backgroundColor: AppColors.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.handshake_outlined,
              size: 80,
              color: AppColors.white,
            ),
            const SizedBox(height: 20),
            const Text(
              'SkillBid',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your skills. Your price.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.primaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
