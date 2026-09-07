import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_config.dart';

abstract class AppConfigRepository {
  Future<Either<Failure, AppConfig>> getAppConfig();
  Future<Either<Failure, void>> cacheAppConfig(AppConfig config);
  AppConfig? getCachedAppConfig();
}
