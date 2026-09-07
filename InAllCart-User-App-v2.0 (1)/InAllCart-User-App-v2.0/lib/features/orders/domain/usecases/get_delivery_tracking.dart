import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/delivery_tracking.dart';
import '../repositories/delivery_tracking_repository.dart';

/// Use case for getting delivery tracking data
/// Follows the same pattern as GetFeaturedProducts
class GetDeliveryTracking {
  final DeliveryTrackingRepository _repository;

  GetDeliveryTracking(this._repository);

  Future<Either<Failure, DeliveryTracking>> call({
    required int orderId,
    bool forceRefresh = false,
  }) async {
    return await _repository.getTrackingData(
      orderId: orderId,
      forceRefresh: forceRefresh,
    );
  }
}

/// Use case for getting tracking history
class GetTrackingHistory {
  final DeliveryTrackingRepository _repository;

  GetTrackingHistory(this._repository);

  Future<Either<Failure, List<TrackingHistoryPoint>>> call({
    required int orderId,
  }) async {
    return await _repository.getTrackingHistory(orderId: orderId);
  }
}
