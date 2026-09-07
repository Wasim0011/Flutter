import '../../domain/entities/ride_sharing_entities.dart';

int _parseInt(dynamic val, [int fallback = 0]) {
  if (val == null) return fallback;
  if (val is int) return val;
  if (val is double) return val.toInt();
  if (val is String) {
    return int.tryParse(val) ?? double.tryParse(val)?.toInt() ?? fallback;
  }
  return fallback;
}

int? _parseNullableInt(dynamic val) {
  if (val == null) return null;
  if (val is int) return val;
  if (val is double) return val.toInt();
  if (val is String) {
    return int.tryParse(val) ?? double.tryParse(val)?.toInt();
  }
  return null;
}

class VehicleTypeModel extends VehicleType {
  const VehicleTypeModel({
    required int id,
    required String name,
    String? description,
    required int capacity,
    required double baseFare,
    String? iconUrl,
  }) : super(
          id: id,
          name: name,
          description: description,
          capacity: capacity,
          baseFare: baseFare,
          iconUrl: iconUrl,
        );

  factory VehicleTypeModel.fromJson(Map<String, dynamic> json) {
    return VehicleTypeModel(
      id: _parseInt(json['id']),
      name: json['name'] ?? 'Taxi',
      description: json['description'],
      capacity: _parseInt(json['capacity'], 1),
      baseFare: double.tryParse(json['base_fare']?.toString() ?? '0') ?? 0.0,
      iconUrl: json['icon_url'] ?? json['icon'],
    );
  }
}

class FareEstimateModel extends FareEstimate {
  const FareEstimateModel({
    required String vehicleType,
    required double baseFare,
    required double distanceFare,
    required double timeFare,
    required double surgeMultiplier,
    required double surgeAmount,
    required bool isSurgeActive,
    required double subtotal,
    required double taxAmount,
    required double totalFare,
    required double estimatedDistance,
    required double estimatedDuration,
    String? polyline,
  }) : super(
          vehicleType: vehicleType,
          baseFare: baseFare,
          distanceFare: distanceFare,
          timeFare: timeFare,
          surgeMultiplier: surgeMultiplier,
          surgeAmount: surgeAmount,
          isSurgeActive: isSurgeActive,
          subtotal: subtotal,
          taxAmount: taxAmount,
          totalFare: totalFare,
          estimatedDistance: estimatedDistance,
          estimatedDuration: estimatedDuration,
          polyline: polyline,
        );

  factory FareEstimateModel.fromJson(Map<String, dynamic> json, {String? polyline}) {
    return FareEstimateModel(
      vehicleType: json['vehicle_type'] ?? '',
      baseFare: double.tryParse(json['base_fare']?.toString() ?? '0') ?? 0.0,
      distanceFare: double.tryParse(json['distance_fare']?.toString() ?? '0') ?? 0.0,
      timeFare: double.tryParse(json['time_fare']?.toString() ?? '0') ?? 0.0,
      surgeMultiplier: double.tryParse(json['surge_multiplier']?.toString() ?? '1.0') ?? 1.0,
      surgeAmount: double.tryParse(json['surge_amount']?.toString() ?? '0') ?? 0.0,
      isSurgeActive: json['is_surge_active'] ?? false,
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
      taxAmount: double.tryParse(json['tax_amount']?.toString() ?? '0') ?? 0.0,
      totalFare: double.tryParse(json['total_fare']?.toString() ?? '0') ?? 0.0,
      estimatedDistance: double.tryParse(json['estimated_distance']?.toString() ?? '0') ?? 0.0,
      estimatedDuration: double.tryParse(json['estimated_duration']?.toString() ?? '0') ?? 0.0,
      polyline: polyline ?? json['polyline'],
    );
  }
}

class RideDriverModel extends RideDriver {
  const RideDriverModel({
    required int id,
    required String name,
    String? phone,
    required double rating,
    double? latitude,
    double? longitude,
    String? vehicleMake,
    String? vehicleModel,
    String? vehicleColor,
    String? vehiclePlateNumber,
    String? photo,
  }) : super(
          id: id,
          name: name,
          phone: phone,
          rating: rating,
          latitude: latitude,
          longitude: longitude,
          vehicleMake: vehicleMake,
          vehicleModel: vehicleModel,
          vehicleColor: vehicleColor,
          vehiclePlateNumber: vehiclePlateNumber,
          photo: photo,
        );

  factory RideDriverModel.fromJson(Map<String, dynamic> json) {
    final vehicle = json['vehicle'] ?? {};
    final user = (json['user'] is Map) ? json['user'] as Map : const {};
    return RideDriverModel(
      id: _parseInt(json['id']),
      name: json['name'] ?? user['name'] ?? 'Driver',
      phone: json['phone'] ?? user['phone'],
      rating: double.tryParse(json['rating']?.toString() ?? '5.0') ?? 5.0,
      latitude: double.tryParse(json['latitude']?.toString() ?? json['last_latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? json['last_longitude']?.toString() ?? '0') ?? 0.0,
      vehicleMake: vehicle['make'] ?? json['vehicle_make'],
      vehicleModel: vehicle['model'] ?? json['vehicle_model'],
      vehicleColor: vehicle['color'] ?? json['vehicle_color'],
      vehiclePlateNumber: vehicle['plate_number'] ?? json['vehicle_plate_number'],
      photo: json['photo'] as String? ?? json['avatar'] as String? ?? user['avatar'] as String?,
    );
  }
}

class RideModel extends Ride {
  const RideModel({
    required int id,
    required int riderId,
    int? driverId,
    required int vehicleTypeId,
    required String status,
    required String pickupAddress,
    required double pickupLatitude,
    required double pickupLongitude,
    required String dropoffAddress,
    required double dropoffLatitude,
    required double dropoffLongitude,
    required double totalFare,
    required String paymentMethod,
    RideDriverModel? driver,
    String? ridePin,
    String? vehicleTypeName,
    String? createdAt,
    int? rating,
    String? ratingComment,
    double? baseFare,
    double? distanceFare,
    double? timeFare,
    double? taxAmount,
    double? discount,
    String? promoCode,
    String? paymentStatus,
    String? cancelledBy,
    String? cancellationReason,
    double? cancellationFee,
    String? completedAt,
    String? cancelledAt,
    double? distanceKm,
    int? durationMinutes,
  }) : super(
          id: id,
          riderId: riderId,
          driverId: driverId,
          vehicleTypeId: vehicleTypeId,
          status: status,
          pickupAddress: pickupAddress,
          pickupLatitude: pickupLatitude,
          pickupLongitude: pickupLongitude,
          dropoffAddress: dropoffAddress,
          dropoffLatitude: dropoffLatitude,
          dropoffLongitude: dropoffLongitude,
          totalFare: totalFare,
          paymentMethod: paymentMethod,
          driver: driver,
          ridePin: ridePin,
          vehicleTypeName: vehicleTypeName,
          createdAt: createdAt,
          rating: rating,
          ratingComment: ratingComment,
          baseFare: baseFare,
          distanceFare: distanceFare,
          timeFare: timeFare,
          taxAmount: taxAmount,
          discount: discount,
          promoCode: promoCode,
          paymentStatus: paymentStatus,
          cancelledBy: cancelledBy,
          cancellationReason: cancellationReason,
          cancellationFee: cancellationFee,
          completedAt: completedAt,
          cancelledAt: cancelledAt,
          distanceKm: distanceKm,
          durationMinutes: durationMinutes,
        );

  factory RideModel.fromJson(Map<String, dynamic> json) {
    RideDriverModel? parsedDriver;
    if (json['driver'] != null && json['driver'] is Map) {
      parsedDriver = RideDriverModel.fromJson(json['driver']);
    }

    String? vehicleTypeName;
    if (json['vehicle_type'] is Map) {
      vehicleTypeName = json['vehicle_type']['name'];
    } else if (json['vehicle_type'] is String) {
      vehicleTypeName = json['vehicle_type'];
    } else if (json['vehicle_type_name'] != null) {
      vehicleTypeName = json['vehicle_type_name'];
    }

    final rideId = _parseInt(json['id']);
    return RideModel(
      id: rideId,
      riderId: _parseInt(json['rider_id']),
      driverId: _parseNullableInt(json['driver_id']),
      vehicleTypeId: _parseInt(json['vehicle_type_id'], 1),
      status: json['status'] ?? 'searching',
      pickupAddress: json['pickup_address'] ?? '',
      pickupLatitude: double.tryParse(json['pickup_latitude']?.toString() ?? '0') ?? 0.0,
      pickupLongitude: double.tryParse(json['pickup_longitude']?.toString() ?? '0') ?? 0.0,
      dropoffAddress: json['dropoff_address'] ?? '',
      dropoffLatitude: double.tryParse(json['dropoff_latitude']?.toString() ?? '0') ?? 0.0,
      dropoffLongitude: double.tryParse(json['dropoff_longitude']?.toString() ?? '0') ?? 0.0,
      totalFare: double.tryParse(json['total_fare']?.toString() ?? '0') ?? 0.0,
      paymentMethod: json['payment_method'] ?? 'cash',
      ridePin: json['ride_pin'] ?? (rideId != 0 ? (rideId % 10000).toString().padLeft(4, '0') : '1234'),
      driver: parsedDriver,
      vehicleTypeName: vehicleTypeName,
      createdAt: json['created_at'],
      rating: _parseNullableInt(json['rating']),
      ratingComment: json['rating_comment'] ?? json['comment'],
      baseFare: double.tryParse(json['base_fare']?.toString() ?? ''),
      distanceFare: double.tryParse(json['distance_fare']?.toString() ?? ''),
      timeFare: double.tryParse(json['time_fare']?.toString() ?? ''),
      taxAmount: double.tryParse(json['tax_amount']?.toString() ?? ''),
      discount: double.tryParse(json['discount']?.toString() ?? json['discount_amount']?.toString() ?? ''),
      promoCode: json['promo_code'],
      paymentStatus: json['payment_status'],
      cancelledBy: json['cancelled_by'],
      cancellationReason: json['cancellation_reason'],
      cancellationFee: double.tryParse(json['cancellation_fee']?.toString() ?? ''),
      completedAt: json['completed_at'],
      cancelledAt: json['cancelled_at'],
      distanceKm: double.tryParse(json['actual_distance']?.toString() ?? json['estimated_distance']?.toString() ?? ''),
      durationMinutes: _parseNullableInt(json['actual_duration']) ?? _parseNullableInt(json['estimated_duration']),
    );
  }
}
