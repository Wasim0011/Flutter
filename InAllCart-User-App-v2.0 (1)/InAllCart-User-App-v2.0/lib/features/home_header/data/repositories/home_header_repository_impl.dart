import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/data_sync_service.dart';
import '../../domain/entities/home_header_config.dart';
import '../../domain/repositories/home_header_repository.dart';
import '../datasources/home_header_local_datasource.dart';
import '../datasources/home_header_remote_datasource.dart';
import '../models/home_header_config_model.dart';

/// Production-grade home header repository
/// 
/// Architecture (same as products):
/// - Stale-while-revalidate pattern
/// - Reactive updates via DataSyncService streams
/// - ETag-based cache validation
/// - Automatic background refresh
/// - Proper error handling with retry logic
class HomeHeaderRepositoryImpl implements HomeHeaderRepository {
  final HomeHeaderRemoteDataSource _remoteDataSource;
  final HomeHeaderLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;
  final DataSyncService _dataSyncService;

  HomeHeaderRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._networkInfo,
  ) : _dataSyncService = DataSyncService();

  @override
  Future<Either<Failure, HomeHeaderConfig>> getHomeHeaderConfig({
    bool forceRefresh = false,
  }) async {
    final isConnected = await _networkInfo.isConnected;

    _dataSyncService.setHomeHeaderLoading(true);

    if (!isConnected) {
      final result = await _getCachedConfig();
      _dataSyncService.setHomeHeaderLoading(false);
      return result;
    }

    // Force refresh: clear all cache and fetch fresh
    if (forceRefresh) {
      await _localDataSource.clearCache();
      _dataSyncService.resetRetryCount('home_header');
      final result = await _fetchFromServer();
      _dataSyncService.setHomeHeaderLoading(false);
      return result;
    }

    // Stale-while-revalidate: return cache immediately, refresh in background
    final cachedConfig = await _localDataSource.getCachedConfig();
    
    if (cachedConfig != null) {
      _dataSyncService.updateHomeHeader(
        data: cachedConfig,
        isStale: true,
      );
      
      // Return cached immediately, refresh in background
      _backgroundRefresh();
      
      _dataSyncService.setHomeHeaderLoading(false);
      return Right(cachedConfig);
    }
    // No cache: fetch from server
    final result = await _fetchFromServer();
    _dataSyncService.setHomeHeaderLoading(false);
    return result;
  }

  /// Fetch from server with ETag support (same pattern as products)
  Future<Either<Failure, HomeHeaderConfig>> _fetchFromServer() async {
    try {
      final currentETag = await _localDataSource.getCachedVersion();
      
      final response = await _remoteDataSource.getHomeHeaderConfigWithETag(
        currentETag: currentETag,
      );
      
      if (response.notModified) {
        // Server says data hasn't changed - try to use cache
        final cached = await _localDataSource.getCachedConfig();
        if (cached != null) {
          _dataSyncService.updateHomeHeader(
            data: cached,
            isStale: false,
          );
          return Right(cached);
        }
        // Cache is empty but server returned 304 - clear ETag and refetch
        // This is the same pattern as products: clear version and retry
        await _localDataSource.setCachedVersion('');
        return _fetchFromServerWithoutETag();
      }
      
      // New data from server
      if (response.config != null) {
        if (response.config!.tabs.isNotEmpty) {
          // tabs available
        }
        
        await _localDataSource.cacheConfig(response.config!);
        if (response.etag != null) {
          await _localDataSource.setCachedVersion(response.etag!);
        }
        
        _dataSyncService.updateHomeHeader(
          data: response.config!,
          isStale: false,
          etag: response.etag,
        );
        
        return Right(response.config!);
      }
      
      // Fallback to default config
      return Right(HomeHeaderConfigModel.defaultConfig());
    } on NetworkException {
      return _getCachedConfig();
    } on ServerException catch (e) {
      _dataSyncService.updateHomeHeader(
        error: ServerFailure(e.message, statusCode: e.statusCode),
      );
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      final failure = ServerFailure('Failed to load home header config: $e');
      _dataSyncService.updateHomeHeader(error: failure);
      return Left(failure);
    }
  }

  /// Fetch without ETag (used when cache is empty but got 304)
  Future<Either<Failure, HomeHeaderConfig>> _fetchFromServerWithoutETag() async {
    try {
      
      final response = await _remoteDataSource.getHomeHeaderConfigWithETag(
        currentETag: null,
      );
      
      if (response.config != null) {
        await _localDataSource.cacheConfig(response.config!);
        if (response.etag != null) {
          await _localDataSource.setCachedVersion(response.etag!);
        }
        
        _dataSyncService.updateHomeHeader(
          data: response.config!,
          isStale: false,
          etag: response.etag,
        );
        
        return Right(response.config!);
      }
      
      return Right(HomeHeaderConfigModel.defaultConfig());
    } on NetworkException {
      return _getCachedConfig();
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure('Failed to load home header config: $e'));
    }
  }

  Future<Either<Failure, HomeHeaderConfig>> _getCachedConfig() async {
    try {
      final config = await _localDataSource.getCachedConfig();
      if (config == null) {
        // Return default config when offline and no cache
        final failure = const NetworkFailure('No internet connection and no cached data');
        _dataSyncService.updateHomeHeader(error: failure);
        return Right(HomeHeaderConfigModel.defaultConfig());
      }
      _dataSyncService.updateHomeHeader(
        data: config,
        isStale: true,
      );
      return Right(config);
    } catch (e) {
      return Right(HomeHeaderConfigModel.defaultConfig());
    }
  }

  /// Background refresh with proper error handling (same pattern as products)
  Future<void> _backgroundRefresh({bool overrideCache = true}) async {
    const refreshKey = 'home_header';
    
    // Check if should refresh using DataSyncService
    if (!overrideCache && !_dataSyncService.shouldRefreshHomeHeader()) {
      return;
    }
    
    _dataSyncService.markHomeHeaderRefreshStarted();
    
    try {
      final currentETag = await _localDataSource.getCachedVersion();
      
      final response = await _remoteDataSource.getHomeHeaderConfigWithETag(
        currentETag: currentETag,
      );
      
      if (response.notModified) {
        _dataSyncService.markHomeHeaderRefreshCompleted(success: true);
        return;
      }
      
      if (response.config != null) {
        if (response.config!.tabs.isNotEmpty) {
        }
        
        await _localDataSource.cacheConfig(response.config!);
        if (response.etag != null) {
          await _localDataSource.setCachedVersion(response.etag!);
        }
        
        _dataSyncService.updateHomeHeader(
          data: response.config!,
          isStale: false,
          etag: response.etag,
        );
        
        _dataSyncService.markHomeHeaderRefreshCompleted(success: true);
      }
    } catch (e) {
      // Silent fail - background refresh shouldn't affect UI
      _dataSyncService.markHomeHeaderRefreshCompleted(success: false);
      
      // Retry with exponential backoff
      if (_dataSyncService.shouldRetry(refreshKey)) {
        final delay = _dataSyncService.getRetryDelay(refreshKey);
        Future.delayed(delay, () => _backgroundRefresh());
      }
    }
  }
}
