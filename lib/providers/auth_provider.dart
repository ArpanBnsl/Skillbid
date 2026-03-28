import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'bid_provider.dart';
import 'chat_provider.dart';
import 'contract_provider.dart';
import 'job_provider.dart';
import 'notification_provider.dart';
import 'portfolio_provider.dart';
import 'user_provider.dart' as userp;
import '../repositories/auth_repository.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../config/supabase_config.dart';

final authServiceProvider = Provider((ref) => AuthService());

final authRepositoryProvider = Provider((ref) => AuthRepository());

/// Tracks auth session user IDs so account switches invalidate dependent providers.
final authSessionUserIdProvider = StreamProvider<String?>((ref) async* {
  yield getCurrentUserId();
  yield* supabase.auth.onAuthStateChange.map((event) => event.session?.user.id);
});

/// Track authentication state from session-aware stream
final authStateProvider = Provider<bool>((ref) {
  final sessionUserId = ref.watch(authSessionUserIdProvider).valueOrNull;
  return sessionUserId != null;
});

/// Check if user is authenticated
final isAuthenticatedProvider = Provider((ref) {
  final authState = ref.watch(authStateProvider);
  return authState || supabase.auth.currentSession != null;
});

/// Get current user ID from auth session
final currentUserIdProvider = Provider((ref) {
  final streamUserId = ref.watch(authSessionUserIdProvider).valueOrNull;
  return streamUserId ?? getCurrentUserId();
});

/// Get current user email from auth session
final currentUserEmailProvider = Provider<String?>((ref) {
  ref.watch(authSessionUserIdProvider);
  return supabase.auth.currentUser?.email;
});

/// Get current user from auth session
final currentUserProvider = Provider((ref) {
  ref.watch(authSessionUserIdProvider);
  return getCurrentUser();
});

/// Sign in with email and password
final signInProvider = FutureProvider.family<void, ({String email, String password})>((ref, params) async {
  final repo = ref.watch(authRepositoryProvider);
  await repo.signIn(email: params.email, password: params.password);

  // Refresh all auth-dependent providers on account switch.
  ref.invalidate(authSessionUserIdProvider);
  ref.invalidate(authStateProvider);
  ref.invalidate(currentUserIdProvider);
  ref.invalidate(currentUserProvider);
  ref.invalidate(currentUserEmailProvider);
  ref.invalidate(userp.currentUserProvider);
  ref.invalidate(userp.userRoleProvider);
  ref.invalidate(providerBidsProvider);
  ref.invalidate(clientJobsProvider);
  ref.invalidate(availableJobsProvider);
  ref.invalidate(clientContractsProvider);
  ref.invalidate(providerContractsProvider);
  ref.invalidate(userChatsProvider);
  ref.invalidate(userChatOverviewsProvider);
  ref.invalidate(providerPortfolioProvider);
  ref.invalidate(notificationInitProvider);
});

/// Sign out
final signOutProvider = FutureProvider<void>((ref) async {
  // Remove FCM token before signing out so the device stops receiving
  // notifications for this account.
  final userId = ref.read(currentUserIdProvider);
  if (userId != null) {
    await NotificationService().removeToken(userId: userId);
  }

  final repo = ref.watch(authRepositoryProvider);
  await repo.signOut();

  // Force immediate state refresh on account switch/sign-out.
  ref.invalidate(authSessionUserIdProvider);
  ref.invalidate(authStateProvider);
  ref.invalidate(currentUserIdProvider);
  ref.invalidate(currentUserProvider);
  ref.invalidate(currentUserEmailProvider);
  ref.invalidate(userp.currentUserProvider);
  ref.invalidate(userp.userRoleProvider);
  ref.invalidate(providerBidsProvider);
  ref.invalidate(clientJobsProvider);
  ref.invalidate(availableJobsProvider);
  ref.invalidate(clientContractsProvider);
  ref.invalidate(providerContractsProvider);
  ref.invalidate(userChatsProvider);
  ref.invalidate(userChatOverviewsProvider);
  ref.invalidate(providerPortfolioProvider);
  ref.invalidate(notificationInitProvider);
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
