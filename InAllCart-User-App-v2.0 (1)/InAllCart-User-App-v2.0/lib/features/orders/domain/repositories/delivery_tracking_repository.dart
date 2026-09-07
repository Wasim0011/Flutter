import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/delivery_tracking.dart';

abstract class DeliveryTrackingRepository {
  /// Get delivery tracking data with cache-first + ETag validation
  /// This is the main method called every 10 seconds
  /// Returns cached data instantly, then validates in background
  Future<Either<Failure, DeliveryTracking>> getTrackingData({
    required int orderId,
    bool forceRefresh = false,
  });

  /// Get tracking history for route replay
  Future<Either<Failure, List<TrackingHistoryPoint>>> getTrackingHistory({
    required int orderId,
  });

  /// Clear tracking cache for an order
  Future<void> clearTrackingCache(int orderId);
}
