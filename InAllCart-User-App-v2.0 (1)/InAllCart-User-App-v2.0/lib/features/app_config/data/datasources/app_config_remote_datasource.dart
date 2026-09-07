import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/app_config_model.dart';

abstract class AppConfigRemoteDataSource {
  Future<AppConfigModel> getAppConfig({double? lat, double? lng});
}

class AppConfigRemoteDataSourceImpl implements AppConfigRemoteDataSource {
  final ApiClient _apiClient;

  AppConfigRemoteDataSourceImpl(this._apiClient);

  @override
  Future<AppConfigModel> getAppConfig({double? lat, double? lng}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.appConfig,
      queryParameters: (lat != null && lng != null)
          ? {'lat': lat.toString(), 'lng': lng.toString()}
          : null,
    );
    return AppConfigModel.fromJson(response['data'] ?? response);
  }
}
