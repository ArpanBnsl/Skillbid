import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_constants.dart';
import '../models/bid_model.dart';
import '../repositories/bid_repository.dart';
import 'auth_provider.dart';
import 'job_provider.dart';
import 'notification_provider.dart';

final bidRepositoryProvider = Provider((ref) => BidRepository());

/// Get provider's bids
final providerBidsProvider = FutureProvider<List<BidModel>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final repo = ref.watch(bidRepositoryProvider);
  return repo.getProviderBids(userId);
});

/// Get bids for a specific job
final jobBidsProvider = FutureProvider.family<List<BidModel>, String>((ref, jobId) async {
  final repo = ref.watch(bidRepositoryProvider);
  return repo.getJobBids(jobId);
});

/// Get specific bid
final bidProvider = FutureProvider.family<BidModel?, String>((ref, bidId) async {
  final repo = ref.watch(bidRepositoryProvider);
  return repo.getBidById(bidId);
});

/// Create bid — also notifies the job's client.
final createBidProvider = FutureProvider.family<BidModel, ({String jobId, double amount, int? estimatedDays, String? message})>((ref, params) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) throw Exception('User not authenticated');

  final repo = ref.watch(bidRepositoryProvider);
  final bid = await repo.createBid(
    jobId: params.jobId,
    providerId: userId,
    amount: params.amount,
    estimatedDays: params.estimatedDays,
    message: params.message,
  );

  // Refresh provider's bids
  ref.invalidate(providerBidsProvider);
  ref.invalidate(jobBidsProvider(params.jobId));

  // ── Notification: tell the client someone bid on their job ──
  try {
    final notifRepo = ref.read(notificationRepositoryProvider);
    final job = await ref.read(jobRepositoryProvider).getJobById(params.jobId);
    if (job != null) {
      await notifRepo.createNotification(
        userId: job.clientId,
        type: AppConstants.notifNewBid,
        title: 'New Bid Received',
        body: 'Someone bid \$${params.amount.toStringAsFixed(0)} on "${job.title}"',
        data: {'job_id': params.jobId, 'role': 'client'},
      );
    }
  } catch (_) {}

  return bid;
});

/// Accept bid (update status)
final acceptBidProvider = FutureProvider.family<void, String>((ref, bidId) async {
  final repo = ref.watch(bidRepositoryProvider);
  await repo.updateBidStatus(bidId: bidId, status: 'accepted');

  // Refresh bids
  ref.invalidate(providerBidsProvider);
  ref.invalidate(bidProvider(bidId));
});

/// Reject bid
final rejectBidProvider = FutureProvider.family<void, String>((ref, bidId) async {
  final repo = ref.watch(bidRepositoryProvider);
  await repo.updateBidStatus(bidId: bidId, status: 'rejected');

  // Refresh bids
  ref.invalidate(providerBidsProvider);
  ref.invalidate(bidProvider(bidId));
});

/// Withdraw bid
final withdrawBidProvider = FutureProvider.family<void, String>((ref, bidId) async {
  final repo = ref.watch(bidRepositoryProvider);
  await repo.withdrawBid(bidId);

  // Refresh bids
  ref.invalidate(providerBidsProvider);
  ref.invalidate(bidProvider(bidId));
});

/// Check if provider already bid
final hasProviderBidProvider = FutureProvider.family<bool, ({String jobId, String providerId})>((ref, params) async {
  final repo = ref.watch(bidRepositoryProvider);
  return repo.hasProviderBidOnJob(jobId: params.jobId, providerId: params.providerId);
});
