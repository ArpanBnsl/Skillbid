import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_constants.dart';
import '../models/contract_model.dart';
import '../repositories/contract_repository.dart';
import 'auth_provider.dart';
import 'bid_provider.dart';
import 'chat_provider.dart';
import 'job_provider.dart';
import 'notification_provider.dart';

final contractRepositoryProvider = Provider((ref) => ContractRepository());

/// Get client's contracts
final clientContractsProvider = FutureProvider<List<ContractModel>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final repo = ref.watch(contractRepositoryProvider);
  return repo.getClientContracts(userId);
});

/// Get provider's contracts
final providerContractsProvider = FutureProvider<List<ContractModel>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final repo = ref.watch(contractRepositoryProvider);
  return repo.getProviderContracts(userId);
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

/// Accept bid and create contract — notifies both client and worker.
final acceptBidAndCreateContractProvider = FutureProvider.family<ContractModel, ({String bidId, String jobId, String clientId})>((ref, params) async {
  final contractRepo = ref.watch(contractRepositoryProvider);
  final contract = await contractRepo.acceptBidAndCreateContract(
    bidId: params.bidId,
    jobId: params.jobId,
    clientId: params.clientId,
  );

  // Refresh all contract lists
  ref.invalidate(clientContractsProvider);
  ref.invalidate(providerContractsProvider);
  ref.invalidate(jobProvider(params.jobId));
  ref.invalidate(jobBidsProvider(params.jobId));

  // ── Notifications ──
  try {
    final notifRepo = ref.read(notificationRepositoryProvider);
    final job = await ref.read(jobRepositoryProvider).getJobById(params.jobId);
    final jobTitle = job?.title ?? 'project';

    // Find the chat for navigation
    final chatRepo = ref.read(chatRepositoryProvider);
    final chat = await chatRepo.getChatByContractId(contract.id);
    final chatId = chat?.id;

    // 1) Client confirmation → redirects to chat on tap
    await notifRepo.createNotification(
      userId: params.clientId,
      type: AppConstants.notifBidApproved,
      title: 'Bid Approved',
      body: 'You approved a bid on "$jobTitle". Start chatting!',
      data: {
        'chat_id': chatId,
        'role': 'client',
      },
    );

    // 2) Worker notification → proposal accepted, redirects to chat
    await notifRepo.createNotification(
      userId: contract.providerId,
      type: AppConstants.notifProposalAccepted,
      title: 'Proposal Accepted!',
      body: 'Your bid on "$jobTitle" was accepted!',
      data: {
        'chat_id': chatId,
        'job_id': params.jobId,
        'role': 'provider',
      },
    );
  } catch (_) {}

  return contract;
});

/// Update contract status
final updateContractStatusProvider = FutureProvider.family<void, ({String contractId, String status})>((ref, params) async {
  final repo = ref.watch(contractRepositoryProvider);
  await repo.updateContractStatus(contractId: params.contractId, status: params.status);

  // Refresh contracts
  ref.invalidate(contractProvider(params.contractId));
  ref.invalidate(clientContractsProvider);
  ref.invalidate(providerContractsProvider);
});

/// Complete contract
final completeContractProvider = FutureProvider.family<void, String>((ref, contractId) async {
  final repo = ref.watch(contractRepositoryProvider);
  await repo.completeContract(contractId);

  // Refresh contracts
  ref.invalidate(contractProvider(contractId));
  ref.invalidate(clientContractsProvider);
  ref.invalidate(providerContractsProvider);
});

/// Worker submits work — notifies the client.
final submitWorkProvider = FutureProvider.family<void, String>((ref, contractId) async {
  final repo = ref.watch(contractRepositoryProvider);
  final contract = await repo.getContractById(contractId);
  if (contract == null) throw Exception('Contract not found');

  await repo.submitWork(contractId);

  ref.invalidate(contractProvider(contractId));
  ref.invalidate(clientContractsProvider);
  ref.invalidate(providerContractsProvider);
  ref.invalidate(contractByJobProvider(contract.jobId));
  ref.invalidate(jobProvider(contract.jobId));

  // ── Notification: tell the client work was submitted ──
  try {
    final notifRepo = ref.read(notificationRepositoryProvider);
    final job = await ref.read(jobRepositoryProvider).getJobById(contract.jobId);
    await notifRepo.createNotification(
      userId: contract.clientId,
      type: AppConstants.notifStatusChange,
      title: 'Work Submitted',
      body: 'Work has been submitted for "${job?.title ?? 'your project'}"',
      data: {
        'contract_id': contractId,
        'job_id': contract.jobId,
        'role': 'client',
      },
    );
  } catch (_) {}
});

/// Client approves submitted work — notifies both parties.
final approveSubmittedWorkProvider = FutureProvider.family<void, String>((ref, contractId) async {
  final repo = ref.watch(contractRepositoryProvider);
  final contract = await repo.getContractById(contractId);
  if (contract == null) throw Exception('Contract not found');

  await repo.approveSubmittedWork(contractId);

  ref.invalidate(contractProvider(contractId));
  ref.invalidate(clientContractsProvider);
  ref.invalidate(providerContractsProvider);
  ref.invalidate(contractByJobProvider(contract.jobId));
  ref.invalidate(jobProvider(contract.jobId));

  // ── Notifications: project completed ──
  try {
    final notifRepo = ref.read(notificationRepositoryProvider);
    final job = await ref.read(jobRepositoryProvider).getJobById(contract.jobId);
    final jobTitle = job?.title ?? 'The project';

    await notifRepo.createNotification(
      userId: contract.clientId,
      type: AppConstants.notifProjectCompleted,
      title: 'Project Completed',
      body: '"$jobTitle" has been completed!',
      data: {
        'contract_id': contractId,
        'job_id': contract.jobId,
        'role': 'client',
      },
    );

    await notifRepo.createNotification(
      userId: contract.providerId,
      type: AppConstants.notifProjectCompleted,
      title: 'Project Completed',
      body: '"$jobTitle" has been marked complete!',
      data: {
        'contract_id': contractId,
        'job_id': contract.jobId,
        'role': 'provider',
      },
    );
  } catch (_) {}
});

/// Add review to contract
final addReviewProvider = FutureProvider.family<void, ({String contractId, int rating, String reviewText})>((ref, params) async {
  final repo = ref.watch(contractRepositoryProvider);
  await repo.addReview(
    contractId: params.contractId,
    rating: params.rating,
    reviewText: params.reviewText,
  );

  // Refresh contract
  ref.invalidate(contractProvider(params.contractId));
  ref.invalidate(clientContractsProvider);
});

final providerAverageRatingProvider = FutureProvider.family<double?, String>((ref, providerId) async {
  final repo = ref.watch(contractRepositoryProvider);
  return repo.getProviderAverageRating(providerId);
});
