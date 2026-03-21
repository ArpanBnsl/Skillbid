import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_constants.dart';
import '../models/contract_model.dart';
import '../repositories/contract_repository.dart';
import '../services/route_service.dart';
import '../services/tracking_service.dart';
import 'auth_provider.dart';
import 'bid_provider.dart';
import 'job_provider.dart';

final contractRepositoryProvider = Provider((ref) => ContractRepository());
final trackingServiceProvider = Provider((ref) => TrackingService());
final routeServiceProvider = Provider((ref) => RouteService());

/// Get client's contracts
final clientContractsProvider = FutureProvider<List<ContractModel>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  
  final repo = ref.watch(contractRepositoryProvider);
  return repo.getClientContracts(userId);
});

final clientActiveContractsProvider = FutureProvider<List<ContractModel>>((ref) async {
  final contracts = await ref.watch(clientContractsProvider.future);
  return contracts.where((c) => c.status == AppConstants.contractStatusActive).toList();
});

final clientPastContractsProvider = FutureProvider<List<ContractModel>>((ref) async {
  final contracts = await ref.watch(clientContractsProvider.future);
  return contracts
      .where(
        (c) => c.status == AppConstants.contractStatusCompleted || c.status == AppConstants.contractStatusTerminated,
      )
      .toList();
});

/// Get provider's contracts
final providerContractsProvider = FutureProvider<List<ContractModel>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  
  final repo = ref.watch(contractRepositoryProvider);
  return repo.getProviderContracts(userId);
});

final providerContractsByUserProvider = FutureProvider.family<List<ContractModel>, String>((ref, providerId) async {
  final repo = ref.watch(contractRepositoryProvider);
  return repo.getProviderContracts(providerId);
});

final providerActiveContractsProvider = FutureProvider<List<ContractModel>>((ref) async {
  final contracts = await ref.watch(providerContractsProvider.future);
  return contracts.where((c) => c.status == AppConstants.contractStatusActive).toList();
});

final providerPastContractsProvider = FutureProvider<List<ContractModel>>((ref) async {
  final contracts = await ref.watch(providerContractsProvider.future);
  return contracts
      .where(
        (c) => c.status == AppConstants.contractStatusCompleted || c.status == AppConstants.contractStatusTerminated,
      )
      .toList();
});

/// Get specific contract
final contractProvider = FutureProvider.family<ContractModel?, String>((ref, contractId) async {
  final repo = ref.watch(contractRepositoryProvider);
  return repo.getContractById(contractId);
});

/// Get contract by job ID
final contractByJobProvider = FutureProvider.family<ContractModel?, String>((ref, jobId) async {
  final repo = ref.watch(contractRepositoryProvider);
  return repo.getContractByJobId(jobId);
});

/// Accept bid and create contract
final acceptBidAndCreateContractProvider = FutureProvider.family<ContractModel, ({String bidId, String jobId, String clientId})>((ref, params) async {
  final contractRepo = ref.watch(contractRepositoryProvider);
  final contract = await contractRepo.acceptBidAndCreateContract(
    bidId: params.bidId,
    jobId: params.jobId,
    clientId: params.clientId,
  );
  
  // Refresh all contract lists
  ref.invalidate(clientContractsProvider);
  ref.invalidate(clientActiveContractsProvider);
  ref.invalidate(clientPastContractsProvider);
  ref.invalidate(providerContractsProvider);
  ref.invalidate(providerActiveContractsProvider);
  ref.invalidate(providerPastContractsProvider);
  ref.invalidate(jobProvider(params.jobId));
  ref.invalidate(jobBidsProvider(params.jobId));
  
  return contract;
});

/// Update contract status
final updateContractStatusProvider = FutureProvider.family<void, ({String contractId, String status})>((ref, params) async {
  final repo = ref.watch(contractRepositoryProvider);
  await repo.updateContractStatus(contractId: params.contractId, status: params.status);
  
  // Refresh contracts
  ref.invalidate(contractProvider(params.contractId));
  ref.invalidate(clientContractsProvider);
  ref.invalidate(clientActiveContractsProvider);
  ref.invalidate(clientPastContractsProvider);
  ref.invalidate(providerContractsProvider);
  ref.invalidate(providerActiveContractsProvider);
  ref.invalidate(providerPastContractsProvider);
});

/// Complete contract
final completeContractProvider = FutureProvider.family<void, String>((ref, contractId) async {
  final repo = ref.watch(contractRepositoryProvider);
  final contract = await repo.getContractById(contractId);
  if (contract == null) throw Exception('Contract not found');
  await repo.completeContract(contractId);
  
  // Refresh contracts
  ref.invalidate(contractProvider(contractId));
  ref.invalidate(clientContractsProvider);
  ref.invalidate(clientActiveContractsProvider);
  ref.invalidate(clientPastContractsProvider);
  ref.invalidate(providerContractsProvider);
  ref.invalidate(providerActiveContractsProvider);
  ref.invalidate(providerPastContractsProvider);
  ref.invalidate(contractByJobProvider(contract.jobId));
  ref.invalidate(jobProvider(contract.jobId));
});

final submitWorkProvider = FutureProvider.family<void, String>((ref, contractId) async {
  final repo = ref.watch(contractRepositoryProvider);
  final contract = await repo.getContractById(contractId);
  if (contract == null) throw Exception('Contract not found');

  await repo.submitWork(contractId);

  ref.invalidate(contractProvider(contractId));
  ref.invalidate(clientContractsProvider);
  ref.invalidate(clientActiveContractsProvider);
  ref.invalidate(clientPastContractsProvider);
  ref.invalidate(providerContractsProvider);
  ref.invalidate(providerActiveContractsProvider);
  ref.invalidate(providerPastContractsProvider);
  ref.invalidate(contractByJobProvider(contract.jobId));
  ref.invalidate(jobProvider(contract.jobId));
});

final approveSubmittedWorkProvider = FutureProvider.family<void, String>((ref, contractId) async {
  final repo = ref.watch(contractRepositoryProvider);
  final contract = await repo.getContractById(contractId);
  if (contract == null) throw Exception('Contract not found');

  await repo.approveSubmittedWork(contractId);

  ref.invalidate(contractProvider(contractId));
  ref.invalidate(clientContractsProvider);
  ref.invalidate(clientActiveContractsProvider);
  ref.invalidate(clientPastContractsProvider);
  ref.invalidate(providerContractsProvider);
  ref.invalidate(providerActiveContractsProvider);
  ref.invalidate(providerPastContractsProvider);
  ref.invalidate(contractByJobProvider(contract.jobId));
  ref.invalidate(jobProvider(contract.jobId));
});

final terminateContractProvider = FutureProvider.family<void, ({String contractId, String terminatedBy})>((ref, params) async {
  final repo = ref.watch(contractRepositoryProvider);
  final contract = await repo.getContractById(params.contractId);
  if (contract == null) throw Exception('Contract not found');

  await repo.terminateContract(
    contractId: params.contractId,
    terminatedBy: params.terminatedBy,
  );

  ref.invalidate(contractProvider(params.contractId));
  ref.invalidate(clientContractsProvider);
  ref.invalidate(clientActiveContractsProvider);
  ref.invalidate(clientPastContractsProvider);
  ref.invalidate(providerContractsProvider);
  ref.invalidate(providerActiveContractsProvider);
  ref.invalidate(providerPastContractsProvider);
  ref.invalidate(contractByJobProvider(contract.jobId));
  ref.invalidate(jobProvider(contract.jobId));
});

/// Add review to contract
final addReviewProvider = FutureProvider.family<void, ({String contractId, int rating, String reviewText})>((ref, params) async {
  final repo = ref.watch(contractRepositoryProvider);
  final contract = await repo.getContractById(params.contractId);
  if (contract == null) throw Exception('Contract not found');
  await repo.addClientReview(contractId: params.contractId, providerRating: params.rating, reviewText: params.reviewText);
  
  // Refresh contract
  ref.invalidate(contractProvider(params.contractId));
  ref.invalidate(clientContractsProvider);
  ref.invalidate(clientPastContractsProvider);
  ref.invalidate(providerContractsProvider);
  ref.invalidate(providerPastContractsProvider);
  ref.invalidate(providerAverageRatingProvider(contract.providerId));
});

final addProviderRatingProvider = FutureProvider.family<void, ({String contractId, int rating})>((ref, params) async {
  final repo = ref.watch(contractRepositoryProvider);
  final contract = await repo.getContractById(params.contractId);
  if (contract == null) throw Exception('Contract not found');

  await repo.addProviderRating(
    contractId: params.contractId,
    clientRating: params.rating,
  );

  ref.invalidate(contractProvider(params.contractId));
  ref.invalidate(clientContractsProvider);
  ref.invalidate(clientPastContractsProvider);
  ref.invalidate(providerContractsProvider);
  ref.invalidate(providerPastContractsProvider);
  ref.invalidate(clientAverageRatingProvider(contract.clientId));
});

final providerAverageRatingProvider = FutureProvider.family<double?, String>((ref, providerId) async {
  final repo = ref.watch(contractRepositoryProvider);
  return repo.getProviderAverageRating(providerId);
});

final clientAverageRatingProvider = FutureProvider.family<double?, String>((ref, clientId) async {
  final repo = ref.watch(contractRepositoryProvider);
  return repo.getClientAverageRating(clientId);
});

/// Fetch route data (polyline + distance + ETA) for a tracked contract
final routeDataProvider = FutureProvider.family<RouteData?, ({double providerLat, double providerLng, double clientLat, double clientLng})>((ref, params) async {
  final routeService = ref.watch(routeServiceProvider);
  return routeService.getRoute(
    providerLat: params.providerLat,
    providerLng: params.providerLng,
    clientLat: params.clientLat,
    clientLng: params.clientLng,
  );
});
