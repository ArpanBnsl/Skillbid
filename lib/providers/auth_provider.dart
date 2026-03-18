import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';
import '../services/auth_service.dart';
import '../config/supabase_config.dart';

final authServiceProvider = Provider((ref) => AuthService());

final authRepositoryProvider = Provider((ref) => AuthRepository());

/// Track authentication state - properly watches Supabase auth state
final authStateProvider = StreamProvider<bool>((ref) {
  return supabase.auth.onAuthStateChange.map((event) {
    return event.session != null;
  });
});

/// Check if user is authenticated
final isAuthenticatedProvider = Provider((ref) {
  final authState = ref.watch(authStateProvider);
  final hasSession = supabase.auth.currentSession != null;
  return authState.maybeWhen(
    data: (isAuthenticated) => isAuthenticated || hasSession,
    orElse: () => hasSession,
  );
});

/// Get current user ID from auth session
final currentUserIdProvider = Provider((ref) {
  final authState = ref.watch(authStateProvider);
  final sessionUserId = getCurrentUserId();
  return authState.maybeWhen(
    data: (_) => getCurrentUserId() ?? sessionUserId,
    orElse: () => sessionUserId,
  );
});

/// Get current user email from auth session
final currentUserEmailProvider = Provider<String?>((ref) {
  ref.watch(authStateProvider);
  return supabase.auth.currentUser?.email;
});

/// Get current user from auth session
final currentUserProvider = Provider((ref) {
  final authState = ref.watch(authStateProvider);
  final sessionUser = getCurrentUser();
  return authState.maybeWhen(
    data: (_) => getCurrentUser() ?? sessionUser,
    orElse: () => sessionUser,
  );
});

/// Sign in with email and password
final signInProvider = FutureProvider.family<void, ({String email, String password})>((ref, params) async {
  final repo = ref.watch(authRepositoryProvider);
  await repo.signIn(email: params.email, password: params.password);
});

/// Sign out
final signOutProvider = FutureProvider<void>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  await repo.signOut();
});

/// Sign up
final signUpProvider = FutureProvider.family<String, ({String email, String password, String fullName, String phone})>(
  (ref, params) async {
    final repo = ref.watch(authRepositoryProvider);
    final userId = await repo.signUp(
      email: params.email,
      password: params.password,
      fullName: params.fullName,
      phone: params.phone,
    );
    return userId;
  },
);

/// Persist selected role for current user and bootstrap provider profile when needed
final selectUserRoleProvider = FutureProvider.family<void, String>((ref, role) async {
  final repo = ref.watch(authRepositoryProvider);
  final userId = ref.read(currentUserIdProvider) ?? getCurrentUserId();
  if (userId == null) throw Exception('User not authenticated');

  final normalizedRole = role.toLowerCase();
  final roleId = normalizedRole == 'client' ? 1 : 2;

  await repo.setUserRole(userId: userId, roleId: roleId);
});

final providerOnboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  final userId = ref.read(currentUserIdProvider) ?? getCurrentUserId();
  if (userId == null) return false;
  return repo.isProviderOnboardingComplete(userId);
});
