import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/referral_stats_model.dart';

abstract class ReferralRemoteDataSource {
  Future<ReferralStatsModel> getReferralStats();
  Future<String> getInviteLink();
}

class ReferralRemoteDataSourceImpl implements ReferralRemoteDataSource {
  final ApiClient _apiClient;

  ReferralRemoteDataSourceImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<ReferralStatsModel> getReferralStats() async {
    try {
      final responseData = await _apiClient.get<Map<String, dynamic>>(ApiEndpoints.referralStats);
      
      if (responseData['success'] == true) {
        return ReferralStatsModel.fromJson(responseData['data']);
      } else {
        throw Exception(responseData['message'] ?? 'Failed to get referral stats');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<String> getInviteLink() async {
    try {
      final responseData = await _apiClient.get<Map<String, dynamic>>(ApiEndpoints.inviteLink);

      if (responseData['success'] == true) {
        return responseData['data']['invite_link'] as String;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to get invite link');
      }
    } catch (e) {
      rethrow;
    }
  }
}
