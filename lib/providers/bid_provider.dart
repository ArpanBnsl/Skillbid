import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_constants.dart';
import '../models/bid_model.dart';
import '../repositories/bid_repository.dart';
import 'auth_provider.dart';
import 'job_provider.dart';
import 'notification_provider.dart';

final bidRepositoryProvider = Provider((ref) => BidRepository());

/// Holds the provider's own bids in memory so new bids can be injected
/// directly from Realtime payloads — no DB round-trip needed.
class ProviderBidsNotifier extends AsyncNotifier<List<BidModel>> {
  @override
  Future<List<BidModel>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return [];
    final repo = ref.watch(bidRepositoryProvider);
    return repo.getProviderBids(userId);
  }

  void prependBid(BidModel bid) {
    final current = state.valueOrNull;
    if (current == null) return;
    if (current.any((b) => b.id == bid.id)) return;
    state = AsyncData([bid, ...current]);
  }

  void updateBidStatus(String bidId, String status) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.map((b) => b.id == bidId ? b.copyWith(status: status) : b).toList(),
    );
  }
}

final providerBidsProvider =
    AsyncNotifierProvider<ProviderBidsNotifier, List<BidModel>>(
  ProviderBidsNotifier.new,
);

/// Holds bids for a specific job in memory so new bids from providers appear
/// instantly on the client's screen — no DB round-trip needed.
class JobBidsNotifier extends FamilyAsyncNotifier<List<BidModel>, String> {
  @override
  Future<List<BidModel>> build(String jobId) async {
    final repo = ref.watch(bidRepositoryProvider);
    return repo.getJobBids(jobId);
  }

  void prependBid(BidModel bid) {
    final current = state.valueOrNull;
    if (current == null) return;
    if (current.any((b) => b.id == bid.id)) return;
    state = AsyncData([bid, ...current]);
  }

  void updateBidStatus(String bidId, String status) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.map((b) => b.id == bidId ? b.copyWith(status: status) : b).toList(),
    );
  }
}

final jobBidsProvider =
    AsyncNotifierProvider.family<JobBidsNotifier, List<BidModel>, String>(
  JobBidsNotifier.new,
);

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

  // Inject into providerBidsProvider directly (always alive in IndexedStack).
  // For jobBidsProvider, only inject if currently alive (client viewing that job);
  // otherwise invalidate so it re-fetches fresh when they navigate there.
  ref.read(providerBidsProvider.notifier).prependBid(bid);
  if (ref.exists(jobBidsProvider(params.jobId))) {
    ref.read(jobBidsProvider(params.jobId).notifier).prependBid(bid);
  } else {
    ref.invalidate(jobBidsProvider(params.jobId));
  }

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
  ref.read(providerBidsProvider.notifier).updateBidStatus(bidId, 'accepted');
  ref.invalidate(bidProvider(bidId));
});

/// Reject bid
final rejectBidProvider = FutureProvider.family<void, String>((ref, bidId) async {
  final repo = ref.watch(bidRepositoryProvider);
  await repo.updateBidStatus(bidId: bidId, status: 'rejected');
  ref.read(providerBidsProvider.notifier).updateBidStatus(bidId, 'rejected');
  ref.invalidate(bidProvider(bidId));
});

/// Withdraw bid
final withdrawBidProvider = FutureProvider.family<void, String>((ref, bidId) async {
  final repo = ref.watch(bidRepositoryProvider);
  await repo.withdrawBid(bidId);
  ref.read(providerBidsProvider.notifier).updateBidStatus(bidId, 'withdrawn');
  ref.invalidate(bidProvider(bidId));
});

/// Check if provider already bid
final hasProviderBidProvider = FutureProvider.family<bool, ({String jobId, String providerId})>((ref, params) async {
  final repo = ref.watch(bidRepositoryProvider);
  return repo.hasProviderBidOnJob(jobId: params.jobId, providerId: params.providerId);
});
