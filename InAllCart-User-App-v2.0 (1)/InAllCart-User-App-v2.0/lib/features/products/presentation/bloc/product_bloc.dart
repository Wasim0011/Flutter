import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/data_sync_service.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/get_products.dart';
import '../../domain/usecases/get_products_by_ids.dart';

// ============== EVENTS ==============

abstract class ProductEvent extends Equatable {
  const ProductEvent();
  @override
  List<Object?> get props => [];
}

class LoadProducts extends ProductEvent {
  final int page;
  final String? search;
  final int? categoryId;
  final int? storeId;
  final int? brandId;
  final bool forceRefresh;

  const LoadProducts({
    this.page = 1,
    this.search,
    this.categoryId,
    this.storeId,
    this.brandId,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [
    page,
    search,
    categoryId,
    storeId,
    brandId,
    forceRefresh,
  ];
}

class LoadFeaturedProducts extends ProductEvent {
  final int limit;
  final bool forceRefresh;
  const LoadFeaturedProducts({this.limit = 10, this.forceRefresh = false});

  @override
  List<Object?> get props => [limit, forceRefresh];
}

class LoadProductDetails extends ProductEvent {
  final int productId;
  const LoadProductDetails(this.productId);

  @override
  List<Object?> get props => [productId];
}

class LoadSimilarProducts extends ProductEvent {
  final int categoryId;
  final int excludeProductId;
  const LoadSimilarProducts({
    required this.categoryId,
    required this.excludeProductId,
  });

  @override
  List<Object?> get props => [categoryId, excludeProductId];
}

class SearchProductsEvent extends ProductEvent {
  final String query;
  const SearchProductsEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class LoadMoreProducts extends ProductEvent {}

class LoadProductsByIds extends ProductEvent {
  final List<int> ids;
  const LoadProductsByIds(this.ids);
  @override
  List<Object?> get props => [ids];
}

class RefreshProducts extends ProductEvent {}

/// Internal event triggered by stream updates
class _StreamDataUpdated extends ProductEvent {
  final List<Product> products;
  final bool isStale;
  const _StreamDataUpdated(this.products, {this.isStale = false});

  @override
  List<Object?> get props => [products, isStale];
}

class _ProductsRefreshed extends ProductEvent {
  final String queryKey;
  final List<Product> products;

  const _ProductsRefreshed({required this.queryKey, required this.products});

  @override
  List<Object?> get props => [queryKey, products];
}

// ============== STATES ==============

abstract class ProductState extends Equatable {
  const ProductState();
  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductsLoaded extends ProductState {
  final List<Product> products;
  final bool hasMore;
  final int currentPage;

  const ProductsLoaded({
    required this.products,
    this.hasMore = true,
    this.currentPage = 1,
  });

  @override
  List<Object?> get props => [products, hasMore, currentPage];

  ProductsLoaded copyWith({
    List<Product>? products,
    bool? hasMore,
    int? currentPage,
  }) {
    return ProductsLoaded(
      products: products ?? this.products,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class FeaturedProductsLoaded extends ProductState {
  final List<Product> products;
  final DateTime loadedAt;
  final bool isStale;

  FeaturedProductsLoaded(this.products, {this.isStale = false})
    : loadedAt = DateTime.now();

  @override
  List<Object?> get props => [products, loadedAt, isStale];
}

class ProductDetailsLoaded extends ProductState {
  final Product product;
  final List<Product>? similarProducts;

  const ProductDetailsLoaded(this.product, {this.similarProducts});

  @override
  List<Object?> get props => [product, similarProducts];

  ProductDetailsLoaded copyWith({
    Product? product,
    List<Product>? similarProducts,
  }) {
    return ProductDetailsLoaded(
      product ?? this.product,
      similarProducts: similarProducts ?? this.similarProducts,
    );
  }
}

class ProductError extends ProductState {
  final String message;

  const ProductError(this.message);

  @override
  List<Object?> get props => [message];
}

// ============== PRODUCT BLOC (General) ==============

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetProducts _getProducts;
  final GetFeaturedProducts _getFeaturedProducts;
  final GetProductById _getProductById;
  final SearchProducts _searchProducts;
  final GetProductsByIds _getProductsByIds;

  String? _currentSearch;
  int? _currentCategoryId;
  int? _currentStoreId;
  int? _currentBrandId;
  String? _activeProductsQueryKey;

  ProductBloc(
    this._getProducts,
    this._getFeaturedProducts,
    this._getProductById,
    this._searchProducts,
    this._getProductsByIds,
  ) : super(ProductInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<_ProductsRefreshed>(_onProductsRefreshed);
    on<LoadFeaturedProducts>(_onLoadFeaturedProducts);
    on<LoadProductDetails>(_onLoadProductDetails);
    on<LoadSimilarProducts>(_onLoadSimilarProducts);
    on<SearchProductsEvent>(_onSearchProducts);
    on<LoadMoreProducts>(_onLoadMoreProducts);
    on<LoadProductsByIds>(_onLoadProductsByIds);
    on<RefreshProducts>(_onRefreshProducts);
  }

  Future<void> _onLoadProducts(
    LoadProducts event,
    Emitter<ProductState> emit,
  ) async {
    final queryKey =
        '${event.page}_${event.search}_${event.categoryId}_${event.storeId}_${event.brandId}';
    _activeProductsQueryKey = queryKey;

    final loadingTimer = Timer(const Duration(milliseconds: 140), () {
      if (isClosed) return;
      emit(ProductLoading());
    });

    _currentSearch = event.search;
    _currentCategoryId = event.categoryId;
    _currentStoreId = event.storeId;
    _currentBrandId = event.brandId;

    final result = await _getProducts(
      page: event.page,
      search: event.search,
      categoryId: event.categoryId,
      storeId: event.storeId,
      brandId: event.brandId,
      forceRefresh: event.forceRefresh,
    );

    loadingTimer.cancel();

    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (products) => emit(
        ProductsLoaded(
          products: products,
          hasMore: products.length >= 15,
          currentPage: event.page,
        ),
      ),
    );

    if (!event.forceRefresh && event.page == 1) {
      unawaited(
        _getProducts(
          page: 1,
          search: event.search,
          categoryId: event.categoryId,
          storeId: event.storeId,
          brandId: event.brandId,
          forceRefresh: true,
        ).then((fresh) {
          if (isClosed) return;
          fresh.fold((_) {}, (freshProducts) {
            add(
              _ProductsRefreshed(queryKey: queryKey, products: freshProducts),
            );
          });
        }),
      );
    }
  }

  void _onProductsRefreshed(
    _ProductsRefreshed event,
    Emitter<ProductState> emit,
  ) {
    if (_activeProductsQueryKey != event.queryKey) return;
    final current = state;
    if (current is! ProductsLoaded) return;
    if (current.currentPage != 1) return;

    final oldIds = current.products.map((e) => e.id).join(',');
    final newIds = event.products.map((e) => e.id).join(',');
    if (oldIds == newIds) return;

    emit(
      current.copyWith(
        products: event.products,
        hasMore: event.products.length >= 15,
        currentPage: 1,
      ),
    );
  }

  Future<void> _onLoadFeaturedProducts(
    LoadFeaturedProducts event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());

    final result = await _getFeaturedProducts(limit: event.limit);

    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (products) => emit(FeaturedProductsLoaded(products)),
    );
  }

  Future<void> _onLoadProductDetails(
    LoadProductDetails event,
    Emitter<ProductState> emit,
  ) async {
    final loadingTimer = Timer(const Duration(milliseconds: 140), () {
      if (isClosed) return;
      if (!emit.isDone) emit(ProductLoading());
    });

    final result = await _getProductById(event.productId, forceRefresh: false);
    loadingTimer.cancel();

    if (result.isLeft()) {
      final failure = result.fold((l) => l, (r) => null)!;
      if (!emit.isDone) emit(ProductError(failure.message));
      return;
    }

    final product = result.fold((l) => null, (r) => r)!;
    if (!emit.isDone) emit(ProductDetailsLoaded(product));

    final freshResult = await _getProductById(event.productId, forceRefresh: true);
    if (isClosed || emit.isDone) return;
    freshResult.fold((_) {}, (freshProduct) {
      final current = state;
      if (current is! ProductDetailsLoaded) return;
      final oldSig =
          '${current.product.updatedAt?.millisecondsSinceEpoch}_${current.product.images.length}_${current.product.description.full?.length ?? 0}_${current.product.variants.length}';
      final newSig =
          '${freshProduct.updatedAt?.millisecondsSinceEpoch}_${freshProduct.images.length}_${freshProduct.description.full?.length ?? 0}_${freshProduct.variants.length}';
      if (oldSig == newSig) return;
      if (!emit.isDone) emit(current.copyWith(product: freshProduct));
    });
  }

  Future<void> _onLoadSimilarProducts(
    LoadSimilarProducts event,
    Emitter<ProductState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProductDetailsLoaded) return;

    // Load products from the same category
    final result = await _getProducts(page: 1, categoryId: event.categoryId);

    await result.fold(
      (failure) async {
        // On failure, try fallback to featured products
        final featuredResult = await _getFeaturedProducts(limit: 10);
        featuredResult.fold(
          (_) {},
          (featured) {
            final fallback = featured.where((p) => p.id != event.excludeProductId).take(10).toList();
            emit(currentState.copyWith(similarProducts: fallback));
          },
        );
      },
      (products) async {
        // Filter out the current product and limit to 10
        final list = products
            .where((p) => p.id != event.excludeProductId)
            .take(10)
            .toList();

        if (list.isEmpty) {
          // Fallback to featured products if no products in same category
          final featuredResult = await _getFeaturedProducts(limit: 10);
          featuredResult.fold(
            (_) {
              emit(currentState.copyWith(similarProducts: []));
            },
            (featured) {
              final fallback = featured.where((p) => p.id != event.excludeProductId).take(10).toList();
              emit(currentState.copyWith(similarProducts: fallback));
            },
          );
        } else {
          emit(currentState.copyWith(similarProducts: list));
        }
      },
    );
  }

  Future<void> _onSearchProducts(
    SearchProductsEvent event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    _currentSearch = event.query;

    final result = await _searchProducts(event.query);

    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (products) => emit(
        ProductsLoaded(
          products: products,
          hasMore: products.length >= 15,
          currentPage: 1,
        ),
      ),
    );
  }

  Future<void> _onLoadMoreProducts(
    LoadMoreProducts event,
    Emitter<ProductState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProductsLoaded || !currentState.hasMore) return;

    final nextPage = currentState.currentPage + 1;
    final result = await _getProducts(
      page: nextPage,
      search: _currentSearch,
      categoryId: _currentCategoryId,
      storeId: _currentStoreId,
      brandId: _currentBrandId,
    );

    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (newProducts) => emit(
        currentState.copyWith(
          products: [...currentState.products, ...newProducts],
          hasMore: newProducts.length >= 15,
          currentPage: nextPage,
        ),
      ),
    );
  }

  Future<void> _onRefreshProducts(
    RefreshProducts event,
    Emitter<ProductState> emit,
  ) async {
    add(
      LoadProducts(
        search: _currentSearch,
        categoryId: _currentCategoryId,
        storeId: _currentStoreId,
        brandId: _currentBrandId,
      ),
    );
  }

  Future<void> _onLoadProductsByIds(
    LoadProductsByIds event,
    Emitter<ProductState> emit,
  ) async {
    if (event.ids.isEmpty) {
      emit(const ProductsLoaded(products: [], hasMore: false));
      return;
    }

    emit(ProductLoading());
    final result = await _getProductsByIds(event.ids);
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (products) => emit(ProductsLoaded(products: products, hasMore: false)),
    );
  }
}

// ============== FEATURED PRODUCTS BLOC (Home Page) ==============

/// MNC-level FeaturedProductsBloc with reactive stream subscription
///
/// Architecture:
/// - Subscribes to DataSyncService streams for real-time updates
/// - Automatic UI updates when background refresh completes
/// - Proper cleanup on dispose
/// - Stale data indication for UX
class FeaturedProductsBloc extends Bloc<ProductEvent, ProductState> {
  final GetFeaturedProducts _getFeaturedProducts;
  final DataSyncService _dataSyncService;

  StreamSubscription<DataState<List<Product>>>? _streamSubscription;
  String? _lastDataHash;

  FeaturedProductsBloc(this._getFeaturedProducts)
    : _dataSyncService = DataSyncService(),
      super(ProductInitial()) {
    on<LoadFeaturedProducts>(_onLoadFeaturedProducts);
    on<_StreamDataUpdated>(_onStreamDataUpdated);

    _subscribeToStream();
  }

  String _generateDataHash(List<Product> products) {
    final buffer = StringBuffer();
    for (final p in products) {
      buffer.write(
        '${p.id}_${p.name}_${p.price.amount}_${p.imageUrl}_${p.flags.isFeatured}_',
      );
    }
    return buffer.toString().hashCode.toString();
  }

  void _subscribeToStream() {
    _streamSubscription?.cancel();

    _streamSubscription = _dataSyncService.featuredProductsStream
        .distinct((prev, curr) {
          if (!prev.hasData || !curr.hasData) return false;
          return _generateDataHash(prev.data!) ==
                  _generateDataHash(curr.data!) &&
              prev.isStale == curr.isStale;
        })
        .listen((dataState) {
          if (dataState.hasData && !isClosed) {
            final newHash = _generateDataHash(dataState.data!);

            if (_lastDataHash != newHash ||
                (state is FeaturedProductsLoaded &&
                    (state as FeaturedProductsLoaded).isStale !=
                        dataState.isStale)) {
              _lastDataHash = newHash;
              add(
                _StreamDataUpdated(dataState.data!, isStale: dataState.isStale),
              );
            }
          }
        });
  }

  Future<void> _onLoadFeaturedProducts(
    LoadFeaturedProducts event,
    Emitter<ProductState> emit,
  ) async {
    if (state is! FeaturedProductsLoaded) {
      emit(ProductLoading());
    }

    final result = await _getFeaturedProducts(
      limit: event.limit,
      forceRefresh: event.forceRefresh,
    );

    result.fold((failure) => emit(ProductError(failure.message)), (products) {
      _lastDataHash = _generateDataHash(products);
      emit(FeaturedProductsLoaded(products));
    });
  }

  void _onStreamDataUpdated(
    _StreamDataUpdated event,
    Emitter<ProductState> emit,
  ) {
    emit(FeaturedProductsLoaded(event.products, isStale: event.isStale));
  }

  @override
  Future<void> close() {
    _streamSubscription?.cancel();
    return super.close();
  }
}
