import '../models/portfolio/portfolio_model.dart';
import '../models/portfolio/portfolio_image_model.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../utils/exceptions.dart';
import '../utils/app_logger.dart';

class PortfolioRepository {
  final _databaseService = DatabaseService();
  final _storageService = StorageService();

  String? _extractStoragePathFromPublicUrl(String url, String bucket) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      final publicIndex = segments.indexOf('public');
      if (publicIndex == -1 || publicIndex + 2 > segments.length) return null;
      if (segments[publicIndex + 1] != bucket) return null;
      return segments.sublist(publicIndex + 2).join('/');
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _mapPortfolioRow(Map<String, dynamic> row) {
    dynamic asIso(dynamic value) {
      if (value is DateTime) return value.toIso8601String();
      return value;
    }

    return {
      'id': row['id'],
      'providerId': row['provider_id'],
      'title': row['title'],
      'description': row['description'],
      'cost': (row['cost'] as num?)?.toDouble(),
      'isDeleted': row['is_deleted'] ?? false,
      'createdAt': asIso(row['created_at']),
      'updatedAt': asIso(row['updated_at']),
    };
  }

  Map<String, dynamic> _mapPortfolioImageRow(Map<String, dynamic> row) {
    dynamic asIso(dynamic value) {
      if (value is DateTime) return value.toIso8601String();
      return value;
    }

    return {
      'id': row['id'],
      'portfolioId': row['portfolio_id'],
      'imageUrl': row['image_url'],
      'createdAt': asIso(row['created_at']),
    };
  }

  /// Create portfolio item
  Future<PortfolioModel> createPortfolioItem({
    required String providerId,
    required String title,
    String? description,
    double? cost,
  }) async {
    try {
      final result = await _databaseService.insertData(
        table: 'provider_portfolio',
        data: {
          'provider_id': providerId,
          'title': title,
          'description': description,
          'cost': cost,
        },
      );
      return PortfolioModel.fromJson(_mapPortfolioRow(result));
    } catch (e) {
      AppLogger.logError('Create portfolio item failed for providerId: $providerId', e);
      throw AppException(
        message: 'Create portfolio item failed: $e',
        originalException: e,
      );
    }
  }

  /// Get portfolio item by ID
  Future<PortfolioModel?> getPortfolioById(String portfolioId) async {
    try {
      final result = await _databaseService.fetchData(
        table: 'provider_portfolio',
        filters: {'id': portfolioId},
      );
      if (result.isEmpty) return null;
      return PortfolioModel.fromJson(_mapPortfolioRow(result.first));
    } catch (e) {
      AppLogger.logError('Get portfolio failed for portfolioId: $portfolioId', e);
      throw AppException(
        message: 'Get portfolio failed: $e',
        originalException: e,
      );
    }
  }

  /// Get provider's portfolio
  Future<List<PortfolioModel>> getProviderPortfolio(String providerId, {int limit = 20, int offset = 0}) async {
    try {
      final result = await _databaseService.fetchData(
        table: 'provider_portfolio',
        filters: {
          'provider_id': providerId,
          'is_deleted': false,
        },
        orderBy: 'created_at',
        descending: true,
        limit: limit,
        offset: offset,
      );
      return result.map((e) => PortfolioModel.fromJson(_mapPortfolioRow(e))).toList();
    } catch (e) {
      AppLogger.logError('Get provider portfolio failed for providerId: $providerId', e);
      throw AppException(
        message: 'Get provider portfolio failed: $e',
        originalException: e,
      );
    }
  }

  /// Update portfolio item
  Future<void> updatePortfolioItem({
    required String portfolioId,
    String? title,
    String? description,
    double? cost,
  }) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    data['description'] = description;
    data['cost'] = cost;

    await _databaseService.updateData(
      table: 'provider_portfolio',
      data: data,
      id: portfolioId,
    );
  }

  /// Add portfolio image
  Future<PortfolioImageModel> addPortfolioImage({
    required String portfolioId,
    required dynamic imageFile,
  }) async {
    try {
      final imageUrl = await _storageService.uploadImage(
        image: imageFile,
        bucket: 'portfolio-images',
        path: portfolioId,
      );

      final result = await _databaseService.insertData(
        table: 'portfolio_images',
        data: {
          'portfolio_id': portfolioId,
          'image_url': imageUrl,
        },
      );
      return PortfolioImageModel.fromJson(_mapPortfolioImageRow(result));
    } catch (e) {
      AppLogger.logError('Add portfolio image failed for portfolioId: $portfolioId', e);
      throw AppException(
        message: 'Add portfolio image failed: $e',
        originalException: e,
      );
    }
  }

  /// Get portfolio images
  Future<List<PortfolioImageModel>> getPortfolioImages(String portfolioId) async {
    try {
      final result = await _databaseService.fetchData(
        table: 'portfolio_images',
        filters: {'portfolio_id': portfolioId},
      );
      return result.map((e) => PortfolioImageModel.fromJson(_mapPortfolioImageRow(e))).toList();
    } catch (e) {
      AppLogger.logError('Get portfolio images failed for portfolioId: $portfolioId', e);
      throw AppException(
        message: 'Get portfolio images failed: $e',
        originalException: e,
      );
    }
  }

  /// Delete a single portfolio image
  Future<void> deletePortfolioImage({
    required String imageId,
    required String imageUrl,
  }) async {
    try {
      final storagePath = _extractStoragePathFromPublicUrl(imageUrl, 'portfolio-images');
      if (storagePath != null && storagePath.isNotEmpty) {
        await _storageService.deleteImage(
          bucket: 'portfolio-images',
          path: storagePath,
        );
      }

      await _databaseService.deleteData(
        table: 'portfolio_images',
        id: imageId,
      );
    } catch (e) {
      AppLogger.logError('Delete portfolio image failed for imageId: $imageId', e);
      throw AppException(
        message: 'Delete portfolio image failed: $e',
        originalException: e,
      );
    }
  }

  /// Delete portfolio item (soft delete)
  Future<void> deletePortfolioItem(String portfolioId) async {
    try {
      await _databaseService.softDeleteData(
        table: 'provider_portfolio',
        id: portfolioId,
      );
    } catch (e) {
      AppLogger.logError('Delete portfolio item failed for portfolioId: $portfolioId', e);
      throw AppException(
        message: 'Delete portfolio item failed: $e',
        originalException: e,
      );
    }
  }
}
