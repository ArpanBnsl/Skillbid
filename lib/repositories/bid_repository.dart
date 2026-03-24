import '../config/supabase_config.dart';
import '../models/bid_model.dart';
import '../services/database_service.dart';
import '../utils/exceptions.dart';
import '../utils/app_logger.dart';

class BidRepository {
  final _databaseService = DatabaseService();

  /// Parse a raw Supabase Realtime payload row into a BidModel.
  /// Used by shell Realtime callbacks to inject new bids without a DB round-trip.
  static BidModel bidFromRawRow(Map<String, dynamic> row) {
    dynamic asIso(dynamic v) => v is DateTime ? v.toIso8601String() : v;
    return BidModel.fromJson({
      'id': row['id'],
      'jobId': row['job_id'],
      'providerId': row['provider_id'],
      'amount': (row['amount'] as num?)?.toDouble() ?? 0,
      'estimatedDays': (row['estimated_days'] as num?)?.toInt(),
      'message': row['message'],
      'status': row['status'] ?? 'pending',
      'isDeleted': row['is_deleted'] ?? false,
      'createdAt': asIso(row['created_at']),
      'updatedAt': asIso(row['updated_at'] ?? row['created_at']),
    });
  }

  Map<String, dynamic> _mapBidRow(Map<String, dynamic> row) {
    dynamic asIso(dynamic value) {
      if (value is DateTime) return value.toIso8601String();
      return value;
    }

    return {
      'id': row['id'],
      'jobId': row['job_id'],
      'providerId': row['provider_id'],
      'amount': (row['amount'] as num?)?.toDouble() ?? 0,
      'estimatedDays': (row['estimated_days'] as num?)?.toInt(),
      'message': row['message'],
      'status': row['status'] ?? 'pending',
      'isDeleted': row['is_deleted'] ?? false,
      'createdAt': asIso(row['created_at']),
      'updatedAt': asIso(row['updated_at']),
    };
  }

  /// Create a bid
  Future<BidModel> createBid({
    required String jobId,
    required String providerId,
    required double amount,
    int? estimatedDays,
    String? message,
  }) async {
    try {
      final jobRows = await _databaseService.fetchData(
        table: 'jobs',
        select: 'client_id,status,is_deleted',
        filters: {'id': jobId},
      );
      if (jobRows.isEmpty) {
        throw AppException(message: 'Job not found');
      }

      final job = jobRows.first;
      if (job['is_deleted'] == true) {
        throw AppException(message: 'This job is no longer available');
      }
      if (job['status'] != 'open') {
        throw AppException(message: 'Bids can only be placed on open jobs');
      }
      if (job['client_id'] == providerId) {
        throw AppException(message: 'You cannot bid on your own project');
      }

      final result = await _databaseService.insertData(
        table: 'bids',
        data: {
          'job_id': jobId,
          'provider_id': providerId,
          'amount': amount,
          'estimated_days': estimatedDays,
          'message': message,
        },
      );
      return BidModel.fromJson(_mapBidRow(result));
    } catch (e) {
      AppLogger.logError('Create bid failed for jobId: $jobId, providerId: $providerId', e);
      throw AppException(
        message: 'Create bid failed: $e',
        originalException: e,
      );
    }
  }

  /// Get bid by ID
  Future<BidModel?> getBidById(String bidId) async {
    try {
      final result = await _databaseService.fetchData(
        table: 'bids',
        filters: {'id': bidId},
      );
      if (result.isEmpty) return null;
      return BidModel.fromJson(_mapBidRow(result.first));
    } catch (e) {
      AppLogger.logError('Get bid failed for bidId: $bidId', e);
      throw AppException(
        message: 'Get bid failed: $e',
        originalException: e,
      );
    }
  }

  /// Live stream of bids for a job — updates in real-time via Supabase Realtime
  Stream<List<BidModel>> streamJobBids(String jobId) {
    return supabase
        .from('bids')
        .stream(primaryKey: ['id'])
        .eq('job_id', jobId)
        .order('created_at', ascending: false)
        .map((rows) => rows
            .where((r) => r['is_deleted'] != true)
            .map((row) => BidModel.fromJson(_mapBidRow(row)))
            .toList());
  }

  /// Live stream of a provider's bids — updates in real-time via Supabase Realtime
  Stream<List<BidModel>> streamProviderBids(String providerId) {
    return supabase
        .from('bids')
        .stream(primaryKey: ['id'])
        .eq('provider_id', providerId)
        .order('created_at', ascending: false)
        .map((rows) => rows
            .where((r) => r['is_deleted'] != true)
            .map((row) => BidModel.fromJson(_mapBidRow(row)))
            .toList());
  }

  /// Get bids for a job
  Future<List<BidModel>> getJobBids(String jobId) async {
    try {
      final result = await _databaseService.fetchData(
        table: 'bids',
        filters: {
          'job_id': jobId,
          'is_deleted': false,
        },
        orderBy: 'created_at',
        descending: true,
      );
      return result.map((e) => BidModel.fromJson(_mapBidRow(e))).toList();
    } catch (e) {
      AppLogger.logError('Get job bids failed for jobId: $jobId', e);
      throw AppException(
        message: 'Get job bids failed: $e',
        originalException: e,
      );
    }
  }

  /// Get provider's bids
  Future<List<BidModel>> getProviderBids(String providerId, {int limit = 20, int offset = 0}) async {
    try {
      final result = await _databaseService.fetchData(
        table: 'bids',
        filters: {
          'provider_id': providerId,
          'is_deleted': false,
        },
        orderBy: 'created_at',
        descending: true,
        limit: limit,
        offset: offset,
      );
      return result.map((e) => BidModel.fromJson(_mapBidRow(e))).toList();
    } catch (e) {
      AppLogger.logError('Get provider bids failed for providerId: $providerId', e);
      throw AppException(
        message: 'Get provider bids failed: $e',
        originalException: e,
      );
    }
  }

  /// Update bid status
  Future<void> updateBidStatus({
    required String bidId,
    required String status,
  }) async {
    try {
      await _databaseService.updateData(
        table: 'bids',
        data: {'status': status},
        id: bidId,
      );
    } catch (e) {
      AppLogger.logError('Update bid status failed for bidId: $bidId, status: $status', e);
      throw AppException(
        message: 'Update bid status failed: $e',
        originalException: e,
      );
    }
  }

  /// Withdraw bid
  Future<void> withdrawBid(String bidId) async {
    try {
      await updateBidStatus(bidId: bidId, status: 'withdrawn');
    } catch (e) {
      AppLogger.logError('Withdraw bid failed for bidId: $bidId', e);
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Withdraw bid failed: $e',
        originalException: e,
      );
    }
  }

  /// Delete bid (soft delete)
  Future<void> deleteBid(String bidId) async {
    try {
      await _databaseService.softDeleteData(
        table: 'bids',
        id: bidId,
      );
    } catch (e) {
      AppLogger.logError('Delete bid failed for bidId: $bidId', e);
      throw AppException(
        message: 'Delete bid failed: $e',
        originalException: e,
      );
    }
  }

  /// Check if provider already bid on job
  Future<bool> hasProviderBidOnJob({
    required String jobId,
    required String providerId,
  }) async {
    try {
      final result = await _databaseService.fetchData(
        table: 'bids',
        filters: {
          'job_id': jobId,
          'provider_id': providerId,
          'is_deleted': false,
        },
      );
      return result.isNotEmpty;
    } catch (e) {
      AppLogger.logError('Check provider bid failed for jobId: $jobId, providerId: $providerId', e);
      return false;
    }
  }

  Future<void> rejectOtherBidsForJob({
    required String jobId,
    required String acceptedBidId,
  }) async {
    try {
      final bids = await getJobBids(jobId);
      for (final bid in bids) {
        if (bid.id != acceptedBidId && bid.status == 'pending') {
          await updateBidStatus(bidId: bid.id, status: 'rejected');
        }
      }
    } catch (e) {
      AppLogger.logError('Reject other bids failed for jobId: $jobId', e);
      throw AppException(
        message: 'Reject other bids failed: $e',
        originalException: e,
      );
    }
  }
}
