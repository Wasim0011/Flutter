import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/app_content.dart';
import '../repositories/app_content_repository.dart';

class GetAppContent {
  final AppContentRepository repository;

  GetAppContent(this.repository);

  Future<Either<Failure, List<AppContent>>> call({
    int? tabId,
    bool forceRefresh = false,
  }) {
    return repository.getAppContent(
      tabId: tabId,
      forceRefresh: forceRefresh,
    );
  }
}
