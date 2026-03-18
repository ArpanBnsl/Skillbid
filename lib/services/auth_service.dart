import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../utils/exceptions.dart';
import '../utils/app_logger.dart';

class AuthService {
  /// Sign up a new user with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    try {
      return await supabase.auth.signUp(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      AppLogger.logError('Sign up auth error', e);
      throw AppAuthException(
        message: 'Sign up failed: ${e.message}',
        originalException: e,
      );
    } catch (e) {
      AppLogger.logError('Sign up failed', e);
      throw AppAuthException(
        message: 'Sign up failed: $e',
        originalException: e,
      );
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      AppLogger.logError('Sign in auth error', e);
      throw AppAuthException(
        message: 'Sign in failed: ${e.message}',
        originalException: e,
      );
    } catch (e) {
      AppLogger.logError('Sign in failed', e);
      throw AppAuthException(
        message: 'Sign in failed: $e',
        originalException: e,
      );
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      AppLogger.logError('Sign out failed', e);
      throw AppAuthException(
        message: 'Sign out failed: $e',
        originalException: e,
      );
    }
  }

  /// Get current user
  User? getCurrentUser() {
    return supabase.auth.currentUser;
  }

  /// Get current user ID
  String? getCurrentUserId() {
    return supabase.auth.currentUser?.id;
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return supabase.auth.currentSession != null;
  }

  /// Reset password
  Future<void> resetPassword({required String email}) async {
    try {
      await supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      AppLogger.logError('Password reset failed', e);
      throw AppAuthException(
        message: 'Password reset failed: $e',
        originalException: e,
      );
    }
  }

  /// Update user email
  Future<void> updateEmail({required String newEmail}) async {
    try {
      await supabase.auth.updateUser(UserAttributes(email: newEmail));
    } catch (e) {
      AppLogger.logError('Email update failed', e);
      throw AppAuthException(
        message: 'Email update failed: $e',
        originalException: e,
      );
    }
  }

  /// Update user password
  Future<void> updatePassword({required String newPassword}) async {
    try {
      await supabase.auth.updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      AppLogger.logError('Password update failed', e);
      throw AppAuthException(
        message: 'Password update failed: $e',
        originalException: e,
      );
    }
  }
}
