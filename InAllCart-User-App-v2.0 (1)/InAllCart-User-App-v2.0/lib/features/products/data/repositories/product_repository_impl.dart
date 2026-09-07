import 'dart:async';
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:crypto/crypto.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/data_sync_service.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_local_datasource.dart';
import '../datasources/product_remote_datasource.dart';

/// Production-grade product repository
///
/// Architecture:
/// - Stale-while-revalidate pattern
/// - Reactive updates via DataSyncService streams
/// - ETag-based cache validation
/// - Automatic background refresh
/// - Proper error handling with retry logic
class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource _remoteDataSource;
  final ProductLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;
  final DataSyncService _dataSyncService;

  ProductRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._networkInfo,
  ) : _dataSyncService = DataSyncService();

  // ============== PRODUCTS LIST (PAGINATED - NO FULL CACHE) ==============

  String _productsListKey({
    required int perPage,
    String? search,
    int? categoryId,
    double? minPrice,
    double? maxPrice,
    String? brand,
    int? brandId,
    int? storeId,
  }) {
    final raw = jsonEncode({
      'per_page': perPage,
      'search': search ?? '',
      'category_id': categoryId ?? 0,
      'min_price': minPrice ?? 0,
      'max_price': maxPrice ?? 0,
      'brand': brand ?? '',
      'brand_id': brandId ?? 0,
      'store_id': storeId ?? 0,
    });
    return md5.convert(utf8.encode(raw)).toString();
  }

  @override
  Future<Either<Failure, List<Product>>> getProducts({
    int page = 1,
    int perPage = 15,
    String? search,
    int? categoryId,
    double? minPrice,
    double? maxPrice,
    String? brand,
    int? brandId,
    int? storeId,
    bool forceRefresh = false,
  }) async {
    final isConnected = await _networkInfo.isConnected;

    final listKey = _productsListKey(
      perPage: perPage,
      search: search,
      categoryId: categoryId,
      minPrice: minPrice,
      maxPrice: maxPrice,
      brand: brand,
      brandId: brandId,
      storeId: storeId,
    );

    if (!forceRefresh && page == 1) {
      final cached = await _getCachedProductsList(listKey);
      if (cached.isNotEmpty) {
        if (isConnected) {
          unawaited(
            _fetchProducts(
              page: page,
              perPage: perPage,
              search: search,
              categoryId: categoryId,
              minPrice: minPrice,
              maxPrice: maxPrice,
              brand: brand,
              brandId: brandId,
              storeId: storeId,
              listKey: listKey,
              cacheOnly: true,
            ),
          );
        }
        return Right(cached);
      }

      if (!isConnected) {
        final isDefaultQuery =
            search == null &&
            categoryId == null &&
            storeId == null &&
            brandId == null &&
            minPrice == null &&
            maxPrice == null &&
            brand == null;
        if (isDefaultQuery) {
          return _getCachedProducts();
        }
        return const Left(NetworkFailure('No internet connection'));
      }
    } else if (!isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    return _fetchProducts(
      page: page,
      perPage: perPage,
      search: search,
      categoryId: categoryId,
      minPrice: minPrice,
      maxPrice: maxPrice,
      brand: brand,
      brandId: brandId,
      storeId: storeId,
      listKey: listKey,
    );
  }

  Future<Either<Failure, List<Product>>> _fetchProducts({
    int page = 1,
    int perPage = 15,
    String? search,
    int? categoryId,
    double? minPrice,
    double? maxPrice,
    String? brand,
    int? brandId,
    int? storeId,
    required String listKey,
    bool cacheOnly = false,
  }) async {
    try {
      final products = await _remoteDataSource.getProducts(
        page: page,
        perPage: perPage,
        search: search,
        categoryId: categoryId,
        minPrice: minPrice,
        maxPrice: maxPrice,
        brand: brand,
        brandId: brandId,
        storeId: storeId,
      );

      if (page == 1) {
        await _localDataSource.cacheProductsList(
          key: listKey,
          products: products,
        );
      }

      if (cacheOnly) return const Right([]);
      return Right(products);
    } on NetworkException {
      if (page == 1) {
        final cached = await _getCachedProductsList(listKey);
        if (cached.isNotEmpty) return Right(cached);
      }
      return const Left(NetworkFailure('No internet connection'));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure('Failed to load products: $e'));
    }
  }

  Future<List<Product>> _getCachedProductsList(String listKey) async {
    try {
      return await _localDataSource.getCachedProductsList(key: listKey);
    } catch (e) {
      return [];
    }
  }

  Future<Either<Failure, List<Product>>> _getCachedProducts() async {
    try {
      final products = await _localDataSource.getCachedProducts();
      if (products.isEmpty) {
        return const Left(
          NetworkFailure('No internet connection and no cached data'),
        );
      }
      return Right(products);
    } catch (e) {
      return Left(CacheFailure('Failed to load cached products: $e'));
    }
  }

  // ============== FEATURED PRODUCTS ==============

  @override
  Future<Either<Failure, List<Product>>> getFeaturedProducts({
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    final isConnected = await _networkInfo.isConnected;

    _dataSyncService.setFeaturedProductsLoading(true);

    if (!isConnected) {
      final result = await _getCachedFeaturedProducts();
      _dataSyncService.setFeaturedProductsLoading(false);
      return result;
    }

    if (forceRefresh) {
      await _localDataSource.setFeaturedCachedVersion('');
      _dataSyncService.resetRetryCount('featured_products');
      final result = await _fetchFeaturedProductsFromServer(limit);
      _dataSyncService.setFeaturedProductsLoading(false);
      return result;
    }

    // Stale-while-revalidate
    final cachedProducts = await _localDataSource.getCachedFeaturedProducts();

    if (cachedProducts.isNotEmpty) {
      _dataSyncService.updateFeaturedProducts(
        data: cachedProducts,
        isStale: true,
      );

      _backgroundRefreshFeaturedProducts(limit);

      _dataSyncService.setFeaturedProductsLoading(false);
      return Right(cachedProducts);
    }

    final result = await _fetchFeaturedProductsFromServer(limit);
    _dataSyncService.setFeaturedProductsLoading(false);
    return result;
  }

  Future<Either<Failure, List<Product>>> _fetchFeaturedProductsFromServer(
    int limit,
  ) async {
    try {
      final currentETag = await _localDataSource.getFeaturedCachedVersion();

      final response = await _remoteDataSource.getFeaturedProductsWithETag(
        limit: limit,
        currentETag: currentETag,
      );

      if (response.notModified) {
        final cached = await _localDataSource.getCachedFeaturedProducts();
        if (cached.isNotEmpty) {
          _dataSyncService.updateFeaturedProducts(data: cached, isStale: false);
          return Right(cached);
        }
        // Cache is empty but server returned 304 - clear ETag and refetch
        await _localDataSource.setFeaturedCachedVersion('');
        return _fetchFeaturedProductsFromServer(limit);
      }

      await _localDataSource.cacheFeaturedProducts(response.products);
      if (response.etag != null) {
        await _localDataSource.setFeaturedCachedVersion(response.etag!);
      }

      _dataSyncService.updateFeaturedProducts(
        data: response.products,
        isStale: false,
        etag: response.etag,
      );

      return Right(response.products);
    } on NetworkException {
      return _getCachedFeaturedProducts();
    } on ServerException catch (e) {
      _dataSyncService.updateFeaturedProducts(
        error: ServerFailure(e.message, statusCode: e.statusCode),
      );
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      final failure = ServerFailure('Failed to load featured products: $e');
      _dataSyncService.updateFeaturedProducts(error: failure);
      return Left(failure);
    }
  }

  Future<Either<Failure, List<Product>>> _getCachedFeaturedProducts() async {
    try {
      final products = await _localDataSource.getCachedFeaturedProducts();
      if (products.isEmpty) {
        final failure = const NetworkFailure(
          'No internet connection and no cached data',
        );
        _dataSyncService.updateFeaturedProducts(error: failure);
        return Left(failure);
      }
      _dataSyncService.updateFeaturedProducts(data: products, isStale: true);
      return Right(products);
    } catch (e) {
      final failure = CacheFailure(
        'Failed to load cached featured products: $e',
      );
      _dataSyncService.updateFeaturedProducts(error: failure);
      return Left(failure);
    }
  }

  Future<void> _backgroundRefreshFeaturedProducts(int limit) async {
    const refreshKey = 'featured_products';

    if (!_dataSyncService.shouldRefreshFeaturedProducts()) {
      return;
    }

    _dataSyncService.markFeaturedProductsRefreshStarted();

    try {
      final currentETag = await _localDataSource.getFeaturedCachedVersion();

      final response = await _remoteDataSource.getFeaturedProductsWithETag(
        limit: limit,
        currentETag: currentETag,
      );

      if (response.notModified) {
        final current = _dataSyncService.featuredProductsState;
        if (current.hasData) {
          _dataSyncService.updateFeaturedProducts(
            data: current.data,
            isStale: false,
          );
        }
        _dataSyncService.markFeaturedProductsRefreshCompleted(success: true);
        return;
      }

      await _localDataSource.cacheFeaturedProducts(response.products);
      if (response.etag != null) {
        await _localDataSource.setFeaturedCachedVersion(response.etag!);
      }

      _dataSyncService.updateFeaturedProducts(
        data: response.products,
        isStale: false,
        etag: response.etag,
      );

      _dataSyncService.markFeaturedProductsRefreshCompleted(success: true);
    } catch (e) {
      _dataSyncService.markFeaturedProductsRefreshCompleted(success: false);

      if (_dataSyncService.shouldRetry(refreshKey)) {
        final delay = _dataSyncService.getRetryDelay(refreshKey);
        Future.delayed(delay, () => _backgroundRefreshFeaturedProducts(limit));
      }
    }
  }

  // ============== SINGLE PRODUCT ==============

  @override
  Future<Either<Failure, Product>> getProductById(
    int id, {
    bool forceRefresh = false,
  }) async {
    final isConnected = await _networkInfo.isConnected;

    if (!forceRefresh) {
      try {
        final cachedProduct = await _localDataSource.getCachedProduct(id);
        if (cachedProduct != null) {
          if (isConnected) {
            unawaited(_fetchAndCacheProduct(id));
          }
          return Right(cachedProduct);
        }
      } catch (e) {
        // Ignore cache read errors and try network below
      }
    }

    if (!isConnected) {
      return const Left(
        NetworkFailure('No internet connection and product not cached'),
      );
    }

    try {
      final product = await _fetchAndCacheProduct(id);
      return Right(product);
    } on NetworkException {
      try {
        final cachedProduct = await _localDataSource.getCachedProduct(id);
        if (cachedProduct != null) {
          return Right(cachedProduct);
        }
        return const Left(NetworkFailure('No internet connection'));
      } catch (e) {
        return const Left(NetworkFailure('No internet connection'));
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure('Failed to load product: $e'));
    }
  }

  Future<Product> _fetchAndCacheProduct(int id) async {
    final product = await _remoteDataSource.getProductById(id);
    await _localDataSource.cacheProduct(product);
    return product;
  }

  // ============== OTHER QUERIES ==============

  @override
  Future<Either<Failure, List<Product>>> getProductsByCategory(
    int categoryId, {
    int page = 1,
  }) async {
    try {
      final products = await _remoteDataSource.getProductsByCategory(
        categoryId,
        page: page,
      );
      return Right(products);
    } on NetworkException {
      return const Left(NetworkFailure('No internet connection'));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure('Failed to load products: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Product>>> searchProducts(
    String query, {
    int page = 1,
  }) async {
    try {
      final products = await _remoteDataSource.searchProducts(
        query,
        page: page,
      );
      return Right(products);
    } on NetworkException {
      return const Left(NetworkFailure('No internet connection'));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure('Failed to search products: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getRelatedProducts(
    int productId, {
    int limit = 6,
  }) async {
    try {
      final products = await _remoteDataSource.getRelatedProducts(
        productId,
        limit: limit,
      );
      return Right(products);
    } on NetworkException {
      return const Left(NetworkFailure('No internet connection'));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure('Failed to load related products: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getProductsByIds(List<int> ids) async {
    if (ids.isEmpty) return const Right([]);

    final List<Product> products = [];
    final List<int> missingIds = [];

    // 1. Check local cache for each ID first
    for (final id in ids) {
      try {
        final cached = await _localDataSource.getCachedProduct(id);
        if (cached != null) {
          products.add(cached);
        } else {
          missingIds.add(id);
        }
      } catch (_) {
        missingIds.add(id);
      }
    }

    // If everything was in cache, return immediately
    if (missingIds.isEmpty) {
      // Sort to maintain requested order
      products.sort((a, b) => ids.indexOf(a.id).compareTo(ids.indexOf(b.id)));
      return Right(products);
    }

    final isConnected = await _networkInfo.isConnected;
    if (!isConnected) {
      if (products.isNotEmpty) return Right(products);
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      // 2. Fetch missing products concurrently
      final List<Future<Product>> futures = missingIds
          .map(
            (id) => getProductById(id, forceRefresh: true).then((result) {
              return result.fold(
                (failure) => throw failure,
                (product) => product,
              );
            }),
          )
          .toList();

      final List<Product> fetchedProducts = await Future.wait(futures);
      products.addAll(fetchedProducts);

      // 3. Sort to maintain the order of the requested IDs
      products.sort((a, b) => ids.indexOf(a.id).compareTo(ids.indexOf(b.id)));

      return Right(products);
    } catch (e) {
      // If we have some products (from cache), return them instead of failing completely
      if (products.isNotEmpty) {
        products.sort((a, b) => ids.indexOf(a.id).compareTo(ids.indexOf(b.id)));
        return Right(products);
      }
      return Left(ServerFailure('Failed to load wishlist products: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> suggestProducts(
    String query,
  ) async {
    final isConnected = await _networkInfo.isConnected;
    if (!isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final suggestions = await _remoteDataSource.suggestProducts(query);
      return Right(suggestions);
    } on NetworkException {
      return const Left(NetworkFailure('No internet connection'));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure('Failed to get suggestions: $e'));
    }
  }
}
