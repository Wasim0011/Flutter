import 'package:flutter/foundation.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/product_model.dart';

/// Response wrapper for products with ETag support
class ProductsResponse {
  final List<ProductModel> products;
  final bool notModified;
  final String? etag;

  ProductsResponse({
    required this.products,
    this.notModified = false,
    this.etag,
  });
}

abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> getProducts({
    int page = 1,
    int perPage = 15,
    String? search,
    int? categoryId,
    double? minPrice,
    double? maxPrice,
    String? brand,
    int? brandId,
    List<int>? ids,
    int? storeId,
  });

  /// Get products with ETag support for cache validation
  Future<ProductsResponse> getProductsWithETag({
    int page = 1,
    int perPage = 15,
    String? currentETag,
  });

  Future<List<ProductModel>> getFeaturedProducts({int limit = 10});

  /// Get featured products with ETag support for cache validation
  Future<ProductsResponse> getFeaturedProductsWithETag({
    int limit = 10,
    String? currentETag,
  });

  Future<ProductModel> getProductById(int id);

  Future<List<ProductModel>> getProductsByCategory(int categoryId, {int page = 1});

  Future<List<ProductModel>> searchProducts(String query, {int page = 1});

  Future<List<ProductModel>> getRelatedProducts(int productId, {int limit = 6});

  Future<List<ProductModel>> getProductsByIds(List<int> ids);

  Future<Map<String, dynamic>> suggestProducts(String query);
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final ApiClient _apiClient;

  ProductRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<ProductModel>> getProducts({
    int page = 1,
    int perPage = 15,
    String? search,
    int? categoryId,
    double? minPrice,
    double? maxPrice,
    String? brand,
    int? brandId,
    List<int>? ids,
    int? storeId,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (search != null) 'search': search,
      if (categoryId != null) 'category_id': categoryId,
      if (minPrice != null) 'min_price': minPrice,
      if (maxPrice != null) 'max_price': maxPrice,
      if (brand != null) 'brand': brand,
      if (brandId != null) 'brand_id': brandId,
      if (ids != null && ids.isNotEmpty) 'ids': ids,
      if (storeId != null) 'store_id': storeId,
    };

    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.products,
      queryParameters: queryParams,
    );

    final data = response['data'] as List? ?? [];
    _debugLogSampleProduct('getProducts (category_id=$categoryId)', data);
    return data.map((e) => ProductModel.fromJson(e)).toList();
  }

  @override
  Future<List<ProductModel>> getProductsByIds(List<int> ids) async {
    if (ids.isEmpty) return [];

    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.products,
      queryParameters: {'ids': ids},
    );

    final data = response['data'] as List? ?? [];
    return data.map((e) => ProductModel.fromJson(e)).toList();
  }

  @override
  Future<ProductsResponse> getProductsWithETag({
    int page = 1,
    int perPage = 15,
    String? currentETag,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };

    final response = await _apiClient.getWithETag<Map<String, dynamic>>(
      ApiEndpoints.products,
      queryParameters: queryParams,
      etag: currentETag,
    );

    // If not modified, return empty list with flag
    if (response.notModified) {
      return ProductsResponse(
        products: [],
        notModified: true,
        etag: currentETag,
      );
    }

    final data = response.data?['data'] as List? ?? [];
    return ProductsResponse(
      products: data.map((e) => ProductModel.fromJson(e)).toList(),
      notModified: false,
      etag: response.etag,
    );
  }

  @override
  Future<List<ProductModel>> getFeaturedProducts({int limit = 10}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.featuredProducts,
      queryParameters: {'limit': limit},
    );

    final data = response['data'] as List? ?? [];
    return data.map((e) => ProductModel.fromJson(e)).toList();
  }

  @override
  Future<ProductsResponse> getFeaturedProductsWithETag({
    int limit = 10,
    String? currentETag,
  }) async {
    final response = await _apiClient.getWithETag<Map<String, dynamic>>(
      ApiEndpoints.featuredProducts,
      queryParameters: {'limit': limit},
      etag: currentETag,
    );

    if (response.notModified) {
      return ProductsResponse(
        products: [],
        notModified: true,
        etag: currentETag,
      );
    }

    final data = response.data?['data'] as List? ?? [];
    return ProductsResponse(
      products: data.map((e) => ProductModel.fromJson(e)).toList(),
      notModified: false,
      etag: response.etag,
    );
  }

  @override
  Future<ProductModel> getProductById(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.productDetails(id.toString()),
    );

    return ProductModel.fromJson(response['data']);
  }

  @override
  Future<List<ProductModel>> getProductsByCategory(int categoryId, {int page = 1}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.productsByCategory(categoryId.toString()),
      queryParameters: {'page': page},
    );

    final data = response['data'] as List? ?? [];
    _debugLogSampleProduct('getProductsByCategory ($categoryId)', data);
    return data.map((e) => ProductModel.fromJson(e)).toList();
  }

  @override
  Future<List<ProductModel>> searchProducts(String query, {int page = 1}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.searchProducts,
      queryParameters: {'q': query, 'page': page},
    );

    final data = response['data'] as List? ?? [];
    return data.map((e) => ProductModel.fromJson(e)).toList();
  }

  @override
  Future<List<ProductModel>> getRelatedProducts(int productId, {int limit = 6}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.relatedProducts(productId.toString()),
      queryParameters: {'limit': limit},
    );

    final data = response['data'] as List? ?? [];
    return data.map((e) => ProductModel.fromJson(e)).toList();
  }

  @override
  Future<Map<String, dynamic>> suggestProducts(String query) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${ApiEndpoints.products}/suggest',
      queryParameters: {'q': query},
    );

    return response['data'] as Map<String, dynamic>;
  }

  /// Sub-task 6 diagnostics: prints the raw, unparsed JSON for the first
  /// product returned by a listing endpoint, straight from the API - before
  /// ProductModel.fromJson touches it. This is the only reliable way to see
  /// exactly which image-related field (if any) the category/listing
  /// endpoint actually sends, since the product-detail endpoint is known to
  /// work but the listing endpoint is not. Debug builds only; safe to leave
  /// in the codebase.
  void _debugLogSampleProduct(String source, List data) {
    if (!kDebugMode || data.isEmpty) return;
    try {
      final sample = data.first;
      if (sample is! Map) {
        debugPrint('[ProductAPI:$source] sample is not a Map: ${sample.runtimeType}');
        return;
      }
      final tag = '[ProductAPI:$source]';
      // Print the full top-level key list first - short, always survives.
      debugPrint('$tag top-level keys: ${sample.keys.toList()}');

      // Then print only keys that look image-related, plus their raw value.
      // This is deliberately narrow (vs dumping the whole JSON) because the
      // full product payload is large enough that logcat silently drops
      // lines under load ("chatty" throttling) - this targeted version is
      // short enough to always make it through intact.
      const needles = ['image', 'photo', 'thumb', 'media', 'gallery', 'picture', 'icon', 'cover', 'file', 'url', 'path'];
      sample.forEach((key, value) {
        final lower = key.toString().toLowerCase();
        if (needles.any((n) => lower.contains(n))) {
          debugPrint('$tag $key = $value');
        }
      });
      debugPrint('$tag ----- end -----');
    } catch (e) {
      debugPrint('[ProductAPI:$source] failed to log sample product: $e');
    }
  }
}