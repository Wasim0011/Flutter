import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/home_header_config.dart';

abstract class HomeHeaderRepository {
  Future<Either<Failure, HomeHeaderConfig>> getHomeHeaderConfig({
    bool forceRefresh = false,
  });
}
