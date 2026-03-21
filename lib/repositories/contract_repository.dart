import '../config/app_constants.dart';
import '../models/contract_model.dart';
import '../repositories/bid_repository.dart';
import '../repositories/chat_repository.dart';
import '../repositories/job_repository.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../services/route_service.dart';
import '../utils/app_logger.dart';
import '../utils/exceptions.dart';

class ContractRepository {
  final _databaseService = DatabaseService();
  final _bidRepository = BidRepository();
  final _chatRepository = ChatRepository();
  final _jobRepository = JobRepository();
  final _routeService = RouteService();

  double _clampScore(double value) {
    if (value < 0) return 0;
    if (value > 10) return 10;
    return value;
  }

  Future<void> _applyReliabilityFault({
    required String providerId,
    required double penalty,
  }) async {
    final rows = await _databaseService.fetchData(
      table: 'provider_profiles',
      select: 'rel_score,rel_streak,is_banned',
      filters: {'user_id': providerId},
    );
    if (rows.isEmpty) return;

    final currentScore = (rows.first['rel_score'] as num?)?.toDouble() ?? 5.0;
    final nextScore = _clampScore(currentScore - penalty);
    final banned = nextScore <= 0;

    await _databaseService.updateData(
      table: 'provider_profiles',
      id: providerId,
      idColumn: 'user_id',
      data: {
        'rel_score': nextScore,
        'rel_streak': 0,
        'is_banned': banned,
      },
    );
  }

  Future<void> _applyReliabilityReward(String providerId) async {
    final rows = await _databaseService.fetchData(
      table: 'provider_profiles',
      select: 'rel_score,rel_streak,is_banned',
      filters: {'user_id': providerId},
    );
    if (rows.isEmpty) return;

    final currentScore = (rows.first['rel_score'] as num?)?.toDouble() ?? 5.0;
    final currentStreak = (rows.first['rel_streak'] as num?)?.toInt() ?? 0;

    final increment = currentStreak <= 0
        ? 0.5
        : (currentStreak == 1 ? 0.6 : 0.7);
    final nextScore = _clampScore(currentScore + increment);

    await _databaseService.updateData(
      table: 'provider_profiles',
      id: providerId,
      idColumn: 'user_id',
      data: {
        'rel_score': nextScore,
        'rel_streak': currentStreak + 1,
        'is_banned': false,
      },
    );
  }

  Future<void> _enforceReliabilityOnActiveContracts() async {
    final activeRows = await _databaseService.fetchData(
      table: 'contracts',
      select:
          'id,job_id,provider_id,status,is_deleted,response_due_at,first_provider_response_at,arrival_due_at,arrived_at,terminated_by',
      filters: {
        'status': AppConstants.contractStatusActive,
        'is_deleted': false,
      },
    );

    if (activeRows.isEmpty) return;
    final now = DateTime.now().toUtc();

    for (final row in activeRows) {
      final contractId = row['id'] as String;
      final providerId = row['provider_id'] as String;
      final jobId = row['job_id'] as String;

      final job = await _jobRepository.getJobById(jobId);
      if (job == null) continue;

      if (job.isImmediate) {
        final arrivalDueRaw = row['arrival_due_at'];
        final arrivedRaw = row['arrived_at'];
        final arrivalDueAt = arrivalDueRaw == null
            ? null
            : DateTime.tryParse(arrivalDueRaw.toString())?.toUtc();
        final arrivedAt = arrivedRaw == null
            ? null
            : DateTime.tryParse(arrivedRaw.toString())?.toUtc();

        if (arrivalDueAt == null) {
          await _databaseService.updateData(
            table: 'contracts',
            id: contractId,
            data: {
              'arrival_due_at': now.add(const Duration(minutes: 60)).toIso8601String(),
            },
          );
          continue;
        }

        if (arrivedAt == null && now.isAfter(arrivalDueAt)) {
          await _databaseService.updateData(
            table: 'contracts',
            id: contractId,
            data: {
              'status': AppConstants.contractStatusTerminated,
              'terminated_by': AppConstants.contractTerminatedByProvider,
              'end_date': now.toIso8601String(),
              'tracking_enabled': false,
            },
          );
          await _jobRepository.updateJob(
            jobId: jobId,
            status: AppConstants.jobStatusCancelled,
          );
          await _chatRepository.closeChatByContract(contractId);
          await _applyReliabilityFault(providerId: providerId, penalty: 0.7);
        }
      } else {
        final responseDueRaw = row['response_due_at'];
        final firstProviderResponseRaw = row['first_provider_response_at'];
        final responseDueAt = responseDueRaw == null
            ? null
            : DateTime.tryParse(responseDueRaw.toString())?.toUtc();
        final firstProviderResponseAt = firstProviderResponseRaw == null
            ? null
            : DateTime.tryParse(firstProviderResponseRaw.toString())?.toUtc();

        if (responseDueAt != null &&
            firstProviderResponseAt == null &&
            now.isAfter(responseDueAt)) {
          await _databaseService.updateData(
            table: 'contracts',
            id: contractId,
            data: {
              'status': AppConstants.contractStatusTerminated,
              'terminated_by': AppConstants.contractTerminatedByProvider,
              'end_date': now.toIso8601String(),
              'tracking_enabled': false,
            },
          );
          await _jobRepository.updateJob(
            jobId: jobId,
            status: AppConstants.jobStatusCancelled,
          );
          await _chatRepository.closeChatByContract(contractId);
          await _applyReliabilityFault(providerId: providerId, penalty: 0.5);
        }
      }
    }
  }

  Map<String, dynamic> _mapContractRow(Map<String, dynamic> row) {
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
      'jobId': row['job_id'],
      'bidId': row['bid_id'],
      'clientId': row['client_id'],
      'providerId': row['provider_id'],
      'status': row['status'] ?? AppConstants.contractStatusActive,
      'terminatedBy': row['terminated_by'],
      'startDate': asIso(row['start_date']),
      'endDate': asIso(row['end_date']),
      'workSubmittedAt': asIso(row['work_submitted_at']),
      'providerRating': (row['provider_rating'] as num?)?.toInt() ?? (row['rating'] as num?)?.toInt(),
      'clientRating': (row['client_rating'] as num?)?.toInt(),
      'reviewText': row['review_text'],
      'isDeleted': row['is_deleted'] ?? false,
      'providerLat': (row['provider_lat'] as num?)?.toDouble(),
      'providerLng': (row['provider_lng'] as num?)?.toDouble(),
      'lastLocationUpdate': asIso(row['last_location_update']),
      'trackingEnabled': row['tracking_enabled'] ?? false,
      'createdAt': asIso(row['created_at']),
      'updatedAt': asIso(row['updated_at']),
    };
  }

  Future<void> _recomputeRatings({
    required String clientId,
    required String providerId,
  }) async {
    try {
      final providerContracts = await _databaseService.fetchData(
        table: 'contracts',
        select: 'provider_rating,status',
        filters: {
          'provider_id': providerId,
          'is_deleted': false,
          'status': AppConstants.contractStatusCompleted,
        },
      );

      final providerRatings = providerContracts
          .map((e) => (e['provider_rating'] as num?)?.toDouble())
          .whereType<double>()
          .toList();
      final providerAverage = providerRatings.isEmpty
          ? null
          : providerRatings.reduce((a, b) => a + b) / providerRatings.length;

      await _databaseService.updateData(
        table: 'provider_profiles',
        id: providerId,
        idColumn: 'user_id',
        data: {
          'average_rating': providerAverage,
        },
      );

      final clientContracts = await _databaseService.fetchData(
        table: 'contracts',
        select: 'client_rating,status',
        filters: {
          'client_id': clientId,
          'is_deleted': false,
          'status': AppConstants.contractStatusCompleted,
        },
      );

      final clientRatings = clientContracts
          .map((e) => (e['client_rating'] as num?)?.toDouble())
          .whereType<double>()
          .toList();
      final clientAverage = clientRatings.isEmpty
          ? null
          : clientRatings.reduce((a, b) => a + b) / clientRatings.length;

      await _databaseService.updateData(
        table: 'profiles',
        id: clientId,
        data: {
          'average_rating': clientAverage,
        },
      );
    } catch (e) {
      // Do not fail review submission when aggregate columns are missing.
      AppLogger.logError('Recompute ratings failed for clientId: $clientId, providerId: $providerId', e);
    }
  }

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
          'status': AppConstants.contractStatusActive,
          'start_date': DateTime.now().toUtc().toIso8601String(),
        },
      );
      return ContractModel.fromJson(_mapContractRow(result));
    } catch (e) {
      AppLogger.logError('Create contract failed for jobId: $jobId', e);
      throw AppException(message: 'Create contract failed: $e', originalException: e);
    }
  }

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
      throw AppException(message: 'Get contract failed: $e', originalException: e);
    }
  }

  Future<List<ContractModel>> getClientContracts(String clientId, {int limit = 20, int offset = 0}) async {
    try {
      await _enforceReliabilityOnActiveContracts();
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
      throw AppException(message: 'Get client contracts failed: $e', originalException: e);
    }
  }

  Future<List<ContractModel>> getProviderContracts(String providerId, {int limit = 20, int offset = 0}) async {
    try {
      await _enforceReliabilityOnActiveContracts();
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
      throw AppException(message: 'Get provider contracts failed: $e', originalException: e);
    }
  }

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
      throw AppException(message: 'Update contract status failed: $e', originalException: e);
    }
  }

  Future<ContractModel> acceptBidAndCreateContract({
    required String bidId,
    required String jobId,
    required String clientId,
  }) async {
    final bid = await _bidRepository.getBidById(bidId);
    if (bid == null) throw AppException(message: 'Bid not found');
    if (bid.providerId == clientId) throw AppException(message: 'You cannot accept your own bid');

    final job = await _jobRepository.getJobById(jobId);
    if (job == null || job.isDeleted) {
      throw AppException(message: 'Job not found');
    }
    if (job.status != AppConstants.jobStatusOpen) {
      throw AppException(message: 'Only open jobs can accept bids');
    }

    final providerRows = await _databaseService.fetchData(
      table: 'provider_profiles',
      select: 'is_banned,rel_score',
      filters: {'user_id': bid.providerId},
    );
    if (providerRows.isNotEmpty) {
      final isBanned = providerRows.first['is_banned'] == true;
      final relScore = (providerRows.first['rel_score'] as num?)?.toDouble() ?? 5.0;
      if (isBanned || relScore <= 0) {
        throw AppException(message: 'This provider is restricted due to low reliability score');
      }
    }

    final existing = await getContractByJobId(jobId);
    if (existing != null && !existing.isDeleted && existing.status == AppConstants.contractStatusActive) {
      throw AppException(message: 'This job already has an active contract');
    }

    await _bidRepository.updateBidStatus(bidId: bidId, status: AppConstants.bidStatusAccepted);
    await _bidRepository.rejectOtherBidsForJob(jobId: jobId, acceptedBidId: bidId);

    final contract = await createContract(
      jobId: jobId,
      bidId: bidId,
      clientId: clientId,
      providerId: bid.providerId,
    );

    await _jobRepository.updateJob(jobId: jobId, status: AppConstants.jobStatusInProgress);
    await _chatRepository.ensureContractChat(
      contractId: contract.id,
      clientId: clientId,
      providerId: bid.providerId,
    );

    // Enable tracking if the job is immediate
    if (job.isImmediate) {
      try {
        DateTime? arrivalDueAt;
        if (job.jobLat != null && job.jobLng != null) {
          final providerLocRows = await _databaseService.fetchData(
            table: 'profiles',
            select: 'latitude,longitude',
            filters: {'id': bid.providerId},
          );
          if (providerLocRows.isNotEmpty) {
            final pLat = (providerLocRows.first['latitude'] as num?)?.toDouble();
            final pLng = (providerLocRows.first['longitude'] as num?)?.toDouble();
            if (pLat != null && pLng != null) {
              final route = await _routeService.getRoute(
                providerLat: pLat,
                providerLng: pLng,
                clientLat: job.jobLat!,
                clientLng: job.jobLng!,
              );

              if (route != null) {
                final etaMin = (route.durationSeconds / 60).ceil();
                arrivalDueAt = DateTime.now().toUtc().add(Duration(minutes: etaMin + 15));
              } else {
                final distance = LocationService.distanceKm(pLat, pLng, job.jobLat!, job.jobLng!);
                final etaMin = LocationService.estimateTravelMinutes(distance, avgSpeedKmh: 30);
                arrivalDueAt = DateTime.now().toUtc().add(Duration(minutes: etaMin.ceil() + 15));
              }
            }
          }
        }
        arrivalDueAt ??= DateTime.now().toUtc().add(const Duration(minutes: 60));

        await _databaseService.updateData(
          table: 'contracts',
          id: contract.id,
          data: {
            'tracking_enabled': true,
            'arrival_due_at': arrivalDueAt.toIso8601String(),
          },
        );
      } catch (e) {
        AppLogger.logError('Enable tracking failed for contract: ${contract.id}', e);
      }
    }

    return contract;
  }

  Future<void> addReview({
    required String contractId,
    required int rating,
    required String reviewText,
  }) async {
    await addClientReview(contractId: contractId, providerRating: rating, reviewText: reviewText);
  }

  Future<void> addClientReview({
    required String contractId,
    required int providerRating,
    required String reviewText,
  }) async {
    try {
      final contract = await getContractById(contractId);
      if (contract == null) throw AppException(message: 'Contract not found');
      if (contract.status != AppConstants.contractStatusCompleted) {
        throw AppException(message: 'Reviews are only allowed on completed contracts');
      }
      try {
        await _databaseService.updateData(
          table: 'contracts',
          data: {
            'provider_rating': providerRating,
            'review_text': reviewText,
          },
          id: contractId,
        );
      } catch (_) {
        // Backward-compatible fallback for older schema using `rating`.
        await _databaseService.updateData(
          table: 'contracts',
          data: {
            'rating': providerRating,
            'review_text': reviewText,
          },
          id: contractId,
        );
      }
      await _recomputeRatings(clientId: contract.clientId, providerId: contract.providerId);
    } catch (e) {
      AppLogger.logError('Add client review failed for contractId: $contractId', e);
      if (e is AppException) rethrow;
      throw AppException(message: 'Add review failed: $e', originalException: e);
    }
  }

  Future<void> addProviderRating({
    required String contractId,
    required int clientRating,
  }) async {
    try {
      final contract = await getContractById(contractId);
      if (contract == null) throw AppException(message: 'Contract not found');
      if (contract.status != AppConstants.contractStatusCompleted) {
        throw AppException(message: 'Ratings are only allowed on completed contracts');
      }
      try {
        await _databaseService.updateData(
          table: 'contracts',
          data: {
            'client_rating': clientRating,
          },
          id: contractId,
        );
      } catch (e) {
        throw AppException(
          message: 'Client rating column missing in database. Apply latest migration and retry.',
          originalException: e,
        );
      }
      await _recomputeRatings(clientId: contract.clientId, providerId: contract.providerId);
    } catch (e) {
      AppLogger.logError('Add provider rating failed for contractId: $contractId', e);
      if (e is AppException) rethrow;
      throw AppException(message: 'Add provider rating failed: $e', originalException: e);
    }
  }

  Future<void> completeContract(String contractId) async {
    try {
      final contract = await getContractById(contractId);
      if (contract == null) throw AppException(message: 'Contract not found');
      if (contract.status == AppConstants.contractStatusTerminated) {
        throw AppException(message: 'Terminated contracts cannot be completed');
      }
      if (contract.workSubmittedAt == null) {
        throw AppException(message: 'Work must be submitted before contract approval');
      }

      final row = await _databaseService.fetchData(
        table: 'contracts',
        select: 'arrival_due_at,arrived_at,response_due_at,first_provider_response_at',
        filters: {'id': contractId},
      );
      if (row.isNotEmpty) {
        final raw = row.first;
        final job = await _jobRepository.getJobById(contract.jobId);
        if (job != null && job.isImmediate) {
          final arrivedAt = raw['arrived_at'] == null
              ? null
              : DateTime.tryParse(raw['arrived_at'].toString())?.toUtc();
          if (arrivedAt == null) {
            await _applyReliabilityFault(providerId: contract.providerId, penalty: 0.7);
            throw AppException(
              message: 'Provider arrival not confirmed for immediate contract',
            );
          }
        } else {
          final responseDue = raw['response_due_at'] == null
              ? null
              : DateTime.tryParse(raw['response_due_at'].toString())?.toUtc();
          final firstResponse = raw['first_provider_response_at'] == null
              ? null
              : DateTime.tryParse(raw['first_provider_response_at'].toString())?.toUtc();
          if (responseDue != null && firstResponse == null) {
            await _applyReliabilityFault(providerId: contract.providerId, penalty: 0.5);
            throw AppException(message: 'Provider did not respond within required window');
          }
        }
      }

      await _databaseService.updateData(
        table: 'contracts',
        data: {
          'status': AppConstants.contractStatusCompleted,
          'completed_at': DateTime.now().toUtc().toIso8601String(),
          'end_date': DateTime.now().toUtc().toIso8601String(),
          'tracking_enabled': false,
        },
        id: contractId,
      );
      await _jobRepository.updateJob(jobId: contract.jobId, status: AppConstants.jobStatusCompleted);
      await _chatRepository.closeChatByContract(contractId);
      await _applyReliabilityReward(contract.providerId);
    } catch (e) {
      AppLogger.logError('Complete contract failed for contractId: $contractId', e);
      if (e is AppException) rethrow;
      throw AppException(message: 'Complete contract failed: $e', originalException: e);
    }
  }

  Future<void> submitWork(String contractId) async {
    try {
      await _databaseService.updateData(
        table: 'contracts',
        data: {
          'work_submitted_at': DateTime.now().toUtc().toIso8601String(),
        },
        id: contractId,
      );
    } catch (e) {
      AppLogger.logError('Submit work failed for contractId: $contractId', e);
      throw AppException(message: 'Submit work failed: $e', originalException: e);
    }
  }

  Future<void> approveSubmittedWork(String contractId) async {
    try {
      await completeContract(contractId);
    } catch (e) {
      AppLogger.logError('Approve submitted work failed for contractId: $contractId', e);
      if (e is AppException) rethrow;
      throw AppException(message: 'Approve submitted work failed: $e', originalException: e);
    }
  }

  Future<void> terminateContract({
    required String contractId,
    required String terminatedBy,
  }) async {
    try {
      final contract = await getContractById(contractId);
      if (contract == null) throw AppException(message: 'Contract not found');
      if (contract.status == AppConstants.contractStatusCompleted) {
        throw AppException(message: 'Completed contracts cannot be terminated');
      }
      if (contract.status == AppConstants.contractStatusTerminated) {
        throw AppException(message: 'Contract is already terminated');
      }
      if (contract.status != AppConstants.contractStatusActive) {
        throw AppException(message: 'Only active contracts can be terminated');
      }
      if (terminatedBy != AppConstants.contractTerminatedByClient &&
          terminatedBy != AppConstants.contractTerminatedByProvider) {
        throw AppException(message: 'Invalid terminated_by value');
      }

      await _databaseService.updateData(
        table: 'contracts',
        data: {
          'status': AppConstants.contractStatusTerminated,
          'terminated_by': terminatedBy,
          'end_date': DateTime.now().toUtc().toIso8601String(),
          'tracking_enabled': false,
        },
        id: contractId,
      );

      await _jobRepository.updateJob(jobId: contract.jobId, status: AppConstants.jobStatusCancelled);
      await _chatRepository.closeChatByContract(contractId);
    } catch (e) {
      AppLogger.logError('Terminate contract failed for contractId: $contractId', e);
      if (e is AppException) rethrow;
      throw AppException(message: 'Terminate contract failed: $e', originalException: e);
    }
  }

  Future<void> cancelContract(String contractId) async {
    await terminateContract(
      contractId: contractId,
      terminatedBy: AppConstants.contractTerminatedByClient,
    );
  }

  Future<void> deleteContract(String contractId) async {
    try {
      await _databaseService.softDeleteData(table: 'contracts', id: contractId);
    } catch (e) {
      AppLogger.logError('Delete contract failed for contractId: $contractId', e);
      throw AppException(message: 'Delete contract failed: $e', originalException: e);
    }
  }

  Future<ContractModel?> getContractByJobId(String jobId) async {
    try {
      final result = await _databaseService.fetchData(
        table: 'contracts',
        filters: {
          'job_id': jobId,
          'is_deleted': false,
        },
        orderBy: 'created_at',
        descending: true,
        limit: 1,
      );
      if (result.isEmpty) return null;
      return ContractModel.fromJson(_mapContractRow(result.first));
    } catch (e) {
      AppLogger.logError('Get contract by job failed for jobId: $jobId', e);
      throw AppException(message: 'Get contract by job failed: $e', originalException: e);
    }
  }

  Future<double?> getProviderAverageRating(String providerId) async {
    try {
      final contracts = await getProviderContracts(providerId, limit: 200, offset: 0);
      final ratings = contracts
          .where((contract) => contract.providerRating != null)
          .map((contract) => contract.providerRating!.toDouble())
          .toList();
      if (ratings.isEmpty) return null;
      return ratings.reduce((a, b) => a + b) / ratings.length;
    } catch (e) {
      AppLogger.logError('Get provider average rating failed for providerId: $providerId', e);
      return null;
    }
  }

  Future<double?> getClientAverageRating(String clientId) async {
    try {
      final contracts = await getClientContracts(clientId, limit: 200, offset: 0);
      final ratings = contracts
          .where((contract) => contract.clientRating != null)
          .map((contract) => contract.clientRating!.toDouble())
          .toList();
      if (ratings.isEmpty) return null;
      return ratings.reduce((a, b) => a + b) / ratings.length;
    } catch (e) {
      AppLogger.logError('Get client average rating failed for clientId: $clientId', e);
      return null;
    }
  }
}
