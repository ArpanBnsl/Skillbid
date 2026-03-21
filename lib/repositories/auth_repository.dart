import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../utils/exceptions.dart';
import '../utils/app_logger.dart';

class AuthRepository {
  final _authService = AuthService();
  final _databaseService = DatabaseService();

  /// Sign up user and create profile
  Future<String> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    try {
      // Sign up with auth
      final authResponse = await _authService.signUp(
        email: email,
        password: password,
      );

      final userId = authResponse.user!.id;

      // Create profile
      await _databaseService.insertData(
        table: 'profiles',
        data: {
          'id': userId,
          'full_name': fullName,
          'phone': phone,
          'imm_req_cnt': 5,
        },
      );

      return userId;
    } catch (e) {
      AppLogger.logError('Sign up failed', e);
      if (e is AppAuthException) rethrow;
      throw AppAuthException(
        message: 'Sign up failed: $e',
        originalException: e,
      );
    }
  }

  /// Sign in user
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Prevent stale-account bleed by clearing local session before a new login.
      await _authService.signOutSilently();

      final response = await _authService.signIn(
        email: email,
        password: password,
      );

      final user = response.user;
      final emailVerified = user?.emailConfirmedAt != null;
      if (!emailVerified) {
        await _authService.signOut();
        throw AppAuthException(
          message: 'Please verify your email before signing in.',
        );
      }
    } catch (e) {
      AppLogger.logError('Sign in failed', e);
      if (e is AppAuthException) rethrow;
      throw AppAuthException(
        message: 'Sign in failed: $e',
        originalException: e,
      );
    }
  }

  /// Sign out user
  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      AppLogger.logError('Sign out failed', e);
      if (e is AppAuthException) rethrow;
      throw AppAuthException(
        message: 'Sign out failed: $e',
        originalException: e,
      );
    }
  }

  /// Set user role
  Future<void> setUserRole({
    required String userId,
    required int roleId,
  }) async {
    try {
      final existing = await _databaseService.fetchData(
        table: 'user_roles',
        filters: {
          'user_id': userId,
          'role_id': roleId,
        },
      );

      if (existing.isEmpty) {
        await _databaseService.insertData(
          table: 'user_roles',
          data: {
            'user_id': userId,
            'role_id': roleId,
          },
        );
      }

      // Update last_role in profile
      await _databaseService.updateData(
        table: 'profiles',
        data: {
          'last_role': roleId == 1 ? 'client' : 'provider',
        },
        id: userId,
      );
    } catch (e) {
      AppLogger.logError('Set user role failed for userId: $userId', e);
      if (e is AppAuthException) rethrow;
      throw AppAuthException(
        message: 'Set user role failed: $e',
        originalException: e,
      );
    }
  }

  /// Create provider profile
  Future<void> createProviderProfile({
    required String userId,
    String? bio,
    int experienceYears = 0,
    double hourlyRate = 0,
  }) async {
    try {
      await _databaseService.insertData(
        table: 'provider_profiles',
        data: {
          'user_id': userId,
          'bio': bio,
          'experience_years': experienceYears,
          'hourly_rate': hourlyRate,
        },
      );
    } catch (e) {
      AppLogger.logError('Create provider profile failed for userId: $userId', e);
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Create provider profile failed: $e',
        originalException: e,
      );
    }
  }

  /// Check if user exists in profiles
  Future<bool> userExists(String userId) async {
    try {
      final result = await _databaseService.fetchData(
        table: 'profiles',
        filters: {'id': userId},
      );
      return result.isNotEmpty;
    } catch (e) {
      AppLogger.logError('User exists check failed for userId: $userId', e);
      return false;
    }
  }

  /// Get current user ID
  String? getCurrentUserId() => _authService.getCurrentUserId();

  /// Check if authenticated
  bool isAuthenticated() => _authService.isAuthenticated();

  /// Determine whether provider onboarding is complete for this user.
  Future<bool> isProviderOnboardingComplete(String userId) async {
    try {
      final profileRows = await _databaseService.fetchData(
        table: 'provider_profiles',
        filters: {
          'user_id': userId,
          'is_deleted': false,
        },
      );
      if (profileRows.isEmpty) return false;

      final skillRows = await _databaseService.fetchData(
        table: 'provider_skills',
        filters: {'provider_id': userId},
      );
      if (skillRows.isEmpty) return false;

      final portfolioRows = await _databaseService.fetchData(
        table: 'provider_portfolio',
        filters: {
          'provider_id': userId,
          'is_deleted': false,
        },
      );

      return portfolioRows.isNotEmpty;
    } catch (e) {
      AppLogger.logError('Provider onboarding check failed for userId: $userId', e);
      return false;
    }
  }
}
