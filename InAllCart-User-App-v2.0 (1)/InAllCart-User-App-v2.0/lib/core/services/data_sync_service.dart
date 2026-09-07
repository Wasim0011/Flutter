import 'dart:async';
import 'package:rxdart/rxdart.dart';

import '../error/failures.dart';
import '../../features/categories/domain/entities/category.dart';
import '../../features/products/domain/entities/product.dart';
import '../../features/home_header/domain/entities/home_header_config.dart';
import '../../features/app_content/domain/entities/app_content.dart';
import '../../features/orders/domain/entities/order.dart';
import '../../features/orders/domain/entities/delivery_tracking.dart';

/// Data state wrapper with metadata
class DataState<T> {
  final T? data;
  final bool isLoading;
  final bool isStale;
  final Failure? error;
  final DateTime? lastUpdated;
  final String? etag;

  const DataState({
    this.data,
    this.isLoading = false,
    this.isStale = false,
    this.error,
    this.lastUpdated,
    this.etag,
  });

  DataState<T> copyWith({
    T? data,
    bool? isLoading,
    bool? isStale,
    Failure? error,
    DateTime? lastUpdated,
    String? etag,
  }) {
    return DataState<T>(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      isStale: isStale ?? this.isStale,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      etag: etag ?? this.etag,
    );
  }

  bool get hasData => data != null;
  bool get hasError => error != null;
}

/// Refresh strategy configuration
class RefreshConfig {
  /// Minimum time between background refreshes
  final Duration minRefreshInterval;
  
  /// Time after which data is considered stale
  final Duration staleAfter;
  
  /// Maximum retries on failure
  final int maxRetries;
  
  /// Retry delay multiplier (exponential backoff)
  final Duration retryDelay;

  const RefreshConfig({
    this.minRefreshInterval = const Duration(seconds: 10),
    this.staleAfter = const Duration(minutes: 5),
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 2),
  });
}
 
/// Usage:
/// ```dart
/// // Subscribe to data stream
/// dataSyncService.featuredCategoriesStream.listen((state) {
///   if (state.hasData) updateUI(state.data);
/// });
/// 
/// // Trigger refresh
/// dataSyncService.refreshFeaturedCategories();
/// ```
class DataSyncService {
  static final DataSyncService _instance = DataSyncService._internal();
  factory DataSyncService() => _instance;
  DataSyncService._internal();

  // ============== STREAM CONTROLLERS ==============
  
  /// Featured categories stream - UI subscribes to this
  final _featuredCategoriesSubject = BehaviorSubject<DataState<List<Category>>>.seeded(
    const DataState<List<Category>>(),
  );
  
  /// Featured products stream - UI subscribes to this
  final _featuredProductsSubject = BehaviorSubject<DataState<List<Product>>>.seeded(
    const DataState<List<Product>>(),
  );
  
  /// All categories stream
  final _categoriesSubject = BehaviorSubject<DataState<List<Category>>>.seeded(
    const DataState<List<Category>>(),
  );

  /// Home header config stream - UI subscribes to this
  final _homeHeaderSubject = BehaviorSubject<DataState<HomeHeaderConfig>>.seeded(
    const DataState<HomeHeaderConfig>(),
  );

  /// App content stream - keyed by tab ID
  final Map<int?, BehaviorSubject<DataState<List<AppContent>>>> _appContentSubjects = {};

  /// Orders stream - UI subscribes to this
  final _ordersSubject = BehaviorSubject<DataState<List<Order>>>.seeded(
    const DataState<List<Order>>(),
  );

  /// Delivery tracking streams - keyed by order ID
  final Map<int, BehaviorSubject<DataState<DeliveryTracking>>> _deliveryTrackingSubjects = {};

  // ============== PUBLIC STREAMS ==============
  
  /// Stream of featured categories state
  Stream<DataState<List<Category>>> get featuredCategoriesStream => 
      _featuredCategoriesSubject.stream;
  
  /// Stream of featured products state
  Stream<DataState<List<Product>>> get featuredProductsStream => 
      _featuredProductsSubject.stream;
  
  /// Stream of all categories state
  Stream<DataState<List<Category>>> get categoriesStream => 
      _categoriesSubject.stream;

  /// Stream of home header config state
  Stream<DataState<HomeHeaderConfig>> get homeHeaderStream => 
      _homeHeaderSubject.stream;

  /// Get app content stream for a specific tab
  Stream<DataState<List<AppContent>>> appContentStream(int? tabId) {
    _ensureAppContentSubject(tabId);
    return _appContentSubjects[tabId]!.stream;
  }

  /// Stream of orders state
  Stream<DataState<List<Order>>> get ordersStream => 
      _ordersSubject.stream;

  /// Get delivery tracking stream for a specific order
  Stream<DataState<DeliveryTracking>> deliveryTrackingStream(int orderId) {
    _ensureDeliveryTrackingSubject(orderId);
    return _deliveryTrackingSubjects[orderId]!.stream;
  }

  void _ensureDeliveryTrackingSubject(int orderId) {
    if (!_deliveryTrackingSubjects.containsKey(orderId)) {
      _deliveryTrackingSubjects[orderId] = BehaviorSubject<DataState<DeliveryTracking>>.seeded(
        const DataState<DeliveryTracking>(),
      );
    }
  }

  void _ensureAppContentSubject(int? tabId) {
    if (!_appContentSubjects.containsKey(tabId)) {
      _appContentSubjects[tabId] = BehaviorSubject<DataState<List<AppContent>>>.seeded(
        const DataState<List<AppContent>>(),
      );
    }
  }

  // ============== CURRENT VALUES ==============
  
  /// Current featured categories state
  DataState<List<Category>> get featuredCategoriesState => 
      _featuredCategoriesSubject.value;
  
  /// Current featured products state
  DataState<List<Product>> get featuredProductsState => 
      _featuredProductsSubject.value;
  
  /// Current categories state
  DataState<List<Category>> get categoriesState => 
      _categoriesSubject.value;

  /// Current home header state
  DataState<HomeHeaderConfig> get homeHeaderState => 
      _homeHeaderSubject.value;

  /// Get current app content state for a tab
  DataState<List<AppContent>> appContentState(int? tabId) {
    _ensureAppContentSubject(tabId);
    return _appContentSubjects[tabId]!.value;
  }

  /// Current orders state
  DataState<List<Order>> get ordersState => 
      _ordersSubject.value;

  /// Get current delivery tracking state for an order
  DataState<DeliveryTracking> getDeliveryTrackingState(int orderId) {
    _ensureDeliveryTrackingSubject(orderId);
    return _deliveryTrackingSubjects[orderId]!.value;
  }

  // ============== REFRESH TRACKING ==============
  
  final Map<String, DateTime> _lastRefreshAttempts = {};
  final Map<String, int> _retryCount = {};
  final Set<String> _pendingRefreshes = {};
  
  final RefreshConfig _config = const RefreshConfig();

  // ============== FEATURED CATEGORIES ==============

  /// Update featured categories state
  void updateFeaturedCategories({
    List<Category>? data,
    bool? isLoading,
    bool? isStale,
    Failure? error,
    String? etag,
  }) {
    final current = _featuredCategoriesSubject.value;
    _featuredCategoriesSubject.add(current.copyWith(
      data: data,
      isLoading: isLoading,
      isStale: isStale,
      error: error,
      lastUpdated: data != null ? DateTime.now() : current.lastUpdated,
      etag: etag,
    ));
  }

  /// Mark featured categories as loading
  void setFeaturedCategoriesLoading(bool loading) {
    final current = _featuredCategoriesSubject.value;
    _featuredCategoriesSubject.add(current.copyWith(isLoading: loading));
  }

  /// Check if featured categories need refresh
  bool shouldRefreshFeaturedCategories() {
    return _shouldRefresh('featured_categories', _featuredCategoriesSubject.value);
  }

  /// Mark refresh as started
  void markFeaturedCategoriesRefreshStarted() {
    _markRefreshStarted('featured_categories');
  }

  /// Mark refresh as completed
  void markFeaturedCategoriesRefreshCompleted({bool success = true}) {
    _markRefreshCompleted('featured_categories', success: success);
  }

  // ============== FEATURED PRODUCTS ==============

  /// Update featured products state
  void updateFeaturedProducts({
    List<Product>? data,
    bool? isLoading,
    bool? isStale,
    Failure? error,
    String? etag,
  }) {
    final current = _featuredProductsSubject.value;
    _featuredProductsSubject.add(current.copyWith(
      data: data,
      isLoading: isLoading,
      isStale: isStale,
      error: error,
      lastUpdated: data != null ? DateTime.now() : current.lastUpdated,
      etag: etag,
    ));
  }

  /// Mark featured products as loading
  void setFeaturedProductsLoading(bool loading) {
    final current = _featuredProductsSubject.value;
    _featuredProductsSubject.add(current.copyWith(isLoading: loading));
  }

  /// Check if featured products need refresh
  bool shouldRefreshFeaturedProducts() {
    return _shouldRefresh('featured_products', _featuredProductsSubject.value);
  }

  /// Mark refresh as started
  void markFeaturedProductsRefreshStarted() {
    _markRefreshStarted('featured_products');
  }

  /// Mark refresh as completed
  void markFeaturedProductsRefreshCompleted({bool success = true}) {
    _markRefreshCompleted('featured_products', success: success);
  }

  // ============== ALL CATEGORIES ==============

  /// Update categories state
  void updateCategories({
    List<Category>? data,
    bool? isLoading,
    bool? isStale,
    Failure? error,
    String? etag,
  }) {
    final current = _categoriesSubject.value;
    _categoriesSubject.add(current.copyWith(
      data: data,
      isLoading: isLoading,
      isStale: isStale,
      error: error,
      lastUpdated: data != null ? DateTime.now() : current.lastUpdated,
      etag: etag,
    ));
  }

  // ============== HOME HEADER ==============

  /// Update home header state
  void updateHomeHeader({
    HomeHeaderConfig? data,
    bool? isLoading,
    bool? isStale,
    Failure? error,
    String? etag,
  }) {
    final current = _homeHeaderSubject.value;
    _homeHeaderSubject.add(current.copyWith(
      data: data,
      isLoading: isLoading,
      isStale: isStale,
      error: error,
      lastUpdated: data != null ? DateTime.now() : current.lastUpdated,
      etag: etag,
    ));
  }

  /// Mark home header as loading
  void setHomeHeaderLoading(bool loading) {
    final current = _homeHeaderSubject.value;
    _homeHeaderSubject.add(current.copyWith(isLoading: loading));
  }

  /// Check if home header needs refresh
  bool shouldRefreshHomeHeader() {
    return _shouldRefresh('home_header', _homeHeaderSubject.value);
  }

  /// Mark refresh as started
  void markHomeHeaderRefreshStarted() {
    _markRefreshStarted('home_header');
  }

  /// Mark refresh as completed
  void markHomeHeaderRefreshCompleted({bool success = true}) {
    _markRefreshCompleted('home_header', success: success);
  }

  // ============== APP CONTENT ==============

  /// Update app content state for a specific tab
  void updateAppContent({
    required int? tabId,
    List<AppContent>? data,
    bool? isLoading,
    bool? isStale,
    Failure? error,
    String? etag,
  }) {
    _ensureAppContentSubject(tabId);
    final current = _appContentSubjects[tabId]!.value;
    _appContentSubjects[tabId]!.add(current.copyWith(
      data: data,
      isLoading: isLoading,
      isStale: isStale,
      error: error,
      lastUpdated: data != null ? DateTime.now() : current.lastUpdated,
      etag: etag,
    ));
  }

  /// Mark app content as loading
  void setAppContentLoading(int? tabId, bool loading) {
    _ensureAppContentSubject(tabId);
    final current = _appContentSubjects[tabId]!.value;
    _appContentSubjects[tabId]!.add(current.copyWith(isLoading: loading));
  }

  /// Check if app content needs refresh
  bool shouldRefreshAppContent(int? tabId) {
    _ensureAppContentSubject(tabId);
    return _shouldRefresh('app_content_$tabId', _appContentSubjects[tabId]!.value);
  }

  /// Mark refresh as started
  void markAppContentRefreshStarted(int? tabId) {
    _markRefreshStarted('app_content_$tabId');
  }

  /// Mark refresh as completed
  void markAppContentRefreshCompleted(int? tabId, {bool success = true}) {
    _markRefreshCompleted('app_content_$tabId', success: success);
  }

  // ============== ORDERS ==============

  /// Update orders state
  void updateOrders({
    List<Order>? data,
    bool? isLoading,
    bool? isStale,
    Failure? error,
    String? etag,
  }) {
    final current = _ordersSubject.value;
    _ordersSubject.add(current.copyWith(
      data: data,
      isLoading: isLoading,
      isStale: isStale,
      error: error,
      lastUpdated: data != null ? DateTime.now() : current.lastUpdated,
      etag: etag,
    ));
  }

  /// Mark orders as loading
  void setOrdersLoading(bool loading) {
    final current = _ordersSubject.value;
    _ordersSubject.add(current.copyWith(isLoading: loading));
  }

  /// Check if orders need refresh
  bool shouldRefreshOrders() {
    return _shouldRefresh('orders', _ordersSubject.value);
  }

  /// Mark refresh as started
  void markOrdersRefreshStarted() {
    _markRefreshStarted('orders');
  }

  /// Mark refresh as completed
  void markOrdersRefreshCompleted({bool success = true}) {
    _markRefreshCompleted('orders', success: success);
  }

  // ============== DELIVERY TRACKING ==============

  /// Update delivery tracking state for a specific order
  void updateDeliveryTracking({
    required int orderId,
    DeliveryTracking? data,
    bool? isLoading,
    bool? isStale,
    Failure? error,
    String? etag,
  }) {
    _ensureDeliveryTrackingSubject(orderId);
    final current = _deliveryTrackingSubjects[orderId]!.value;
    _deliveryTrackingSubjects[orderId]!.add(current.copyWith(
      data: data,
      isLoading: isLoading,
      isStale: isStale,
      error: error,
      lastUpdated: data != null ? DateTime.now() : current.lastUpdated,
      etag: etag,
    ));
  }

  /// Mark delivery tracking as loading
  void setDeliveryTrackingLoading(int orderId, bool loading) {
    _ensureDeliveryTrackingSubject(orderId);
    final current = _deliveryTrackingSubjects[orderId]!.value;
    _deliveryTrackingSubjects[orderId]!.add(current.copyWith(isLoading: loading));
  }

  /// Check if delivery tracking needs refresh
  bool shouldRefreshDeliveryTracking(int orderId) {
    _ensureDeliveryTrackingSubject(orderId);
    return _shouldRefresh('tracking_$orderId', _deliveryTrackingSubjects[orderId]!.value);
  }

  /// Mark refresh as started
  void markDeliveryTrackingRefreshStarted(int orderId) {
    _markRefreshStarted('tracking_$orderId');
  }

  /// Mark refresh as completed
  void markDeliveryTrackingRefreshCompleted(int orderId, {bool success = true}) {
    _markRefreshCompleted('tracking_$orderId', success: success);
  }

  // ============== INTERNAL HELPERS ==============

  bool _shouldRefresh<T>(String key, DataState<T> state) {
    if (_pendingRefreshes.contains(key)) {
      return false;
    }

    final lastAttempt = _lastRefreshAttempts[key];
    if (lastAttempt != null) {
      final elapsed = DateTime.now().difference(lastAttempt);
      if (elapsed < _config.minRefreshInterval) {
        return false;
      }
    }

    if (state.lastUpdated != null) {
      final age = DateTime.now().difference(state.lastUpdated!);
      if (age > _config.staleAfter) {
        return true;
      }
    }

    return true;
  }

  void _markRefreshStarted(String key) {
    _pendingRefreshes.add(key);
    _lastRefreshAttempts[key] = DateTime.now();
  }

  void _markRefreshCompleted(String key, {bool success = true}) {
    _pendingRefreshes.remove(key);
    
    if (success) {
      _retryCount.remove(key);
    } else {
      final retries = (_retryCount[key] ?? 0) + 1;
      _retryCount[key] = retries;
    }
  }

  /// Get retry delay with exponential backoff
  Duration getRetryDelay(String key) {
    final retries = _retryCount[key] ?? 0;
    return _config.retryDelay * (1 << retries); // 2^retries * baseDelay
  }

  /// Check if should retry
  bool shouldRetry(String key) {
    final retries = _retryCount[key] ?? 0;
    return retries < _config.maxRetries;
  }

  /// Reset retry count (call after successful manual refresh)
  void resetRetryCount(String key) {
    _retryCount.remove(key);
  }

  // ============== CLEANUP ==============

  /// Dispose all streams
  void dispose() {
    _featuredCategoriesSubject.close();
    _featuredProductsSubject.close();
    _categoriesSubject.close();
    _homeHeaderSubject.close();
    _ordersSubject.close();
    for (final subject in _appContentSubjects.values) {
      subject.close();
    }
    _appContentSubjects.clear();
    for (final subject in _deliveryTrackingSubjects.values) {
      subject.close();
    }
    _deliveryTrackingSubjects.clear();
  }

  /// Clear all cached data (for logout)
  void clearAll() {
    _featuredCategoriesSubject.add(const DataState<List<Category>>());
    _featuredProductsSubject.add(const DataState<List<Product>>());
    _categoriesSubject.add(const DataState<List<Category>>());
    _homeHeaderSubject.add(const DataState<HomeHeaderConfig>());
    _ordersSubject.add(const DataState<List<Order>>());
    for (final subject in _appContentSubjects.values) {
      subject.add(const DataState<List<AppContent>>());
    }
    for (final subject in _deliveryTrackingSubjects.values) {
      subject.add(const DataState<DeliveryTracking>());
    }
    _lastRefreshAttempts.clear();
    _retryCount.clear();
    _pendingRefreshes.clear();
  }
}
