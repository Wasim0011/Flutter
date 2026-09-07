import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/home_header_config_model.dart';

abstract class HomeHeaderRemoteDataSource {
  Future<HomeHeaderConfigModel> getHomeHeaderConfig();
  Future<HomeHeaderResponse> getHomeHeaderConfigWithETag({String? currentETag});
}

class HomeHeaderRemoteDataSourceImpl implements HomeHeaderRemoteDataSource {
  final ApiClient _apiClient;
  static const String _endpoint = '${ApiEndpoints.apiPrefix}/config/home-header';

  HomeHeaderRemoteDataSourceImpl(this._apiClient);

  @override
  Future<HomeHeaderConfigModel> getHomeHeaderConfig() async {
    final response = await _apiClient.get<Map<String, dynamic>>(_endpoint);
    return HomeHeaderConfigModel.fromJson(response['data'] ?? {});
  }

  @override
  Future<HomeHeaderResponse> getHomeHeaderConfigWithETag({String? currentETag}) async {
    final response = await _apiClient.getWithETag<Map<String, dynamic>>(
      _endpoint,
      etag: currentETag,
    );

    if (response.notModified) {
      return HomeHeaderResponse(notModified: true, etag: currentETag);
    }

    return HomeHeaderResponse(
      config: HomeHeaderConfigModel.fromJson(response.data?['data'] ?? {}),
      notModified: false,
      etag: response.etag,
    );
  }
}
