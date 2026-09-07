import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../app_config/domain/entities/app_config.dart';
import '../repositories/onboarding_repository.dart';

class GetOnboardingScreens {
  final OnboardingRepository repository;

  GetOnboardingScreens(this.repository);

  Future<Either<Failure, List<OnboardingScreen>>> call() =>
      repository.getOnboardingScreens();
}
