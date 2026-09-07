import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/static_page_model.dart';

abstract class StaticPagesRemoteDataSource {
  Future<List<StaticPageModel>> getPages();
}

class StaticPagesRemoteDataSourceImpl implements StaticPagesRemoteDataSource {
  final ApiClient _apiClient;

  StaticPagesRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<StaticPageModel>> getPages() async {
    final response = await _apiClient.get(ApiEndpoints.configPages);
    final data = response['data'] as List;
    return data
        .map((e) => StaticPageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
