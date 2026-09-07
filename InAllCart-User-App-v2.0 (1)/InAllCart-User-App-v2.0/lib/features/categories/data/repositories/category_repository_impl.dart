import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/data_sync_service.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_local_datasource.dart';import '../datasources/category_remote_datasource.dart';

/// Production-grade category repository
/// 
/// Architecture:
/// - Stale-while-revalidate pattern
/// - Reactive updates via DataSyncService streams
/// - ETag-based cache validation
/// - Automatic background refresh
/// - Proper error handling with retry logic
class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource _remoteDataSource;
  final CategoryLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;
  final DataSyncService _dataSyncService;

  CategoryRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._networkInfo,
  ) : _dataSyncService = DataSyncService();

  // ============== ALL CATEGORIES ==============

  @override
  Future<Either<Failure, List<Category>>> getCategories({bool forceRefresh = false}) async {
    final isConnected = await _networkInfo.isConnected;

    if (!isConnected) {
      return _getCachedCategories();
    }

    if (forceRefresh) {
      await _localDataSource.setCachedVersion('');
      return _fetchAndCacheCategories();
    }

    final cachedCategories = await _localDataSource.getCachedCategories();
    
    if (cachedCategories.isNotEmpty) {
      // Return cached immediately, refresh in background
      _backgroundRefreshCategories();
      return Right(cachedCategories);
    }

    return _fetchAndCacheCategories();
  }

  Future<Either<Failure, List<Category>>> _fetchAndCacheCategories() async {
    try {
      final currentETag = await _localDataSource.getCachedVersion();
      final response = await _remoteDataSource.getCategoriesWithETag(
        currentETag: currentETag,
      );
      
      if (response.notModified) {
        final cached = await _localDataSource.getCachedCategories();
        return Right(cached);
      }
      
      await _localDataSource.cacheCategories(response.categories);
      if (response.etag != null) {
        await _localDataSource.setCachedVersion(response.etag!);
      }
      
      // Update stream
      _dataSyncService.updateCategories(
        data: response.categories,
        etag: response.etag,
      );
      
      return Right(response.categories);
    } on NetworkException {
      return _getCachedCategories();
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure('Failed to load categories: $e'));
    }
  }

  Future<Either<Failure, List<Category>>> _getCachedCategories() async {
    try {
      final categories = await _localDataSource.getCachedCategories();
      if (categories.isEmpty) {
        return const Left(NetworkFailure('No internet connection and no cached data'));
      }
      return Right(categories);
    } catch (e) {
      return Left(CacheFailure('Failed to load cached categories: $e'));
    }
  }

  Future<void> _backgroundRefreshCategories() async {
    if (!_dataSyncService.shouldRefreshFeaturedCategories()) return;
    
    _dataSyncService.markFeaturedCategoriesRefreshStarted();
    
    try {
      final currentETag = await _localDataSource.getCachedVersion();
      final response = await _remoteDataSource.getCategoriesWithETag(
        currentETag: currentETag,
      );
      
      if (!response.notModified) {
        await _localDataSource.cacheCategories(response.categories);
        if (response.etag != null) {
          await _localDataSource.setCachedVersion(response.etag!);
        }
        _dataSyncService.updateCategories(
          data: response.categories,
          etag: response.etag,
        );
      }
      
      _dataSyncService.markFeaturedCategoriesRefreshCompleted(success: true);
    } catch (e) {
      _dataSyncService.markFeaturedCategoriesRefreshCompleted(success: false);
    }
  }

  // ============== FEATURED CATEGORIES ==============

  @override
  Future<Either<Failure, List<Category>>> getFeaturedCategories({
    int limit = 8, 
    bool forceRefresh = false,
  }) async {
    final isConnected = await _networkInfo.isConnected;

    _dataSyncService.setFeaturedCategoriesLoading(true);

    if (!isConnected) {
      final result = await _getCachedFeaturedCategories();
      _dataSyncService.setFeaturedCategoriesLoading(false);
      return result;
    }

    if (forceRefresh) {
      await _localDataSource.setFeaturedCachedVersion('');
      _dataSyncService.resetRetryCount('featured_categories');
      final result = await _fetchFeaturedCategoriesFromServer(limit);
      _dataSyncService.setFeaturedCategoriesLoading(false);
      return result;
    }

    final cachedCategories = await _localDataSource.getCachedFeaturedCategories();
    
    if (cachedCategories.isNotEmpty) {
      _dataSyncService.updateFeaturedCategories(
        data: cachedCategories,
        isStale: true,
      );
      _backgroundRefreshFeaturedCategories(limit);
      _dataSyncService.setFeaturedCategoriesLoading(false);
      return Right(cachedCategories);
    }

    final result = await _fetchFeaturedCategoriesFromServer(limit);
    _dataSyncService.setFeaturedCategoriesLoading(false);
    return result;
  }

  /// Fetch featured categories from server and update cache + stream
  Future<Either<Failure, List<Category>>> _fetchFeaturedCategoriesFromServer(int limit) async {
    try {
      final currentETag = await _localDataSource.getFeaturedCachedVersion();
      
      final response = await _remoteDataSource.getFeaturedCategoriesWithETag(
        limit: limit,
        currentETag: currentETag,
      );
      
      if (response.notModified) {
        // Server says data hasn't changed - try to use cache
        final cached = await _localDataSource.getCachedFeaturedCategories();
        if (cached.isNotEmpty) {
          _dataSyncService.updateFeaturedCategories(
            data: cached,
            isStale: false,
          );
          return Right(cached);
        }
        // Cache is empty but server returned 304 - clear ETag and refetch
        await _localDataSource.setFeaturedCachedVersion('');
        return _fetchFeaturedCategoriesFromServer(limit);
      }
      
      // New data from server
      await _localDataSource.cacheFeaturedCategories(response.categories);
      if (response.etag != null) {
        await _localDataSource.setFeaturedCachedVersion(response.etag!);
      }
      
      _dataSyncService.updateFeaturedCategories(
        data: response.categories,
        isStale: false,
        etag: response.etag,
      );
      
      return Right(response.categories);
    } on NetworkException {
      return _getCachedFeaturedCategories();
    } on ServerException catch (e) {
      _dataSyncService.updateFeaturedCategories(
        error: ServerFailure(e.message, statusCode: e.statusCode),
      );
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      final failure = ServerFailure('Failed to load categories: $e');
      _dataSyncService.updateFeaturedCategories(error: failure);
      return Left(failure);
    }
  }

  Future<Either<Failure, List<Category>>> _getCachedFeaturedCategories() async {
    try {
      final categories = await _localDataSource.getCachedFeaturedCategories();
      if (categories.isEmpty) {
        final failure = const NetworkFailure('No internet connection and no cached data');
        _dataSyncService.updateFeaturedCategories(error: failure);
        return Left(failure);
      }
      _dataSyncService.updateFeaturedCategories(
        data: categories,
        isStale: true,
      );
      return Right(categories);
    } catch (e) {
      final failure = CacheFailure('Failed to load cached categories: $e');
      _dataSyncService.updateFeaturedCategories(error: failure);
      return Left(failure);
    }
  }

  /// Background refresh with proper error handling and retry logic
  Future<void> _backgroundRefreshFeaturedCategories(int limit) async {
    const refreshKey = 'featured_categories';
    
    if (!_dataSyncService.shouldRefreshFeaturedCategories()) {
      return;
    }
    
    _dataSyncService.markFeaturedCategoriesRefreshStarted();
    
    try {
      final currentETag = await _localDataSource.getFeaturedCachedVersion();
      
      final response = await _remoteDataSource.getFeaturedCategoriesWithETag(
        limit: limit,
        currentETag: currentETag,
      );
      
      if (response.notModified) {
        final current = _dataSyncService.featuredCategoriesState;
        if (current.hasData) {
          _dataSyncService.updateFeaturedCategories(
            data: current.data,
            isStale: false,
          );
        }
        _dataSyncService.markFeaturedCategoriesRefreshCompleted(success: true);
        return;
      }
      
      await _localDataSource.cacheFeaturedCategories(response.categories);
      if (response.etag != null) {
        await _localDataSource.setFeaturedCachedVersion(response.etag!);
      }
      
      _dataSyncService.updateFeaturedCategories(
        data: response.categories,
        isStale: false,
        etag: response.etag,
      );
      
      _dataSyncService.markFeaturedCategoriesRefreshCompleted(success: true);
      
    } catch (e) {
      _dataSyncService.markFeaturedCategoriesRefreshCompleted(success: false);
      
      if (_dataSyncService.shouldRetry(refreshKey)) {
        final delay = _dataSyncService.getRetryDelay(refreshKey);
        Future.delayed(delay, () => _backgroundRefreshFeaturedCategories(limit));
      }
    }
  }

  // ============== SINGLE CATEGORY ==============

  @override
  Future<Either<Failure, Category>> getCategoryById(int id) async {
    final isConnected = await _networkInfo.isConnected;

    if (!isConnected) {
      try {
        final cachedCategory = await _localDataSource.getCachedCategory(id);
        if (cachedCategory != null) {
          return Right<Failure, Category>(cachedCategory);
        }
        return const Left(NetworkFailure('No internet connection and category not cached'));
      } catch (e) {
        return Left(CacheFailure('Failed to load cached category: $e'));
      }
    }

    try {
      final category = await _remoteDataSource.getCategoryById(id);
      await _localDataSource.cacheCategory(category);
      return Right<Failure, Category>(category);
    } on NetworkException {
      try {
        final cachedCategory = await _localDataSource.getCachedCategory(id);
        if (cachedCategory != null) {
          return Right<Failure, Category>(cachedCategory);
        }
        return const Left(NetworkFailure('No internet connection'));
      } catch (e) {
        return const Left(NetworkFailure('No internet connection'));
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure('Failed to load category: $e'));
    }
  }
}
