import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_config.dart';
import '../repositories/app_config_repository.dart';

class GetAppConfig {
  final AppConfigRepository repository;

  GetAppConfig(this.repository);

  Future<Either<Failure, AppConfig>> call() => repository.getAppConfig();
}
