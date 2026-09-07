import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/onboarding_repository.dart';

class CompleteOnboarding {
  final OnboardingRepository repository;

  CompleteOnboarding(this.repository);

  Future<Either<Failure, void>> call() => repository.completeOnboarding();
}
