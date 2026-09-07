import 'dart:async';

import '../di/injection.dart';
import '../../features/products/data/datasources/product_local_datasource.dart';
import '../../features/categories/data/datasources/category_local_datasource.dart';
import '../../features/cart/data/datasources/cart_local_datasource.dart';
import 'push_notification_service.dart';

/// Service to handle cache invalidation via push notifications
/// Listens for silent push notifications and invalidates relevant caches
class CacheSyncService {
  final PushNotificationService _pushService;
  final ProductLocalDataSource _productLocalDataSource;
  final CategoryLocalDataSource _categoryLocalDataSource;
  final CartLocalDataSource _cartLocalDataSource;

  final _cacheInvalidationController = StreamController<CacheInvalidationEvent>.broadcast();
  Stream<CacheInvalidationEvent> get onCacheInvalidation => _cacheInvalidationController.stream;

  StreamSubscription? _pushSubscription;

  CacheSyncService(
    this._pushService,
    this._productLocalDataSource,
    this._categoryLocalDataSource,
    this._cartLocalDataSource,
  );

  /// Initialize the cache sync service
  void initialize() {
    // Listen for push notification messages
    _pushSubscription = _pushService.onMessage.listen(_handlePushMessage);
  }

  /// Dispose resources
  void dispose() {
    _pushSubscription?.cancel();
    _cacheInvalidationController.close();
  }

  /// Handle incoming push notification
  Future<void> _handlePushMessage(Map<String, dynamic> message) async {
    final data = message['data'] as Map<String, dynamic>?;
    if (data == null) return;

    final type = data['type'] as String?;
    if (type != 'cache_invalidation') return;

    final resource = data['resource'] as String?;
    final action = data['action'] as String?;

    if (resource == null || action == null) return;

    await _handleCacheInvalidation(resource, action, data);
  }

  /// Handle cache invalidation based on resource type
  Future<void> _handleCacheInvalidation(
    String resource,
    String action,
    Map<String, dynamic> data,
  ) async {
    switch (resource) {
      case 'products':
        await _handleProductInvalidation(action, data);
        break;
      case 'categories':
        await _handleCategoryInvalidation(action, data);
        break;
      case 'cart':
        await _handleCartInvalidation(action, data);
        break;
      case 'all':
        await _handleFullInvalidation();
        break;
    }

    // Emit event for UI to refresh
    _cacheInvalidationController.add(
      CacheInvalidationEvent(resource, action, data),
    );
  }

  /// Handle product cache invalidation
  Future<void> _handleProductInvalidation(String action, Map<String, dynamic> data) async {
    switch (action) {
      case 'created':
      case 'updated':
      case 'bulk_updated':
        // Invalidate products list cache
        await _productLocalDataSource.clearCache();
        break;
      case 'deleted':
        // Remove specific product from cache
        final productId = data['product_id'] as int?;
        if (productId != null) {
          await _productLocalDataSource.removeFromCache(productId);
        }
        break;
      case 'price_changed':
        // Invalidate all products (prices might affect multiple)
        await _productLocalDataSource.clearCache();
        break;
    }
  }

  /// Handle category cache invalidation
  Future<void> _handleCategoryInvalidation(String action, Map<String, dynamic> data) async {
    // Categories change rarely, so just clear all
    await _categoryLocalDataSource.clearCache();
  }

  /// Handle cart cache invalidation
  Future<void> _handleCartInvalidation(String action, Map<String, dynamic> data) async {
    switch (action) {
      case 'synced':
        // Cart was synced from another device, reload
        await _cartLocalDataSource.clearCart();
        break;
      case 'cleared':
        await _cartLocalDataSource.clearCart();
        break;
    }
  }

  /// Handle full cache invalidation (e.g., app update)
  Future<void> _handleFullInvalidation() async {
    await _productLocalDataSource.clearCache();
    await _categoryLocalDataSource.clearCache();
    // Don't clear cart - user's data
  }

  /// Manually invalidate a specific cache
  Future<void> invalidateCache(String resource) async {
    switch (resource) {
      case 'products':
        await _productLocalDataSource.clearCache();
        break;
      case 'categories':
        await _categoryLocalDataSource.clearCache();
        break;
      case 'cart':
        await _cartLocalDataSource.clearCart();
        break;
      case 'all':
        await _handleFullInvalidation();
        break;
    }

    _cacheInvalidationController.add(
      CacheInvalidationEvent(resource, 'manual', {}),
    );
  }

  /// Check if any cache needs refresh
  Future<Map<String, bool>> getCacheStatus() async {
    final productCacheValid = await _productLocalDataSource.isCacheValid();
    final categoryCacheValid = await _categoryLocalDataSource.isCacheValid();

    return {
      'products': productCacheValid,
      'categories': categoryCacheValid,
    };
  }
}

/// Event emitted when cache is invalidated
class CacheInvalidationEvent {
  final String resource;
  final String action;
  final Map<String, dynamic> data;

  CacheInvalidationEvent(this.resource, this.action, this.data);
}

/// Factory to create CacheSyncService with dependencies
CacheSyncService createCacheSyncService() {
  return CacheSyncService(
    getIt<PushNotificationService>(),
    getIt<ProductLocalDataSource>(),
    getIt<CategoryLocalDataSource>(),
    getIt<CartLocalDataSource>(),
  );
}
