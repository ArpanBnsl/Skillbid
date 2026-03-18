import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../screens/auth/sign_in_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/auth/provider_onboarding_screen.dart';
import '../screens/auth/role_selection_screen.dart';
import '../screens/client/client_shell.dart';
import '../screens/provider/provider_shell.dart';
import '../screens/common/splash_screen.dart';

class AppRouter {
  static const String splashRoute = '/';
  static const String signInRoute = '/sign-in';
  static const String signUpRoute = '/sign-up';
  static const String roleSelectionRoute = '/role-selection';
  static const String providerOnboardingRoute = '/provider-onboarding';
  static const String clientShellRoute = '/client';
  static const String providerShellRoute = '/provider';

  static final GoRouter router = GoRouter(
    initialLocation: splashRoute,
    routes: [
      GoRoute(
        path: splashRoute,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: signInRoute,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: signUpRoute,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: roleSelectionRoute,
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: providerOnboardingRoute,
        builder: (context, state) => const ProviderOnboardingScreen(),
      ),
      GoRoute(
        path: clientShellRoute,
        builder: (context, state) => const ClientShell(),
      ),
      GoRoute(
        path: providerShellRoute,
        builder: (context, state) => const ProviderShell(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Text('No route defined for ${state.uri}'),
      ),
    ),
  );
}
