import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/ride_sharing_entities.dart';
import '../../domain/repositories/ride_sharing_repository.dart';
import '../datasources/ride_sharing_remote_datasource.dart';
import '../models/ride_sharing_models.dart';

class RideSharingRepositoryImpl implements RideSharingRepository {
  final RideSharingRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  RideSharingRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<VehicleType>>> getVehicleTypes() async {
    if (await networkInfo.isConnected) {
      try {
        final vehicleTypes = await remoteDataSource.getVehicleTypes();
        return Right(vehicleTypes);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<FareEstimate>>> getFareEstimates({
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    int? vehicleTypeId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final params = <String, dynamic>{
          'pickup_latitude': pickupLat,
          'pickup_longitude': pickupLng,
          'dropoff_latitude': dropoffLat,
          'dropoff_longitude': dropoffLng,
        };
        if (vehicleTypeId != null) {
          params['vehicle_type_id'] = vehicleTypeId;
        }
        final estimates = await remoteDataSource.getFareEstimates(params);
        return Right(estimates);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
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
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final ride = await remoteDataSource.bookRide({
          'pickup_latitude': pickupLat,
          'pickup_longitude': pickupLng,
          'pickup_address': pickupAddress,
          'dropoff_latitude': dropoffLat,
          'dropoff_longitude': dropoffLng,
          'dropoff_address': dropoffAddress,
          'vehicle_type_id': vehicleTypeId,
          'payment_method': paymentMethod,
          if (promoCode != null && promoCode.isNotEmpty) 'promo_code': promoCode,
        });
        return Right(ride);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Ride>> boostFare(int rideId, double boostAmount) async {
    if (await networkInfo.isConnected) {
      try {
        final ride = await remoteDataSource.boostFare(rideId, boostAmount);
        return Right(ride);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Ride>> getRideDetails(int rideId) async {
    if (await networkInfo.isConnected) {
      try {
        final ride = await remoteDataSource.getRideDetails(rideId);
        return Right(ride);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Ride>> trackRide(int rideId) async {
    if (await networkInfo.isConnected) {
      try {
        final ride = await remoteDataSource.trackRide(rideId);
        return Right(ride);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Unit>> cancelRide(int rideId, String reason) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.cancelRide(rideId, reason);
        return const Right(unit);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<PaymentMethodInfo>>> getPaymentMethods() async {
    if (await networkInfo.isConnected) {
      try {
        final methods = await remoteDataSource.getPaymentMethods();
        return Right(methods);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, PaymentInitData>> initializeRidePayment({
    required int rideId,
    required String paymentMethod,
    double? amount,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final data = await remoteDataSource.initializeRidePayment(
          rideId: rideId,
          paymentMethod: paymentMethod,
          amount: amount,
        );
        return Right(data);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyRidePayment({
    required int rideId,
    required String paymentMethod,
    required String paymentId,
    Map<String, dynamic>? additionalData,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final success = await remoteDataSource.verifyRidePayment(
          rideId: rideId,
          paymentMethod: paymentMethod,
          paymentId: paymentId,
          additionalData: additionalData,
        );
        return Right(success);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, RideHistoryResult>> getRideHistory({int page = 1}) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.getRideHistory(page: page);

        // The backend returns a Laravel paginator under `data`:
        //   { success, data: { current_page, data: [...], last_page, ... } }
        // Older/alternate shapes may return `data` as a plain list with a
        // sibling `meta` block. Handle both defensively.
        final dynamic dataField = response['data'];

        List<dynamic> ridesJson;
        Map<String, dynamic> pagination;

        if (dataField is List) {
          ridesJson = dataField;
          pagination = (response['meta'] as Map<String, dynamic>?) ?? const {};
        } else if (dataField is Map<String, dynamic>) {
          ridesJson = (dataField['data'] as List?) ?? const [];
          pagination = dataField;
        } else {
          ridesJson = const [];
          pagination = const {};
        }

        final rides = ridesJson
            .map((json) => RideModel.fromJson(json as Map<String, dynamic>))
            .toList();
        final currentPage = (pagination['current_page'] as num?)?.toInt() ?? page;
        final lastPage = (pagination['last_page'] as num?)?.toInt() ?? 1;
        return Right(RideHistoryResult(
          rides: rides,
          hasMore: currentPage < lastPage,
          currentPage: currentPage,
        ));
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> rateRide(int rideId, int rating, String? comment) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.rateRide(rideId, rating, comment);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> triggerSOS(int rideId, double latitude, double longitude, String? message) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.triggerSOS(rideId, latitude, longitude, message);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }
}
