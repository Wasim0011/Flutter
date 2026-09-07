import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/data_sync_service.dart';
import '../../domain/entities/app_content.dart';
import '../../domain/repositories/app_content_repository.dart';
import '../datasources/app_content_local_datasource.dart';
import '../datasources/app_content_remote_datasource.dart';

class AppContentRepositoryImpl implements AppContentRepository {
  final AppContentRemoteDataSource remoteDataSource;
  final AppContentLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final DataSyncService _dataSyncService;

  AppContentRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  }) : _dataSyncService = DataSyncService();

  @override
  Future<Either<Failure, List<AppContent>>> getAppContent({
    int? tabId,
    bool forceRefresh = false,
  }) async {
    
    // Check if we should skip refresh
    if (!forceRefresh && !_dataSyncService.shouldRefreshAppContent(tabId)) {
      final currentState = _dataSyncService.appContentState(tabId);
      if (currentState.hasData) {
        return Right(currentState.data!);
      }
    }

    // Try cache first if not forcing refresh
    if (!forceRefresh) {
      final cached = await localDataSource.getCachedContent(tabId);
      if (cached != null && cached.isNotEmpty) {
        // Update DataSyncService with cached data (marked as potentially stale)
        _dataSyncService.updateAppContent(tabId: tabId, data: cached, isStale: true);
        // Return cache immediately, then try to refresh in background
        _refreshInBackground(tabId);
        return Right(cached);
      }
    }

    // Check network
    if (!await networkInfo.isConnected) {
      final cached = await localDataSource.getCachedContent(tabId);
      if (cached != null) {
        _dataSyncService.updateAppContent(tabId: tabId, data: cached, isStale: true);
        return Right(cached);
      }
      return const Left(NetworkFailure('No internet connection'));
    }

    // Mark refresh started
    _dataSyncService.markAppContentRefreshStarted(tabId);
    _dataSyncService.setAppContentLoading(tabId, true);

    try {
      final currentETag = forceRefresh ? null : await localDataSource.getCachedVersion(tabId);
      
      final response = await remoteDataSource.getAppContent(
        tabId: tabId,
        currentETag: currentETag,
      );

      if (response.notModified) {
        final cached = await localDataSource.getCachedContent(tabId);
        _dataSyncService.updateAppContent(tabId: tabId, data: cached ?? [], isStale: false);
        _dataSyncService.markAppContentRefreshCompleted(tabId, success: true);
        return Right(cached ?? []);
      }

      final contents = response.contents ?? [];
      
      await localDataSource.cacheContent(tabId, contents);
      if (response.etag != null) {
        await localDataSource.setCachedVersion(tabId, response.etag!);
      }

      // Update DataSyncService with fresh data
      _dataSyncService.updateAppContent(
        tabId: tabId,
        data: contents,
        isStale: false,
        etag: response.etag,
      );
      _dataSyncService.markAppContentRefreshCompleted(tabId, success: true);

      return Right(contents);
    } catch (e) {
      _dataSyncService.markAppContentRefreshCompleted(tabId, success: false);
      _dataSyncService.setAppContentLoading(tabId, false);
      
      final cached = await localDataSource.getCachedContent(tabId);
      if (cached != null) {
        _dataSyncService.updateAppContent(tabId: tabId, data: cached, isStale: true);
        return Right(cached);
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<void> _refreshInBackground(int? tabId, {bool overrideCache = true}) async {
    try {
      if (!await networkInfo.isConnected) return;
      if (!overrideCache && !_dataSyncService.shouldRefreshAppContent(tabId)) return;
      
      _dataSyncService.markAppContentRefreshStarted(tabId);
      
      final currentETag = await localDataSource.getCachedVersion(tabId);
      final response = await remoteDataSource.getAppContent(
        tabId: tabId,
        currentETag: currentETag,
      );

      if (!response.notModified && response.contents != null) {
        await localDataSource.cacheContent(tabId, response.contents!);
        if (response.etag != null) {
          await localDataSource.setCachedVersion(tabId, response.etag!);
        }
        // Update DataSyncService - this will trigger UI updates via stream
        _dataSyncService.updateAppContent(
          tabId: tabId,
          data: response.contents!,
          isStale: false,
          etag: response.etag,
        );
      }
      
      _dataSyncService.markAppContentRefreshCompleted(tabId, success: true);
    } catch (e) {
      _dataSyncService.markAppContentRefreshCompleted(tabId, success: false);
    }
  }

  @override
  Future<Either<Failure, List<AppContent>>> getCategoryScreenContent({
    bool forceRefresh = false,
  }) async {
    
    // Use a special tabId for category screen content (-999)
    const categoryScreenTabId = -999;

    // Check if we should skip refresh
    if (!forceRefresh && !_dataSyncService.shouldRefreshAppContent(categoryScreenTabId)) {
      final currentState = _dataSyncService.appContentState(categoryScreenTabId);
      if (currentState.hasData) {
        return Right(currentState.data!);
      }
    }

    // Try cache first if not forcing refresh
    if (!forceRefresh) {
      final cached = await localDataSource.getCachedContent(categoryScreenTabId);
      if (cached != null && cached.isNotEmpty) {
        _dataSyncService.updateAppContent(tabId: categoryScreenTabId, data: cached, isStale: true);
        _refreshCategoryScreenInBackground();
        return Right(cached);
      }
    }

    // Check network
    if (!await networkInfo.isConnected) {
      final cached = await localDataSource.getCachedContent(categoryScreenTabId);
      if (cached != null) {
        _dataSyncService.updateAppContent(tabId: categoryScreenTabId, data: cached, isStale: true);
        return Right(cached);
      }
      return const Left(NetworkFailure('No internet connection'));
    }

    // Mark refresh started
    _dataSyncService.markAppContentRefreshStarted(categoryScreenTabId);
    _dataSyncService.setAppContentLoading(categoryScreenTabId, true);

    try {
      final currentETag = forceRefresh ? null : await localDataSource.getCachedVersion(categoryScreenTabId);
      
      final response = await remoteDataSource.getCategoryScreenContent(
        currentETag: currentETag,
      );

      if (response.notModified) {
        final cached = await localDataSource.getCachedContent(categoryScreenTabId);
        _dataSyncService.updateAppContent(tabId: categoryScreenTabId, data: cached ?? [], isStale: false);
        _dataSyncService.markAppContentRefreshCompleted(categoryScreenTabId, success: true);
        return Right(cached ?? []);
      }

      final contents = response.contents ?? [];
      
      await localDataSource.cacheContent(categoryScreenTabId, contents);
      if (response.etag != null) {
        await localDataSource.setCachedVersion(categoryScreenTabId, response.etag!);
      }

      _dataSyncService.updateAppContent(
        tabId: categoryScreenTabId,
        data: contents,
        isStale: false,
        etag: response.etag,
      );
      _dataSyncService.markAppContentRefreshCompleted(categoryScreenTabId, success: true);

      return Right(contents);
    } catch (e) {
      _dataSyncService.markAppContentRefreshCompleted(categoryScreenTabId, success: false);
      _dataSyncService.setAppContentLoading(categoryScreenTabId, false);
      
      final cached = await localDataSource.getCachedContent(categoryScreenTabId);
      if (cached != null) {
        _dataSyncService.updateAppContent(tabId: categoryScreenTabId, data: cached, isStale: true);
        return Right(cached);
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<void> _refreshCategoryScreenInBackground({bool overrideCache = true}) async {
    const categoryScreenTabId = -999;
    try {
      if (!await networkInfo.isConnected) return;
      if (!overrideCache && !_dataSyncService.shouldRefreshAppContent(categoryScreenTabId)) return;
      
      _dataSyncService.markAppContentRefreshStarted(categoryScreenTabId);
      
      final currentETag = await localDataSource.getCachedVersion(categoryScreenTabId);
      final response = await remoteDataSource.getCategoryScreenContent(
        currentETag: currentETag,
      );

      if (!response.notModified && response.contents != null) {
        await localDataSource.cacheContent(categoryScreenTabId, response.contents!);
        if (response.etag != null) {
          await localDataSource.setCachedVersion(categoryScreenTabId, response.etag!);
        }
        _dataSyncService.updateAppContent(
          tabId: categoryScreenTabId,
          data: response.contents!,
          isStale: false,
          etag: response.etag,
        );
      }
      
      _dataSyncService.markAppContentRefreshCompleted(categoryScreenTabId, success: true);
    } catch (e) {
      _dataSyncService.markAppContentRefreshCompleted(categoryScreenTabId, success: false);
    }
  }
}

