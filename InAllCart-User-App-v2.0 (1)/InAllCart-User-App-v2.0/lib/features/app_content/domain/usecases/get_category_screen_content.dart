import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/app_content.dart';
import '../repositories/app_content_repository.dart';

class GetCategoryScreenContent {
  final AppContentRepository repository;

  GetCategoryScreenContent(this.repository);

  Future<Either<Failure, List<AppContent>>> call({
    bool forceRefresh = false,
  }) {
    return repository.getCategoryScreenContent(
      forceRefresh: forceRefresh,
    );
  }
}
