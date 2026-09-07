import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/app_content.dart';

abstract class AppContentRepository {
  Future<Either<Failure, List<AppContent>>> getAppContent({
    int? tabId,
    bool forceRefresh = false,
  });

  Future<Either<Failure, List<AppContent>>> getCategoryScreenContent({
    bool forceRefresh = false,
  });
}

