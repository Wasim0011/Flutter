import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/storage_service.dart';
import '../../../app_config/data/models/app_config_model.dart';
import '../../../app_config/domain/entities/app_config.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../datasources/onboarding_remote_datasource.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  final OnboardingRemoteDataSource _remoteDataSource;
  final StorageService _storageService;

  OnboardingRepositoryImpl(this._remoteDataSource, this._storageService);

  @override
  Future<Either<Failure, List<OnboardingScreen>>> getOnboardingScreens() async {
    try {
      final screens = await _remoteDataSource.getOnboardingScreens();
      return Right(screens);
    } on NetworkException {
      // Return default screens on network error
      return Right(AppConfigModel.defaultConfig().onboardingScreens);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } catch (e) {
      return Right(AppConfigModel.defaultConfig().onboardingScreens);
    }
  }

  @override
  Future<Either<Failure, void>> completeOnboarding() async {
    try {
      await _storageService.setOnboardingCompleted(true);
      return const Right(null);
    } catch (e) {
      return const Left(CacheFailure('Failed to save onboarding status'));
    }
  }

  @override
  bool isOnboardingCompleted() => _storageService.isOnboardingCompleted();
}
