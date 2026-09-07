import 'package:flutter/foundation.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/popup_model.dart';

abstract class PopupRemoteDataSource {
  Future<List<PopupModel>> getActivePopups();
}

class PopupRemoteDataSourceImpl implements PopupRemoteDataSource {
  final ApiClient _apiClient;

  PopupRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<PopupModel>> getActivePopups() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.popups,
      );
      final rawList = response['data'] as List?;
      if (rawList != null && rawList.isNotEmpty) {
        final List<PopupModel> popups = [];
        for (final item in rawList) {
          if (item is Map) {
            popups.add(
              PopupModel.fromJson(Map<String, dynamic>.from(item)),
            );
          }
        }
        popups.sort((a, b) => b.priority.compareTo(a.priority));
        return popups;
      }
      return [];
    } catch (e) {
      debugPrint('[POPUP_FETCH_ERROR] ApiEndpoints.popups error: $e');
      return [];
    }
  }
}
