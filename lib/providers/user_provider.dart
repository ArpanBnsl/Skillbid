import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user/profile_model.dart';
import '../models/user/provider_profile_model.dart';
import '../repositories/user_repository.dart';
import '../services/location_service.dart';
import 'auth_provider.dart';

final userRepositoryProvider = Provider((ref) => UserRepository());
final locationServiceProvider = Provider((ref) => LocationService());

/// Get current user profile
final currentUserProvider = FutureProvider.autoDispose<ProfileModel?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  
  final repo = ref.watch(userRepositoryProvider);
  return repo.getUserProfile(userId);
});

/// Get user profile by ID
final userProfileProvider = FutureProvider.autoDispose.family<ProfileModel?, String>((ref, userId) async {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getUserProfile(userId);
});

/// Get provider profile
final providerProfileProvider = FutureProvider.autoDispose.family<ProviderProfileModel?, String>((ref, providerId) async {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getProviderProfile(providerId);
});

/// Get user role
final userRoleProvider = FutureProvider<String?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  
  final repo = ref.watch(userRepositoryProvider);
  return repo.getUserRole(userId);
});

/// Update user profile
final updateUserProfileProvider = FutureProvider.family<void, ({String? fullName, String? phone, String? avatarUrl})>((ref, params) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) throw Exception('User not authenticated');
  
  final repo = ref.watch(userRepositoryProvider);
  await repo.updateUserProfile(
    userId: userId,
    fullName: params.fullName,
    phone: params.phone,
    avatarUrl: params.avatarUrl,
  );
  
  // Refresh current user profile
  ref.invalidate(currentUserProvider);
});

/// Update provider profile
final updateProviderProfileProvider = FutureProvider.family<void, ({String? bio, int? experienceYears, double? hourlyRate})>((ref, params) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) throw Exception('User not authenticated');
  
  final repo = ref.watch(userRepositoryProvider);
  await repo.updateProviderProfile(
    providerId: userId,
    bio: params.bio,
    experienceYears: params.experienceYears,
    hourlyRate: params.hourlyRate,
  );
  
  // Refresh provider profile
  ref.invalidate(providerProfileProvider(userId));
});

/// Get provider's skill IDs
final providerSkillIdsProvider = FutureProvider.family<List<int>, String>((ref, providerId) async {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getProviderSkills(providerId);
});

/// Fetch current device location and save it to the user's profile.
/// Call this on app launch / sign-in.
final refreshUserLocationProvider = FutureProvider<void>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return;

  final locationService = ref.read(locationServiceProvider);
  final position = await locationService.getCurrentPosition();
  if (position == null) return;

  final repo = ref.read(userRepositoryProvider);
  await repo.updateUserLocation(
    userId: userId,
    latitude: position.latitude,
    longitude: position.longitude,
  );
});
