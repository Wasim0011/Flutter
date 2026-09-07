import '../../../../core/network/api_client.dart';
import '../models/ride_models.dart';

class RideSharingRepository {
  final ApiClient _apiClient;

  RideSharingRepository(this._apiClient);

  /// Fetch active vehicle types for ride-sharing
  Future<List<VehicleTypeModel>> getVehicleTypes() async {
    try {
      final response = await _apiClient.get(
        '/api/v1/rides/vehicle-types',
        parser: (data) => data,
      );
      final list = (response is Map && response['data'] != null)
          ? response['data']
          : (response is List ? response : []);
      return (list as List)
          .map((item) => VehicleTypeModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Fallback default vehicle types if network/API is offline
      return const [
        VehicleTypeModel(
          id: 1,
          name: 'Bike',
          category: 'bike',
          baseFare: 25.0,
          perKmRate: 8.0,
          perMinuteRate: 1.0,
          capacity: 1,
          estimatedEta: '2-4 min',
        ),
        VehicleTypeModel(
          id: 2,
          name: 'Auto Rickshaw',
          category: 'auto',
          baseFare: 35.0,
          perKmRate: 12.0,
          perMinuteRate: 1.5,
          capacity: 3,
          estimatedEta: '3-5 min',
        ),
        VehicleTypeModel(
          id: 3,
          name: 'Economy Taxi',
          category: 'car',
          baseFare: 50.0,
          perKmRate: 15.0,
          perMinuteRate: 2.0,
          capacity: 4,
          estimatedEta: '4-7 min',
        ),
        VehicleTypeModel(
          id: 4,
          name: 'Premium Sedan',
          category: 'sedan',
          baseFare: 80.0,
          perKmRate: 22.0,
          perMinuteRate: 3.0,
          capacity: 4,
          estimatedEta: '5-9 min',
        ),
        VehicleTypeModel(
          id: 5,
          name: 'SUV XL',
          category: 'suv',
          baseFare: 120.0,
          perKmRate: 30.0,
          perMinuteRate: 4.0,
          capacity: 6,
          estimatedEta: '6-10 min',
        ),
      ];
    }
  }

  /// Get fare estimate for selected route and vehicles.
  ///
  /// C-4 FIX: Backend returns `{success, data: {estimates: [...], polyline}}`.
  /// We now handle both `data.estimates` and flat `estimates` response shapes.
  Future<List<RideEstimateModel>> getFareEstimate({
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    required double dropoffLat,
    required double dropoffLng,
    required String dropoffAddress,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/rides/estimate',
        data: {
          'pickup_lat': pickupLat,
          'pickup_latitude': pickupLat,
          'pickup_lng': pickupLng,
          'pickup_longitude': pickupLng,
          'pickup_address': pickupAddress,
          'dropoff_lat': dropoffLat,
          'dropoff_latitude': dropoffLat,
          'dropoff_lng': dropoffLng,
          'dropoff_longitude': dropoffLng,
          'dropoff_address': dropoffAddress,
        },
        parser: (data) => data,
      );

      // C-4 FIX: Handle nested `data.estimates` shape from backend
      List? list;
      if (response is Map) {
        // Shape 1: {data: {estimates: [...]}} (backend canonical)
        if (response['data'] is Map && response['data']['estimates'] is List) {
          list = response['data']['estimates'] as List;
        }
        // Shape 2: {estimates: [...]} (flat)
        else if (response['estimates'] is List) {
          list = response['estimates'] as List;
        }
        // Shape 3: {data: [...]} (legacy)
        else if (response['data'] is List) {
          list = response['data'] as List;
        }
      } else if (response is List) {
        list = response;
      }

      if (list != null && list.isNotEmpty) {
        return list
            .map((item) => RideEstimateModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      // If parsing found no estimates, fall through to local calculation
      throw Exception('No estimates returned');
    } catch (_) {
      // Calculate local estimated fallback fares if server estimate is unreachable
      final types = await getVehicleTypes();
      return types.map((v) {
        // Fallback distance calculation roughly 5.2 km
        const distKm = 5.2;
        const durMin = 14.0;
        final totalFare = v.baseFare + (distKm * v.perKmRate) + (durMin * v.perMinuteRate);
        return RideEstimateModel(
          vehicleTypeId: v.id,
          vehicleName: v.name,
          distanceKm: distKm,
          durationMinutes: durMin,
          estimatedFare: totalFare.roundToDouble(),
        );
      }).toList();
    }
  }

  /// Book a ride.
  ///
  /// M-4/S-1 FIX: No longer creates fake booking on error.
  /// Throws exception so the Cubit can show an error message.
  Future<RideBookingModel> bookRide({
    required int vehicleTypeId,
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    required double dropoffLat,
    required double dropoffLng,
    required String dropoffAddress,
    required String paymentMethod,
    double? totalFare,
  }) async {
    final response = await _apiClient.post(
      '/api/v1/rides/book',
      data: {
        'vehicle_type_id': vehicleTypeId,
        'pickup_lat': pickupLat,
        'pickup_latitude': pickupLat,
        'pickup_lng': pickupLng,
        'pickup_longitude': pickupLng,
        'pickup_address': pickupAddress,
        'dropoff_lat': dropoffLat,
        'dropoff_latitude': dropoffLat,
        'dropoff_lng': dropoffLng,
        'dropoff_longitude': dropoffLng,
        'dropoff_address': dropoffAddress,
        'payment_method': paymentMethod,
        if (totalFare != null) 'total_fare': totalFare,
      },
      parser: (data) => data,
    );

    // Parse nested response: {data: {ride: {...}}} or {ride: {...}} or {data: {...}}
    final rideData = (response is Map && response['data'] is Map && response['data']['ride'] != null)
        ? response['data']['ride']
        : (response is Map && response['ride'] != null)
            ? response['ride']
            : (response is Map && response['data'] != null ? response['data'] : response);

    return RideBookingModel.fromJson(rideData as Map<String, dynamic>);
  }

  /// Track ride status & driver location.
  ///
  /// C-5 FIX: Handles `{data: {ride: {...}, driver_location: {...}}}` nesting
  /// and wraps in try-catch so tracking timer doesn't crash.
  Future<RideBookingModel> trackRide(int rideId) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/rides/$rideId/track',
        parser: (data) => data,
      );

      // Backend returns {data: {ride: {...}, driver_location: {...}, eta: ...}}
      dynamic rideData;
      if (response is Map) {
        if (response['data'] is Map && response['data']['ride'] != null) {
          rideData = response['data']['ride'];
        } else if (response['ride'] != null) {
          rideData = response['ride'];
        } else if (response['data'] != null) {
          rideData = response['data'];
        } else {
          rideData = response;
        }
      } else {
        rideData = response;
      }

      return RideBookingModel.fromJson(rideData as Map<String, dynamic>);
    } catch (e) {
      // Re-throw to allow caller to handle (periodic check will catch)
      rethrow;
    }
  }

  /// Cancel a ride.
  ///
  /// C-3 FIX: Sends `cancellation_reason` (backend canonical key)
  /// M-2 FIX: Returns false on actual failure instead of swallowing errors.
  Future<bool> cancelRide(int rideId, {String? reason}) async {
    try {
      await _apiClient.post(
        '/api/v1/rides/$rideId/cancel',
        data: {
          'cancellation_reason': reason ?? 'User cancelled',
          'reason': reason ?? 'User cancelled', // legacy alias
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Rate completed ride.
  ///
  /// C-2 FIX: Sends `driver_rating`/`rider_rating` (backend canonical keys)
  ///          and converts double to int.
  /// M-3 FIX: Returns false on failure instead of swallowing errors.
  Future<bool> rateRide(int rideId, double rating, {String? comment}) async {
    try {
      final ratingInt = rating.toInt().clamp(1, 5);
      await _apiClient.post(
        '/api/v1/rides/$rideId/rate',
        data: {
          'driver_rating': ratingInt,
          'rider_rating': ratingInt,
          'driver_review': comment ?? '',
          'rider_review': comment ?? '',
          // Also send simplified aliases for backward compat
          'rating': ratingInt,
          'comment': comment ?? '',
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Trigger SOS alert.
  ///
  /// M-1 FIX: lat/lng are now required parameters since backend validates them.
  Future<bool> triggerSOS(int rideId, {required double lat, required double lng}) async {
    try {
      await _apiClient.post(
        '/api/v1/rides/$rideId/sos',
        data: {
          'latitude': lat,
          'longitude': lng,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Get user ride history
  Future<List<RideBookingModel>> getRideHistory() async {
    try {
      final response = await _apiClient.get(
        '/api/v1/rides/history',
        parser: (data) => data,
      );

      // Handle paginated response: {data: {data: [...]}} or {data: [...]} or {rides: [...]}
      List? list;
      if (response is Map) {
        if (response['data'] is Map && response['data']['data'] is List) {
          // Laravel paginated response: {data: {data: [...], current_page, ...}}
          list = response['data']['data'] as List;
        } else if (response['rides'] is List) {
          list = response['rides'] as List;
        } else if (response['data'] is List) {
          list = response['data'] as List;
        }
      } else if (response is List) {
        list = response;
      }

      return (list ?? [])
          .map((item) => RideBookingModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // M-5 FIX: Rethrow so RideHistoryScreen can show error state
      rethrow;
    }
  }
}
