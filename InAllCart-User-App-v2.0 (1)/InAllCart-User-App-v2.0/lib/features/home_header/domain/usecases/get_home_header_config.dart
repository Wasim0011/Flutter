import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/home_header_config.dart';
import '../repositories/home_header_repository.dart';

class GetHomeHeaderConfig {
  final HomeHeaderRepository repository;

  GetHomeHeaderConfig(this.repository);

  Future<Either<Failure, HomeHeaderConfig>> call({bool forceRefresh = false}) {
    return repository.getHomeHeaderConfig(forceRefresh: forceRefresh);
  }
}
