import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/data_sync_service.dart';
import '../../domain/entities/order.dart' as order_entity;
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_remote_datasource.dart';
import '../datasources/order_local_datasource.dart';
import '../../../checkout/domain/entities/checkout_data.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource remoteDataSource;
  final OrderLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final DataSyncService _dataSyncService;

  OrderRepositoryImpl(
    this.remoteDataSource,
    this.localDataSource,
    this.networkInfo,
  ) : _dataSyncService = DataSyncService();

  @override
  Future<Either<Failure, List<order_entity.Order>>> getOrders({
    int page = 1,
    int perPage = 15,
  }) async {
    
    // Check if we should skip refresh (but allow if forced)
    if (!_dataSyncService.shouldRefreshOrders()) {
      final currentState = _dataSyncService.ordersState;
      if (currentState.hasData) {
        return Right(currentState.data!);
      }
    }

    // Try cache first
    final cached = await localDataSource.getCachedOrders();
    if (cached != null && cached.isNotEmpty) {
      _dataSyncService.updateOrders(data: cached, isStale: true);
      _refreshInBackground(forceRefresh: false);
      return Right(cached);
    }

    // Check network
    if (!await networkInfo.isConnected) {
      if (cached != null) {
        _dataSyncService.updateOrders(data: cached, isStale: true);
        return Right(cached);
      }
      return const Left(NetworkFailure('No internet connection'));
    }

    return _fetchFromServer();
  }

  Future<Either<Failure, List<order_entity.Order>>> _fetchFromServer() async {
    // Mark refresh started
    _dataSyncService.markOrdersRefreshStarted();
    _dataSyncService.setOrdersLoading(true);

    try {
      final currentETag = await localDataSource.getCachedVersion();
      
      final response = await remoteDataSource.getOrders(
        page: 1,
        perPage: 15,
        currentETag: currentETag,
      );

      if (response.notModified) {
        final cachedOrders = await localDataSource.getCachedOrders();
        _dataSyncService.updateOrders(data: cachedOrders ?? [], isStale: false);
        _dataSyncService.markOrdersRefreshCompleted(success: true);
        return Right(cachedOrders ?? []);
      }

      final orders = response.orders ?? [];
      
      await localDataSource.cacheOrders(orders);
      if (response.etag != null) {
        await localDataSource.setCachedVersion(response.etag!);
      }

      _dataSyncService.updateOrders(
        data: orders,
        isStale: false,
        etag: response.etag,
      );
      _dataSyncService.markOrdersRefreshCompleted(success: true);

      return Right(orders);
    } on DioException catch (e) {
      _dataSyncService.markOrdersRefreshCompleted(success: false);
      _dataSyncService.setOrdersLoading(false);
      
      if (e.response?.statusCode == 401) {
        return Left(UnauthorizedFailure('Please login to view orders'));
      }
      
      final cachedOrders = await localDataSource.getCachedOrders();
      if (cachedOrders != null) {
        _dataSyncService.updateOrders(data: cachedOrders, isStale: true);
        return Right(cachedOrders);
      }
      return Left(ServerFailure(e.message ?? 'Failed to load orders'));
    } catch (e) {
      _dataSyncService.markOrdersRefreshCompleted(success: false);
      _dataSyncService.setOrdersLoading(false);
      
      final cachedOrders = await localDataSource.getCachedOrders();
      if (cachedOrders != null) {
        _dataSyncService.updateOrders(data: cachedOrders, isStale: true);
        return Right(cachedOrders);
      }
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  Future<void> _refreshInBackground({bool forceRefresh = false}) async {
    try {
      if (!await networkInfo.isConnected) return;
      if (!forceRefresh && !_dataSyncService.shouldRefreshOrders()) return;
      
      _dataSyncService.markOrdersRefreshStarted();
      
      final currentETag = await localDataSource.getCachedVersion();
      final response = await remoteDataSource.getOrders(
        page: 1,
        perPage: 15,
        currentETag: currentETag,
      );

      if (!response.notModified && response.orders != null) {
        await localDataSource.cacheOrders(response.orders!);
        if (response.etag != null) {
          await localDataSource.setCachedVersion(response.etag!);
        }
        _dataSyncService.updateOrders(
          data: response.orders!,
          isStale: false,
          etag: response.etag,
        );
      }
      
      _dataSyncService.markOrdersRefreshCompleted(success: true);
    } catch (e) {
      _dataSyncService.markOrdersRefreshCompleted(success: false);
    }
  }

  /// Force refresh orders (bypasses throttle)
  @override
  Future<Either<Failure, List<order_entity.Order>>> forceRefreshOrders() async {
    await localDataSource.clearCache();
    return _fetchFromServer();
  }

  @override
  Future<Either<Failure, order_entity.Order>> getOrderById(int orderId) async {
    try {
      final order = await remoteDataSource.getOrderById(orderId);
      return Right(order);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return Left(UnauthorizedFailure('Please login to view order'));
      }
      if (e.response?.statusCode == 404) {
        return Left(ServerFailure('Order not found'));
      }
      return Left(ServerFailure(e.message ?? 'Failed to load order'));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, order_entity.Order>> getOrderByNumber(String orderNumber) async {
    try {
      final order = await remoteDataSource.getOrderByNumber(orderNumber);
      return Right(order);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return Left(ServerFailure('Order not found'));
      }
      return Left(ServerFailure(e.message ?? 'Failed to load order'));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, order_entity.Order>> placeOrder(PlaceOrderRequest request) async {
    try {
      
      final response = await remoteDataSource.placeOrder(request);
      
      // Clear orders cache to force refresh
      await localDataSource.clearCache();
      
      // Return the primary order (for navigation)
      // If multiple orders were created, the user will see them in the orders list
      return Right(response.primaryOrder);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return Left(UnauthorizedFailure('Please login to place order'));
      }
      if (e.response?.statusCode == 400) {
        final message = e.response?.data['message'] ?? 'Invalid order data';
        return Left(ServerFailure(message));
      }
      return Left(ServerFailure(e.message ?? 'Failed to place order'));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, order_entity.Order>> cancelOrder(int orderId, String? reason) async {
    try {
      final order = await remoteDataSource.cancelOrder(orderId, reason);
      // Clear orders cache to force refresh
      await localDataSource.clearCache();
      return Right(order);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return Left(UnauthorizedFailure('Please login to cancel order'));
      }
      if (e.response?.statusCode == 400) {
        final message = e.response?.data['message'] ?? 'Cannot cancel order';
        return Left(ServerFailure(message));
      }
      return Left(ServerFailure(e.message ?? 'Failed to cancel order'));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> trackOrder(
    String orderNumber,
  ) async {
    try {
      final tracking = await remoteDataSource.trackOrder(orderNumber);
      return Right(tracking);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return Left(ServerFailure('Order not found'));
      }
      return Left(ServerFailure(e.message ?? 'Failed to track order'));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }
}
