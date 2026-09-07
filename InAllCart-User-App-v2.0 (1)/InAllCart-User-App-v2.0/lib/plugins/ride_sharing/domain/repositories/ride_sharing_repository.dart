import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/ride_sharing_entities.dart';

abstract class RideSharingRepository {
  Future<Either<Failure, List<VehicleType>>> getVehicleTypes();

  Future<Either<Failure, List<FareEstimate>>> getFareEstimates({
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    int? vehicleTypeId,
  });

  Future<Either<Failure, Ride>> bookRide({
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    required double dropoffLat,
    required double dropoffLng,
    required String dropoffAddress,
    required int vehicleTypeId,
    required String paymentMethod,
    String? promoCode,
  });

  Future<Either<Failure, Ride>> boostFare(int rideId, double boostAmount);

  Future<Either<Failure, Ride>> getRideDetails(int rideId);
  Future<Either<Failure, Ride>> trackRide(int rideId);
  Future<Either<Failure, Unit>> cancelRide(int rideId, String reason);

  Future<Either<Failure, List<PaymentMethodInfo>>> getPaymentMethods();

  Future<Either<Failure, PaymentInitData>> initializeRidePayment({
    required int rideId,
    required String paymentMethod,
    double? amount,
  });

  Future<Either<Failure, bool>> verifyRidePayment({
    required int rideId,
    required String paymentMethod,
    required String paymentId,
    Map<String, dynamic>? additionalData,
  });

  Future<Either<Failure, RideHistoryResult>> getRideHistory({int page = 1});
  Future<Either<Failure, void>> rateRide(int rideId, int rating, String? comment);
  Future<Either<Failure, void>> triggerSOS(int rideId, double latitude, double longitude, String? message);
}

/// Typed result for paginated ride history.
class RideHistoryResult {
  final List<Ride> rides;
  final bool hasMore;
  final int currentPage;

  const RideHistoryResult({
    required this.rides,
    required this.hasMore,
    required this.currentPage,
  });
}
