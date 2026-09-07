import 'package:flutter/foundation.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../app_config/data/models/app_config_model.dart';
import '../../../app_config/domain/entities/app_config.dart';

abstract class OnboardingRemoteDataSource {
  Future<List<OnboardingScreen>> getOnboardingScreens();
}

class OnboardingRemoteDataSourceImpl implements OnboardingRemoteDataSource {
  final ApiClient _apiClient;

  OnboardingRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<OnboardingScreen>> getOnboardingScreens() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.onboarding,
      );
      final rawList = response['data'] as List?;
      if (rawList != null && rawList.isNotEmpty) {
        final List<OnboardingScreen> screens = [];
        for (final item in rawList) {
          if (item is Map) {
            screens.add(
              OnboardingScreenModel.fromJson(Map<String, dynamic>.from(item)),
            );
          }
        }
        screens.sort((a, b) => a.order.compareTo(b.order));
        if (screens.isNotEmpty) {
          return screens;
        }
      }
    } catch (e) {
      debugPrint('[ONBOARDING_FETCH_ERROR] ${ApiEndpoints.onboarding} error: $e');
    }

    // Secondary fallback: Try ApiEndpoints.appConfig if ApiEndpoints.onboarding fails
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.appConfig,
      );
      final data = response['data'] as Map<String, dynamic>? ?? response;
      final rawList = data['onboarding_screens'] as List?;
      if (rawList != null && rawList.isNotEmpty) {
        final List<OnboardingScreen> screens = [];
        for (final item in rawList) {
          if (item is Map) {
            screens.add(
              OnboardingScreenModel.fromJson(Map<String, dynamic>.from(item)),
            );
          }
        }
        screens.sort((a, b) => a.order.compareTo(b.order));
        if (screens.isNotEmpty) {
          return screens;
        }
      }
    } catch (e) {
      debugPrint('[ONBOARDING_FETCH_ERROR] ${ApiEndpoints.appConfig} error: $e');
    }

    // Default fallback only if both network calls fail
    return AppConfigModel.defaultConfig().onboardingScreens;
  }
}
