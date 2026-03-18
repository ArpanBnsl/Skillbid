import '../models/contract_model.dart';
import '../repositories/bid_repository.dart';
import '../repositories/chat_repository.dart';
import '../repositories/job_repository.dart';
import '../services/database_service.dart';
import '../utils/exceptions.dart';
import '../utils/app_logger.dart';

class ContractRepository {
  final _databaseService = DatabaseService();
  final _bidRepository = BidRepository();
  final _chatRepository = ChatRepository();
  final _jobRepository = JobRepository();

  Map<String, dynamic> _mapContractRow(Map<String, dynamic> row) {
    dynamic asIso(dynamic value) {
      if (value is DateTime) return value.toIso8601String();
      return value;
    }

    return {
      'id': row['id'],
      'jobId': row['job_id'],
      'bidId': row['bid_id'],
      'clientId': row['client_id'],
      'providerId': row['provider_id'],
      'status': row['status'] ?? 'active',
      'startDate': asIso(row['start_date']),
      'endDate': asIso(row['end_date']),
      'rating': (row['rating'] as num?)?.toInt(),
      'reviewText': row['review_text'],
      'isDeleted': row['is_deleted'] ?? false,
      'createdAt': asIso(row['created_at']),
      'updatedAt': asIso(row['updated_at']),
    };
  }

  /// Create contract from accepted bid
  Future<ContractModel> createContract({
    required String jobId,
    required String bidId,
    required String clientId,
    required String providerId,
  }) async {
    try {
      final result = await _databaseService.insertData(
        table: 'contracts',
        data: {
          'job_id': jobId,
          'bid_id': bidId,
          'client_id': clientId,
          'provider_id': providerId,
          'start_date': DateTime.now().toIso8601String(),
        },
      );
      return ContractModel.fromJson(_mapContractRow(result));
    } catch (e) {
      AppLogger.logError('Create contract failed for jobId: $jobId', e);
      throw AppException(
        message: 'Create contract failed: $e',
        originalException: e,
      );
    }
  }

  /// Get contract by ID
  Future<ContractModel?> getContractById(String contractId) async {
    try {
      final result = await _databaseService.fetchData(
        table: 'contracts',
        filters: {'id': contractId},
      );
      if (result.isEmpty) return null;
      return ContractModel.fromJson(_mapContractRow(result.first));
    } catch (e) {
      AppLogger.logError('Get contract failed for contractId: $contractId', e);
      throw AppException(
        message: 'Get contract failed: $e',
        originalException: e,
      );
    }
  }

  /// Get client's contracts
  Future<List<ContractModel>> getClientContracts(String clientId, {int limit = 20, int offset = 0}) async {
    try {
      final result = await _databaseService.fetchData(
        table: 'contracts',
        filters: {
          'client_id': clientId,
          'is_deleted': false,
        },
        orderBy: 'created_at',
        descending: true,
        limit: limit,
        offset: offset,
      );
      return result.map((e) => ContractModel.fromJson(_mapContractRow(e))).toList();
    } catch (e) {
      AppLogger.logError('Get client contracts failed for clientId: $clientId', e);
      throw AppException(
        message: 'Get client contracts failed: $e',
        originalException: e,
      );
    }
  }

  /// Get provider's contracts
  Future<List<ContractModel>> getProviderContracts(String providerId, {int limit = 20, int offset = 0}) async {
    try {
      final result = await _databaseService.fetchData(
        table: 'contracts',
        filters: {
          'provider_id': providerId,
          'is_deleted': false,
        },
        orderBy: 'created_at',
        descending: true,
        limit: limit,
        offset: offset,
      );
      return result.map((e) => ContractModel.fromJson(_mapContractRow(e))).toList();
    } catch (e) {
      AppLogger.logError('Get provider contracts failed for providerId: $providerId', e);
      throw AppException(
        message: 'Get provider contracts failed: $e',
        originalException: e,
      );
    }
  }

  /// Update contract status
  Future<void> updateContractStatus({
    required String contractId,
    required String status,
  }) async {
    try {
      await _databaseService.updateData(
        table: 'contracts',
        data: {'status': status},
        id: contractId,
      );
    } catch (e) {
      AppLogger.logError('Update contract status failed for contractId: $contractId', e);
      throw AppException(
        message: 'Update contract status failed: $e',
        originalException: e,
      );
    }
  }

  Future<ContractModel> acceptBidAndCreateContract({
    required String bidId,
    required String jobId,
    required String clientId,
  }) async {
    final bid = await _bidRepository.getBidById(bidId);
    if (bid == null) {
      throw AppException(message: 'Bid not found');
    }
    if (bid.providerId == clientId) {
      throw AppException(message: 'You cannot accept your own bid');
    }

    await _bidRepository.updateBidStatus(bidId: bidId, status: 'accepted');
    await _bidRepository.rejectOtherBidsForJob(jobId: jobId, acceptedBidId: bidId);

    final contract = await createContract(
      jobId: jobId,
      bidId: bidId,
      clientId: clientId,
      providerId: bid.providerId,
    );

    await _jobRepository.updateJob(jobId: jobId, status: 'in_progress');
    await _chatRepository.ensureContractChat(
      contractId: contract.id,
      clientId: clientId,
      providerId: bid.providerId,
    );

    return contract;
  }

  /// Add review to contract
  Future<void> addReview({
    required String contractId,
    required int rating,
    required String reviewText,
  }) async {
    try {
      await _databaseService.updateData(
        table: 'contracts',
        data: {
          'rating': rating,
          'review_text': reviewText,
        },
        id: contractId,
      );
    } catch (e) {
      AppLogger.logError('Add review failed for contractId: $contractId', e);
      throw AppException(
        message: 'Add review failed: $e',
        originalException: e,
      );
    }
  }

  /// Complete contract
  Future<void> completeContract(String contractId) async {
    try {
      final contract = await getContractById(contractId);
      if (contract == null) throw AppException(message: 'Contract not found');
      await updateContractStatus(contractId: contractId, status: 'completed');
      await _databaseService.updateData(
        table: 'contracts',
        data: {
          'completed_at': DateTime.now().toIso8601String(),
          'end_date': DateTime.now().toIso8601String(),
        },
        id: contractId,
      );
      await _jobRepository.updateJob(jobId: contract.jobId, status: 'completed');
      // Close the associated chat
      await _chatRepository.closeChatByContract(contractId);
    } catch (e) {
      AppLogger.logError('Complete contract failed for contractId: $contractId', e);
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Complete contract failed: $e',
        originalException: e,
      );
    }
  }

  Future<void> submitWork(String contractId) async {
    try {
      await _databaseService.updateData(
        table: 'contracts',
        data: {
          'status': 'work_submitted',
          'work_submitted_at': DateTime.now().toIso8601String(),
        },
        id: contractId,
      );
    } catch (e) {
      AppLogger.logError('Submit work failed for contractId: $contractId', e);
      throw AppException(
        message: 'Submit work failed: $e',
        originalException: e,
      );
    }
  }

  Future<void> approveSubmittedWork(String contractId) async {
    try {
      await completeContract(contractId);
    } catch (e) {
      AppLogger.logError('Approve submitted work failed for contractId: $contractId', e);
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Approve submitted work failed: $e',
        originalException: e,
      );
    }
  }

  /// Cancel contract
  Future<void> cancelContract(String contractId) async {
    try {
      await updateContractStatus(contractId: contractId, status: 'cancelled');
    } catch (e) {
      AppLogger.logError('Cancel contract failed for contractId: $contractId', e);
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Cancel contract failed: $e',
        originalException: e,
      );
    }
  }

  /// Delete contract (soft delete)
  Future<void> deleteContract(String contractId) async {
    try {
      await _databaseService.softDeleteData(
        table: 'contracts',
        id: contractId,
      );
    } catch (e) {
      AppLogger.logError('Delete contract failed for contractId: $contractId', e);
      throw AppException(
        message: 'Delete contract failed: $e',
        originalException: e,
      );
    }
  }

  /// Get contract by job ID
  Future<ContractModel?> getContractByJobId(String jobId) async {
    try {
      final result = await _databaseService.fetchData(
        table: 'contracts',
        filters: {
          'job_id': jobId,
          'is_deleted': false,
        },
      );
      if (result.isEmpty) return null;
      return ContractModel.fromJson(_mapContractRow(result.first));
    } catch (e) {
      AppLogger.logError('Get contract by job failed for jobId: $jobId', e);
      throw AppException(
        message: 'Get contract by job failed: $e',
        originalException: e,
      );
    }
  }

  Future<double?> getProviderAverageRating(String providerId) async {
    try {
      final contracts = await getProviderContracts(providerId, limit: 100, offset: 0);
      final ratings = contracts
          .where((contract) => contract.rating != null)
          .map((contract) => contract.rating!.toDouble())
          .toList();
      if (ratings.isEmpty) return null;
      final sum = ratings.reduce((a, b) => a + b);
      return sum / ratings.length;
    } catch (e) {
      AppLogger.logError('Get provider average rating failed for providerId: $providerId', e);
      return null;
    }
  }
}
