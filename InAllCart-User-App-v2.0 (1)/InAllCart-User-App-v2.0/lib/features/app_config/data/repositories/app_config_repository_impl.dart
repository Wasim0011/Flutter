import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/storage_service.dart';
import '../../domain/entities/app_config.dart';
import '../../domain/repositories/app_config_repository.dart';
import '../datasources/app_config_remote_datasource.dart';
import '../models/app_config_model.dart';

class AppConfigRepositoryImpl implements AppConfigRepository {
  final AppConfigRemoteDataSource _remoteDataSource;
  final StorageService _storageService;
  AppConfigModel? _cachedConfig;

  AppConfigRepositoryImpl(this._remoteDataSource, this._storageService);

  @override
  Future<Either<Failure, AppConfig>> getAppConfig() async {
    try {
      // Always fetch fresh — location may have changed, zone currency must be current
      final location = _storageService.getLocation();
      final lat = location?['lat'];
      final lng = location?['lng'];

      final config = await _remoteDataSource.getAppConfig(lat: lat, lng: lng);
      _cachedConfig = config;
      await cacheAppConfig(config);
      return Right(config);
    } on NetworkException {
      // Only fall back to cache when truly offline
      final cached = getCachedAppConfig();
      if (cached != null) return Right(cached);
      return const Left(NetworkFailure('No internet connection'));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      final cached = getCachedAppConfig();
      if (cached != null) return Right(cached);
      final defaultConfig = AppConfigModel.defaultConfig();
      _cachedConfig = defaultConfig;
      return Right(defaultConfig);
    }
  }

  @override
  Future<Either<Failure, void>> cacheAppConfig(AppConfig config) async {
    try {
      final model = config is AppConfigModel
          ? config
          : AppConfigModel(
              currencyConfig: config.currencyConfig,
              timezoneConfig: config.timezoneConfig,
              onboardingEnabled: config.onboardingEnabled,
              onboardingScreens: config.onboardingScreens,
              mapProvider: config.mapProvider,
              googleMapsApiKey: config.googleMapsApiKey,
              pushNotificationConfig: config.pushNotificationConfig,
              appName: config.appName,
              appVersion: config.appVersion,
              supportEmail: config.supportEmail,
              supportPhone: config.supportPhone,
            );
      await _storageService.setAppConfig(model.toJson());
      return const Right(null);
    } catch (e) {
      return const Left(CacheFailure('Failed to cache config'));
    }
  }

  @override
  AppConfig? getCachedAppConfig() {
    if (_cachedConfig != null) return _cachedConfig;

    final cached = _storageService.getAppConfig();
    if (cached != null) {
      _cachedConfig = AppConfigModel.fromJson(cached);
      return _cachedConfig;
    }
    return null;
  }
}
