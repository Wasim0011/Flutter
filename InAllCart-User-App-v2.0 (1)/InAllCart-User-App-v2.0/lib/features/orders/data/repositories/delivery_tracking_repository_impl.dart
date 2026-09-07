import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/data_sync_service.dart';
import '../../domain/entities/delivery_tracking.dart';
import '../../domain/repositories/delivery_tracking_repository.dart';
import '../datasources/delivery_tracking_local_datasource.dart';
import '../datasources/delivery_tracking_remote_datasource.dart';

/// Delivery tracking repository implementation
/// 
/// Uses EXACT SAME pattern as ProductRepositoryImpl:
/// - Cache-first approach (show instantly)
/// - ETag validation in background
/// - 304 responses when no location change
/// - Reactive updates via DataSyncService
class DeliveryTrackingRepositoryImpl implements DeliveryTrackingRepository {
  final DeliveryTrackingRemoteDataSource _remoteDataSource;
  final DeliveryTrackingLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;
  final DataSyncService _dataSyncService;

  DeliveryTrackingRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._networkInfo,
  ) : _dataSyncService = DataSyncService();

  @override
  Future<Either<Failure, DeliveryTracking>> getTrackingData({
    required int orderId,
    bool forceRefresh = false,
  }) async {
    final isConnected = await _networkInfo.isConnected;

    // Set loading state
    _dataSyncService.setDeliveryTrackingLoading(orderId, true);

    // Offline - return cached data only
    if (!isConnected) {
      final result = await _getCachedTrackingData(orderId);
      _dataSyncService.setDeliveryTrackingLoading(orderId, false);
      return result;
    }

    // Force refresh - clear cache and fetch fresh
    if (forceRefresh) {
      await _localDataSource.setCachedVersion(orderId, '');
      _dataSyncService.resetRetryCount('tracking_$orderId');
      final result = await _fetchTrackingFromServer(orderId);
      _dataSyncService.setDeliveryTrackingLoading(orderId, false);
      return result;
    }

    // Stale-while-revalidate pattern (SAME AS PRODUCTS)
    final cachedTracking = await _localDataSource.getCachedTrackingData(orderId);

    if (cachedTracking != null) {
      // Return cached data instantly
      _dataSyncService.updateDeliveryTracking(
        orderId: orderId,
        data: cachedTracking,
        isStale: true,
      );

      // Validate in background
      _backgroundRefreshTracking(orderId);

      _dataSyncService.setDeliveryTrackingLoading(orderId, false);
      return Right(cachedTracking);
    }

    // No cache - fetch from server
    final result = await _fetchTrackingFromServer(orderId);
    _dataSyncService.setDeliveryTrackingLoading(orderId, false);
    return result;
  }

  /// Fetch tracking data from server with ETag support
  Future<Either<Failure, DeliveryTracking>> _fetchTrackingFromServer(int orderId) async {
    try {
      final currentETag = await _localDataSource.getCachedVersion(orderId);

      final response = await _remoteDataSource.getTrackingDataWithETag(
        orderId: orderId,
        currentETag: currentETag,
      );

      // 304 Not Modified - use cached data
      if (response.notModified) {
        final cached = await _localDataSource.getCachedTrackingData(orderId);
        if (cached != null) {
          _dataSyncService.updateDeliveryTracking(
            orderId: orderId,
            data: cached,
            isStale: false,
          );
          return Right(cached);
        }
        // Cache is empty but server returned 304 - clear ETag and refetch
        await _localDataSource.setCachedVersion(orderId, '');
        return _fetchTrackingFromServer(orderId);
      }

      // New data - cache it
      if (response.tracking != null) {
        await _localDataSource.cacheTrackingData(orderId, response.tracking!);
        if (response.etag != null) {
          await _localDataSource.setCachedVersion(orderId, response.etag!);
        }

        _dataSyncService.updateDeliveryTracking(
          orderId: orderId,
          data: response.tracking!,
          isStale: false,
          etag: response.etag,
        );

        return Right(response.tracking!);
      }

      return const Left(ServerFailure('Invalid tracking data'));
    } on NetworkException {
      return _getCachedTrackingData(orderId);
    } on ServerException catch (e) {
      _dataSyncService.updateDeliveryTracking(
        orderId: orderId,
        error: ServerFailure(e.message, statusCode: e.statusCode),
      );
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      final failure = ServerFailure('Failed to load tracking data: $e');
      _dataSyncService.updateDeliveryTracking(
        orderId: orderId,
        error: failure,
      );
      return Left(failure);
    }
  }

  /// Get cached tracking data
  Future<Either<Failure, DeliveryTracking>> _getCachedTrackingData(int orderId) async {
    try {
      final tracking = await _localDataSource.getCachedTrackingData(orderId);
      if (tracking == null) {
        final failure = const NetworkFailure('No internet connection and no cached data');
        _dataSyncService.updateDeliveryTracking(
          orderId: orderId,
          error: failure,
        );
        return Left(failure);
      }
      _dataSyncService.updateDeliveryTracking(
        orderId: orderId,
        data: tracking,
        isStale: true,
      );
      return Right(tracking);
    } catch (e) {
      final failure = CacheFailure('Failed to load cached tracking data: $e');
      _dataSyncService.updateDeliveryTracking(
        orderId: orderId,
        error: failure,
      );
      return Left(failure);
    }
  }

  /// Background refresh with ETag validation (SAME AS PRODUCTS)
  Future<void> _backgroundRefreshTracking(int orderId) async {
    final refreshKey = 'tracking_$orderId';

    if (!_dataSyncService.shouldRefreshDeliveryTracking(orderId)) {
      return;
    }

    _dataSyncService.markDeliveryTrackingRefreshStarted(orderId);

    try {
      final currentETag = await _localDataSource.getCachedVersion(orderId);

      final response = await _remoteDataSource.getTrackingDataWithETag(
        orderId: orderId,
        currentETag: currentETag,
      );

      // 304 Not Modified - keep current data
      if (response.notModified) {
        final current = _dataSyncService.getDeliveryTrackingState(orderId);
        if (current.hasData) {
          _dataSyncService.updateDeliveryTracking(
            orderId: orderId,
            data: current.data,
            isStale: false,
          );
        }
        _dataSyncService.markDeliveryTrackingRefreshCompleted(orderId, success: true);
        return;
      }

      // New data - cache and update
      if (response.tracking != null) {
        await _localDataSource.cacheTrackingData(orderId, response.tracking!);
        if (response.etag != null) {
          await _localDataSource.setCachedVersion(orderId, response.etag!);
        }

        _dataSyncService.updateDeliveryTracking(
          orderId: orderId,
          data: response.tracking!,
          isStale: false,
          etag: response.etag,
        );
      }

      _dataSyncService.markDeliveryTrackingRefreshCompleted(orderId, success: true);
    } catch (e) {
      _dataSyncService.markDeliveryTrackingRefreshCompleted(orderId, success: false);

      // Retry with exponential backoff
      if (_dataSyncService.shouldRetry(refreshKey)) {
        final delay = _dataSyncService.getRetryDelay(refreshKey);
        Future.delayed(delay, () => _backgroundRefreshTracking(orderId));
      }
    }
  }

  @override
  Future<Either<Failure, List<TrackingHistoryPoint>>> getTrackingHistory({
    required int orderId,
  }) async {
    try {
      final response = await _remoteDataSource.getTrackingHistory(
        orderId: orderId,
      );
      return Right(response.history);
    } on NetworkException {
      return const Left(NetworkFailure('No internet connection'));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure('Failed to load tracking history: $e'));
    }
  }

  @override
  Future<void> clearTrackingCache(int orderId) async {
    await _localDataSource.clearTrackingCache(orderId);
  }
}
