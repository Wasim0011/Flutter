import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/category_model.dart';

/// Response wrapper for categories with ETag support
class CategoriesResponse {
  final List<CategoryModel> categories;
  final bool notModified;
  final String? etag;
  
  CategoriesResponse({
    required this.categories,
    this.notModified = false,
    this.etag,
  });
}

abstract class CategoryRemoteDataSource {
  Future<List<CategoryModel>> getCategories();
  Future<CategoriesResponse> getCategoriesWithETag({String? currentETag});
  Future<List<CategoryModel>> getFeaturedCategories({int limit = 8});
  Future<CategoriesResponse> getFeaturedCategoriesWithETag({int limit = 8, String? currentETag});
  Future<CategoryModel> getCategoryById(int id);
}

class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  final ApiClient _apiClient;

  CategoryRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<CategoryModel>> getCategories() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.categories,
    );
    final data = response['data'] as List? ?? [];
    return data.map((e) => CategoryModel.fromJson(e)).toList();
  }

  @override
  Future<CategoriesResponse> getCategoriesWithETag({String? currentETag}) async {
    final response = await _apiClient.getWithETag<Map<String, dynamic>>(
      ApiEndpoints.categories,
      etag: currentETag,
    );

    if (response.notModified) {
      return CategoriesResponse(
        categories: [],
        notModified: true,
        etag: currentETag,
      );
    }

    final data = response.data?['data'] as List? ?? [];
    return CategoriesResponse(
      categories: data.map((e) => CategoryModel.fromJson(e)).toList(),
      notModified: false,
      etag: response.etag,
    );
  }

  @override
  Future<List<CategoryModel>> getFeaturedCategories({int limit = 8}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.featuredCategories,
      queryParameters: {'limit': limit},
    );
    final data = response['data'] as List? ?? [];
    return data.map((e) => CategoryModel.fromJson(e)).toList();
  }

  @override
  Future<CategoriesResponse> getFeaturedCategoriesWithETag({
    int limit = 8,
    String? currentETag,
  }) async {
    final response = await _apiClient.getWithETag<Map<String, dynamic>>(
      ApiEndpoints.featuredCategories,
      queryParameters: {'limit': limit},
      etag: currentETag,
    );

    if (response.notModified) {
      return CategoriesResponse(
        categories: [],
        notModified: true,
        etag: currentETag,
      );
    }

    final data = response.data?['data'] as List? ?? [];
    return CategoriesResponse(
      categories: data.map((e) => CategoryModel.fromJson(e)).toList(),
      notModified: false,
      etag: response.etag,
    );
  }

  @override
  Future<CategoryModel> getCategoryById(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.categoryDetails(id.toString()),
    );
    return CategoryModel.fromJson(response['data']);
  }
}
