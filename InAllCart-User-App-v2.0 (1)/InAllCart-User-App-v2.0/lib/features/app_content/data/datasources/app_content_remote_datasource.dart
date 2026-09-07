import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/app_content_model.dart';

abstract class AppContentRemoteDataSource {
  Future<AppContentResponse> getAppContent({int? tabId, String? currentETag});
  Future<AppContentResponse> getCategoryScreenContent({String? currentETag});
}

class AppContentRemoteDataSourceImpl implements AppContentRemoteDataSource {
  final ApiClient _apiClient;
  static const String _endpoint = '${ApiEndpoints.apiPrefix}/config/app-content';
  static const String _categoryScreenEndpoint = '${ApiEndpoints.apiPrefix}/config/category-screen-content';

  AppContentRemoteDataSourceImpl(this._apiClient);

  @override
  Future<AppContentResponse> getAppContent({int? tabId, String? currentETag}) async {
    final queryParams = <String, String>{};
    if (tabId != null) queryParams['tab_id'] = tabId.toString();

    final response = await _apiClient.getWithETag<Map<String, dynamic>>(
      _endpoint,
      queryParameters: queryParams,
      etag: currentETag,
    );

    if (response.notModified) {
      return AppContentResponse(notModified: true, etag: currentETag);
    }

    final data = response.data?['data'] as List? ?? [];
    final contents = data.map((json) => AppContentModel.fromJson(json)).toList();

    return AppContentResponse(
      contents: contents,
      notModified: false,
      etag: response.etag,
    );
  }

  @override
  Future<AppContentResponse> getCategoryScreenContent({String? currentETag}) async {
    final response = await _apiClient.getWithETag<Map<String, dynamic>>(
      _categoryScreenEndpoint,
      etag: currentETag,
    );

    if (response.notModified) {
      return AppContentResponse(notModified: true, etag: currentETag);
    }

    final data = response.data?['data'] as List? ?? [];
    final contents = data.map((json) => AppContentModel.fromJson(json)).toList();

    return AppContentResponse(
      contents: contents,
      notModified: false,
      etag: response.etag,
    );
  }
}

class AppContentResponse {
  final List<AppContentModel>? contents;
  final bool notModified;
  final String? etag;

  AppContentResponse({this.contents, required this.notModified, this.etag});
}

