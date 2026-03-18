import '../models/job/job_model.dart';
import '../models/job/job_image_model.dart';
import '../models/skill_model.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../utils/exceptions.dart';
import '../utils/app_logger.dart';

class JobRepository {
  final _databaseService = DatabaseService();
  final _storageService = StorageService();

  Map<String, dynamic> _mapJobRow(Map<String, dynamic> row) {
    dynamic asIso(dynamic value) {
      if (value is DateTime) return value.toIso8601String();
      return value;
    }

    return {
      'id': row['id'],
      'clientId': row['client_id'],
      'title': row['title'],
      'description': row['description'],
      'budget': (row['budget'] as num?)?.toDouble() ?? 0,
      'location': row['location'],
      'skillId': (row['skill_id'] as num?)?.toInt() ?? 0,
      'desiredCompletionDays': (row['desired_completion_days'] as num?)?.toInt(),
      'status': row['status'] ?? 'open',
      'isDeleted': row['is_deleted'] ?? false,
      'createdAt': asIso(row['created_at']),
      'updatedAt': asIso(row['updated_at']),
    };
  }

  Map<String, dynamic> _mapJobImageRow(Map<String, dynamic> row) {
    dynamic asIso(dynamic value) {
      if (value is DateTime) return value.toIso8601String();
      return value;
    }

    return {
      'id': row['id'],
      'jobId': row['job_id'],
      'imageUrl': row['image_url'],
      'createdAt': asIso(row['created_at']),
    };
  }

  /// Get all skills (categories)
  Future<List<SkillModel>> getAllSkills() async {
    try {
      final result = await _databaseService.fetchData(table: 'skills');
      return result.map((e) => SkillModel.fromJson(e)).toList();
    } catch (e) {
      AppLogger.logError('Get skills failed', e);
      throw AppException(
        message: 'Get skills failed: $e',
        originalException: e,
      );
    }
  }

  /// Get skill by ID
  Future<SkillModel?> getSkillById(int skillId) async {
    try {
      final result = await _databaseService.fetchData(
        table: 'skills',
        filters: {'id': skillId},
      );
      if (result.isEmpty) return null;
      return SkillModel.fromJson(result.first);
    } catch (e) {
      AppLogger.logError('Get skill failed for skillId: $skillId', e);
      throw AppException(
        message: 'Get skill failed: $e',
        originalException: e,
      );
    }
  }

  /// Create new job
  Future<JobModel> createJob({
    required String clientId,
    required String title,
    required String description,
    required double budget,
    required String location,
    required int skillId,
    int? desiredCompletionDays,
  }) async {
    try {
      final result = await _databaseService.insertData(
        table: 'jobs',
        data: {
          'client_id': clientId,
          'title': title,
          'description': description,
          'budget': budget,
          'location': location,
          'skill_id': skillId,
          'desired_completion_days': desiredCompletionDays,
        },
      );
      return JobModel.fromJson(_mapJobRow(result));
    } catch (e) {
      AppLogger.logError('Create job failed', e);
      throw AppException(
        message: 'Create job failed: $e',
        originalException: e,
      );
    }
  }

  /// Get job by ID
  Future<JobModel?> getJobById(String jobId) async {
    try {
      final result = await _databaseService.fetchData(
        table: 'jobs',
        filters: {'id': jobId},
      );
      if (result.isEmpty) return null;
      return JobModel.fromJson(_mapJobRow(result.first));
    } catch (e) {
      AppLogger.logError('Get job failed for jobId: $jobId', e);
      throw AppException(
        message: 'Get job failed: $e',
        originalException: e,
      );
    }
  }

  /// Get all available jobs (open)
  Future<List<JobModel>> getAvailableJobs({int limit = 20, int offset = 0}) async {
    try {
      final result = await _databaseService.fetchData(
        table: 'jobs',
        filters: {
          'status': 'open',
          'is_deleted': false,
        },
        orderBy: 'created_at',
        descending: true,
        limit: limit,
        offset: offset,
      );
      return result.map((e) => JobModel.fromJson(_mapJobRow(e))).toList();
    } catch (e) {
      AppLogger.logError('Get available jobs failed', e);
      throw AppException(
        message: 'Get available jobs failed: $e',
        originalException: e,
      );
    }
  }

  /// Get client's jobs
  Future<List<JobModel>> getClientJobs(String clientId, {int limit = 20, int offset = 0}) async {
    try {
      final result = await _databaseService.fetchData(
        table: 'jobs',
        filters: {
          'client_id': clientId,
          'is_deleted': false,
        },
        orderBy: 'created_at',
        descending: true,
        limit: limit,
        offset: offset,
      );
      return result.map((e) => JobModel.fromJson(_mapJobRow(e))).toList();
    } catch (e) {
      AppLogger.logError('Get client jobs failed for clientId: $clientId', e);
      throw AppException(
        message: 'Get client jobs failed: $e',
        originalException: e,
      );
    }
  }

  /// Get jobs by skill
  Future<List<JobModel>> getJobsBySkill(int skillId, {int limit = 20, int offset = 0}) async {
    try {
      final result = await _databaseService.fetchData(
        table: 'jobs',
        filters: {
          'skill_id': skillId,
          'status': 'open',
          'is_deleted': false,
        },
        orderBy: 'created_at',
        descending: true,
        limit: limit,
        offset: offset,
      );
      return result.map((e) => JobModel.fromJson(_mapJobRow(e))).toList();
    } catch (e) {
      AppLogger.logError('Get jobs by skill failed for skillId: $skillId', e);
      throw AppException(
        message: 'Get jobs by skill failed: $e',
        originalException: e,
      );
    }
  }

  /// Update job
  Future<void> updateJob({
    required String jobId,
    String? title,
    String? description,
    String? status,
  }) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (status != null) data['status'] = status;

    await _databaseService.updateData(
      table: 'jobs',
      data: data,
      id: jobId,
    );
  }

  /// Add job image
  Future<JobImageModel> addJobImage({
    required String jobId,
    required dynamic imageFile,
  }) async {
    try {
      final imageUrl = await _storageService.uploadImage(
        image: imageFile,
        bucket: 'job-images',
        path: jobId,
      );

      final result = await _databaseService.insertData(
        table: 'job_images',
        data: {
          'job_id': jobId,
          'image_url': imageUrl,
        },
      );
      return JobImageModel.fromJson(_mapJobImageRow(result));
    } catch (e) {
      AppLogger.logError('Add job image failed for jobId: $jobId', e);
      throw AppException(
        message: 'Add job image failed: $e',
        originalException: e,
      );
    }
  }

  /// Get job images
  Future<List<JobImageModel>> getJobImages(String jobId) async {
    try {
      final result = await _databaseService.fetchData(
        table: 'job_images',
        filters: {'job_id': jobId},
      );
      return result.map((e) => JobImageModel.fromJson(_mapJobImageRow(e))).toList();
    } catch (e) {
      AppLogger.logError('Get job images failed for jobId: $jobId', e);
      throw AppException(
        message: 'Get job images failed: $e',
        originalException: e,
      );
    }
  }

  /// Delete job (soft delete)
  Future<void> deleteJob(String jobId) async {
    try {
      await _databaseService.softDeleteData(
        table: 'jobs',
        id: jobId,
      );
    } catch (e) {
      AppLogger.logError('Delete job failed for jobId: $jobId', e);
      throw AppException(
        message: 'Delete job failed: $e',
        originalException: e,
      );
    }
  }
}
