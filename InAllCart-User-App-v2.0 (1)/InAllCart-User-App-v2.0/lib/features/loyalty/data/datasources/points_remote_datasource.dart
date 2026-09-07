
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/points_model.dart';

abstract class PointsRemoteDataSource {
  Future<PointsModel> getBalance();
  Future<List<PointTransactionModel>> getHistory();
  Future<Map<String, dynamic>> redeemPoints(int points);
}

class PointsRemoteDataSourceImpl implements PointsRemoteDataSource {
  final ApiClient apiClient;

  PointsRemoteDataSourceImpl(this.apiClient);

  @override
  Future<PointsModel> getBalance() async {
    final response = await apiClient.get(ApiEndpoints.points);
    return PointsModel.fromJson(response['data']);
  }

  @override
  Future<List<PointTransactionModel>> getHistory() async {
    final response = await apiClient.get(ApiEndpoints.pointsHistory);
    final data = response['data']['data'] as List? ?? [];
    return data.map((e) => PointTransactionModel.fromJson(e)).toList();
  }

  @override
  Future<Map<String, dynamic>> redeemPoints(int points) async {
    final response = await apiClient.post(ApiEndpoints.pointsRedeem, data: {
      'points': points,
    });
    return response['data'] as Map<String, dynamic>;
  }
}
