import '../models/user/profile_model.dart';
import '../models/user/provider_profile_model.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../utils/exceptions.dart';
import '../utils/app_logger.dart';

class UserRepository {
  final _databaseService = DatabaseService();
  final _storageService = StorageService();

  Map<String, dynamic> _mapProviderProfileRow(Map<String, dynamic> row) {
    dynamic asIso(dynamic value) {
      if (value is DateTime) return value.toUtc().toIso8601String();
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) {
          return parsed.toUtc().toIso8601String();
        }
      }
      return value;
    }

    return {
      'userId': row['user_id'],
      'bio': row['bio'],
      'experienceYears': (row['experience_years'] as num?)?.toInt() ?? 0,
      'hourlyRate': (row['hourly_rate'] as num?)?.toDouble() ?? 0,
      'relScore': (row['rel_score'] as num?)?.toDouble() ?? 5.0,
      'relStreak': (row['rel_streak'] as num?)?.toInt() ?? 0,
      'isBanned': row['is_banned'] ?? false,
      'verified': row['verified'] ?? false,
      'isDeleted': row['is_deleted'] ?? false,
      'createdAt': asIso(row['created_at']),
      'updatedAt': asIso(row['updated_at']),
    };
  }

  Map<String, dynamic> _mapProfileRow(Map<String, dynamic> row) {
    dynamic asIso(dynamic value) {
      if (value is DateTime) return value.toUtc().toIso8601String();
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) {
          return parsed.toUtc().toIso8601String();
        }
      }
      return value;
    }

    return {
      'id': row['id'],
      'fullName': row['full_name'],
      'phone': row['phone'],
      'avatarUrl': row['avatar_url'],
      'lastRole': row['last_role'],
      'averageRating': (row['average_rating'] as num?)?.toDouble(),
      'isDeleted': row['is_deleted'] ?? false,
      'latitude': (row['latitude'] as num?)?.toDouble(),
      'longitude': (row['longitude'] as num?)?.toDouble(),
      'locationUpdatedAt': asIso(row['location_updated_at']),
      'immReqCnt': (row['imm_req_cnt'] as num?)?.toInt() ?? 0,
      'createdAt': asIso(row['created_at']),
      'updatedAt': asIso(row['updated_at']),
    };
  }

  /// Get user profile by ID
  Future<ProfileModel?> getUserProfile(String userId) async {
    try {
      final result = await _databaseService.fetchData(
        table: 'profiles',
        filters: {'id': userId},
      );
      if (result.isEmpty) return null;
      return ProfileModel.fromJson(_mapProfileRow(result.first));
    } catch (e) {
      AppLogger.logError('Get user profile failed for userId: $userId', e);
      throw AppException(
        message: 'Get user profile failed: $e',
        originalException: e,
      );
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    final data = <String, dynamic>{};
    if (fullName != null) data['full_name'] = fullName;
    if (phone != null) data['phone'] = phone;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;

    await _databaseService.updateData(
      table: 'profiles',
      data: data,
      id: userId,
    );
  }

  /// Get provider profile
  Future<ProviderProfileModel?> getProviderProfile(String providerId) async {
    try {
      final result = await _databaseService.fetchData(
        table: 'provider_profiles',
        filters: {'user_id': providerId},
      );
      if (result.isEmpty) return null;
      return ProviderProfileModel.fromJson(_mapProviderProfileRow(result.first));
    } catch (e) {
      AppLogger.logError('Get provider profile failed for providerId: $providerId', e);
      throw AppException(
        message: 'Get provider profile failed: $e',
        originalException: e,
      );
    }
  }

  /// Update provider profile
  Future<void> updateProviderProfile({
    required String providerId,
    String? bio,
    int? experienceYears,
    double? hourlyRate,
  }) async {
    final data = <String, dynamic>{};
    if (bio != null) data['bio'] = bio;
    if (experienceYears != null) data['experience_years'] = experienceYears;
    if (hourlyRate != null) data['hourly_rate'] = hourlyRate;

    await _databaseService.updateData(
      table: 'provider_profiles',
      data: data,
      id: providerId,
      idColumn: 'user_id',
    );
  }

  /// Create or update provider profile in one step.
  Future<void> upsertProviderProfile({
    required String providerId,
    String? bio,
    required int experienceYears,
    required double hourlyRate,
  }) async {
    await _databaseService.upsertData(
      table: 'provider_profiles',
      onConflict: 'user_id',
      data: {
        'user_id': providerId,
        'bio': bio,
        'experience_years': experienceYears,
        'hourly_rate': hourlyRate,
      },
    );
  }

  /// Replace provider skills with a new skill list.
  Future<void> setProviderSkills({
    required String providerId,
    required List<int> skillIds,
  }) async {
    await _databaseService.deleteWhere(
      table: 'provider_skills',
      filters: {'provider_id': providerId},
    );

    if (skillIds.isEmpty) return;

    final rows = skillIds
        .map((skillId) => {
              'provider_id': providerId,
              'skill_id': skillId,
            })
        .toList();

    await _databaseService.insertMany(
      table: 'provider_skills',
      data: rows,
    );
  }

  Future<List<int>> getProviderSkills(String providerId) async {
    final rows = await _databaseService.fetchData(
      table: 'provider_skills',
      select: 'skill_id',
      filters: {'provider_id': providerId},
    );
    return rows.map((e) => (e['skill_id'] as num).toInt()).toList();
  }

  /// Get user role
  Future<String?> getUserRole(String userId) async {
    try {
      final result = await _databaseService.fetchData(
        table: 'profiles',
        select: 'last_role',
        filters: {'id': userId},
      );
      if (result.isEmpty) return null;
      return result.first['last_role'];
    } catch (e) {
      AppLogger.logError('Get user role failed for userId: $userId', e);
      return null;
    }
  }

  /// Upload avatar
  Future<String> uploadAvatar(String userId, dynamic imageFile) async {
    try {
      final url = await _storageService.uploadImage(
        image: imageFile,
        bucket: 'avatars',
        path: userId,
      );
      await updateUserProfile(userId: userId, avatarUrl: url);
      return url;
    } catch (e) {
      AppLogger.logError('Upload avatar failed for userId: $userId', e);
      throw AppException(
        message: 'Upload avatar failed: $e',
        originalException: e,
      );
    }
  }

  /// Update user's current location (lat/lng) in profiles table.
  Future<void> updateUserLocation({
    required String userId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _databaseService.updateData(
        table: 'profiles',
        id: userId,
        data: {
          'latitude': latitude,
          'longitude': longitude,
          'location_updated_at': DateTime.now().toUtc().toIso8601String(),
        },
      );
    } catch (e) {
      AppLogger.logError('Update user location failed for userId: $userId', e);
      // Non-fatal: location update failure should not crash the app
    }
  }
}
