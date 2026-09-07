import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../app_config/domain/entities/app_config.dart';

abstract class OnboardingRepository {
  Future<Either<Failure, List<OnboardingScreen>>> getOnboardingScreens();
  Future<Either<Failure, void>> completeOnboarding();
  bool isOnboardingCompleted();
}
