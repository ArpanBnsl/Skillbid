import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/portfolio/portfolio_image_model.dart';
import '../models/portfolio/portfolio_model.dart';
import '../repositories/portfolio_repository.dart';
import 'auth_provider.dart';

final portfolioRepositoryProvider = Provider((ref) => PortfolioRepository());

/// Get a provider's portfolio by provider ID
final providerPortfolioByUserProvider = FutureProvider.family<List<PortfolioModel>, String>((ref, providerId) async {
  final repo = ref.watch(portfolioRepositoryProvider);
  return repo.getProviderPortfolio(providerId);
});

/// Get provider's portfolio
final providerPortfolioProvider = FutureProvider<List<PortfolioModel>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  
  final repo = ref.watch(portfolioRepositoryProvider);
  return repo.getProviderPortfolio(userId);
});

/// Get specific portfolio item
final portfolioItemProvider = FutureProvider.family<PortfolioModel?, String>((ref, portfolioId) async {
  final repo = ref.watch(portfolioRepositoryProvider);
  return repo.getPortfolioById(portfolioId);
});

/// Get portfolio images
final portfolioImagesProvider = FutureProvider.family<List<PortfolioImageModel>, String>((ref, portfolioId) async {
  final repo = ref.watch(portfolioRepositoryProvider);
  return repo.getPortfolioImages(portfolioId);
});

/// Create portfolio item
final createPortfolioProvider = FutureProvider.family<PortfolioModel, ({String title, String? description, double? cost})>((ref, params) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) throw Exception('User not authenticated');
  
  final repo = ref.watch(portfolioRepositoryProvider);
  final portfolio = await repo.createPortfolioItem(
    providerId: userId,
    title: params.title,
    description: params.description,
    cost: params.cost,
  );
  
  // Refresh portfolio list
  ref.invalidate(providerPortfolioProvider);
  
  return portfolio;
});

/// Update portfolio item
final updatePortfolioProvider = FutureProvider.family<void, ({String portfolioId, String? title, String? description, double? cost})>((ref, params) async {
  final repo = ref.watch(portfolioRepositoryProvider);
  await repo.updatePortfolioItem(
    portfolioId: params.portfolioId,
    title: params.title,
    description: params.description,
    cost: params.cost,
  );
  
  // Refresh portfolio
  ref.invalidate(portfolioItemProvider(params.portfolioId));
  ref.invalidate(providerPortfolioProvider);
});

/// Delete portfolio item
final deletePortfolioProvider = FutureProvider.family<void, String>((ref, portfolioId) async {
  final repo = ref.watch(portfolioRepositoryProvider);
  await repo.deletePortfolioItem(portfolioId);
  
  // Refresh portfolio list
  ref.invalidate(providerPortfolioProvider);
});
