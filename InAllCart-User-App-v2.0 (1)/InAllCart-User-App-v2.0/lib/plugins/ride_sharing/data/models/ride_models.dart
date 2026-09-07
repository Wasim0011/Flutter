import 'package:equatable/equatable.dart';

class VehicleTypeModel extends Equatable {
  final int id;
  final String name;
  final String category; // bike, auto, car, suv, etc.
  final String? iconUrl;
  final double baseFare;
  final double perKmRate;
  final double perMinuteRate;
  final int capacity;
  final String estimatedEta;
  final bool isAvailable;

  const VehicleTypeModel({
    required this.id,
    required this.name,
    required this.category,
    this.iconUrl,
    required this.baseFare,
    required this.perKmRate,
    required this.perMinuteRate,
    required this.capacity,
    this.estimatedEta = '3-5 min',
    this.isAvailable = true,
  });

  factory VehicleTypeModel.fromJson(Map<String, dynamic> json) {
    return VehicleTypeModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? 'Standard Ride',
      category: json['category']?.toString() ?? json['type']?.toString() ?? 'car',
      iconUrl: json['icon']?.toString() ?? json['icon_url']?.toString(),
      baseFare: (json['base_fare'] ?? json['base_price'] ?? 0.0).toDouble(),
      perKmRate: (json['per_km_rate'] ?? json['price_per_km'] ?? 0.0).toDouble(),
      perMinuteRate: (json['per_minute_rate'] ?? json['price_per_min'] ?? 0.0).toDouble(),
      capacity: (json['capacity'] ?? json['passengers'] ?? 4) as int,
      estimatedEta: json['eta']?.toString() ?? '3-5 min',
      isAvailable: json['is_available'] ?? json['active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'icon': iconUrl,
      'base_fare': baseFare,
      'per_km_rate': perKmRate,
      'per_minute_rate': perMinuteRate,
      'capacity': capacity,
      'eta': estimatedEta,
      'is_available': isAvailable,
    };
  }

  @override
  List<Object?> get props => [id, name, category, baseFare, perKmRate, perMinuteRate, capacity];
}

class RideEstimateModel extends Equatable {
  final int vehicleTypeId;
  final String vehicleName;
  final double distanceKm;
  final double durationMinutes;
  final double estimatedFare;
  final String currency;
  final double surgeMultiplier;
  final String polyline;

  const RideEstimateModel({
    required this.vehicleTypeId,
    required this.vehicleName,
    required this.distanceKm,
    required this.durationMinutes,
    required this.estimatedFare,
    this.currency = '₹',
    this.surgeMultiplier = 1.0,
    this.polyline = '',
  });

  factory RideEstimateModel.fromJson(Map<String, dynamic> json) {
    return RideEstimateModel(
      vehicleTypeId: json['vehicle_type_id'] is int
          ? json['vehicle_type_id']
          : int.tryParse(json['vehicle_type_id'].toString()) ?? 0,
      vehicleName: json['vehicle_name']?.toString() ?? 'Taxi',
      distanceKm: (json['distance_km'] ?? json['distance'] ?? 0.0).toDouble(),
      durationMinutes: (json['duration_minutes'] ?? json['duration'] ?? 0.0).toDouble(),
      estimatedFare: (json['total_fare'] ?? json['estimated_fare'] ?? json['fare'] ?? 0.0).toDouble(),
      currency: json['currency']?.toString() ?? '₹',
      surgeMultiplier: (json['surge_multiplier'] ?? 1.0).toDouble(),
      polyline: json['polyline']?.toString() ?? json['encoded_polyline']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [vehicleTypeId, estimatedFare, distanceKm, durationMinutes];
}

class RideBookingModel extends Equatable {
  final int id;
  final String rideNumber;
  final String status; // pending, accepted, arrived, in_transit, completed, cancelled
  final double pickupLat;
  final double pickupLng;
  final String pickupAddress;
  final double dropoffLat;
  final double dropoffLng;
  final String dropoffAddress;
  final double totalFare;
  final String paymentMethod;
  final String paymentStatus;
  final String? otp;
  final String? driverName;
  final String? driverPhone;
  final String? driverPhoto;
  final String? vehicleName;
  final String? vehicleNumber;
  final double? driverRating;
  final double? driverLat;
  final double? driverLng;
  final String? createdAt;

  const RideBookingModel({
    required this.id,
    required this.rideNumber,
    required this.status,
    required this.pickupLat,
    required this.pickupLng,
    required this.pickupAddress,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.dropoffAddress,
    required this.totalFare,
    this.paymentMethod = 'cash',
    this.paymentStatus = 'pending',
    this.otp,
    this.driverName,
    this.driverPhone,
    this.driverPhoto,
    this.vehicleName,
    this.vehicleNumber,
    this.driverRating,
    this.driverLat,
    this.driverLng,
    this.createdAt,
  });

  factory RideBookingModel.fromJson(Map<String, dynamic> json) {
    final driver = json['driver'] as Map<String, dynamic>?;
    final vehicle = json['vehicle_type'] as Map<String, dynamic>? ?? json['vehicle'] as Map<String, dynamic>?;

    return RideBookingModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      rideNumber: json['ride_number']?.toString() ?? json['booking_id']?.toString() ?? '#${json['id']}',
      status: json['status']?.toString() ?? 'pending',
      pickupLat: (json['pickup_lat'] ?? json['pickup_latitude'] ?? 0.0).toDouble(),
      pickupLng: (json['pickup_lng'] ?? json['pickup_longitude'] ?? 0.0).toDouble(),
      pickupAddress: json['pickup_address']?.toString() ?? 'Pickup Location',
      dropoffLat: (json['dropoff_lat'] ?? json['dropoff_latitude'] ?? 0.0).toDouble(),
      dropoffLng: (json['dropoff_lng'] ?? json['dropoff_longitude'] ?? 0.0).toDouble(),
      dropoffAddress: json['dropoff_address']?.toString() ?? 'Destination',
      totalFare: (json['total_fare'] ?? json['fare'] ?? json['amount'] ?? 0.0).toDouble(),
      paymentMethod: json['payment_method']?.toString() ?? 'cash',
      paymentStatus: json['payment_status']?.toString() ?? 'pending',
      otp: json['otp']?.toString() ?? json['start_otp']?.toString(),
      driverName: driver?['name']?.toString() ?? json['driver_name']?.toString(),
      driverPhone: driver?['phone']?.toString() ?? json['driver_phone']?.toString(),
      driverPhoto: driver?['avatar']?.toString() ?? driver?['photo']?.toString() ?? json['driver_photo']?.toString(),
      vehicleName: vehicle?['name']?.toString() ?? json['vehicle_name']?.toString(),
      vehicleNumber: driver?['vehicle_number']?.toString() ?? json['vehicle_number']?.toString(),
      driverRating: (driver?['rating'] ?? json['driver_rating'] ?? 4.8).toDouble(),
      driverLat: (driver?['current_lat'] ?? json['driver_lat'] ?? json['driver_latitude'])?.toDouble(),
      driverLng: (driver?['current_lng'] ?? json['driver_lng'] ?? json['driver_longitude'])?.toDouble(),
      createdAt: json['created_at']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, rideNumber, status, totalFare, driverName, driverLat, driverLng];
}
