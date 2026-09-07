import 'package:equatable/equatable.dart';

class VehicleType extends Equatable {
  final int id;
  final String name;
  final String? description;
  final int capacity;
  final double baseFare;
  final String? iconUrl;

  const VehicleType({
    required this.id,
    required this.name,
    this.description,
    required this.capacity,
    required this.baseFare,
    this.iconUrl,
  });

  @override
  List<Object?> get props => [id, name, description, capacity, baseFare, iconUrl];
}

class FareEstimate extends Equatable {
  final String vehicleType;
  final double baseFare;
  final double distanceFare;
  final double timeFare;
  final double surgeMultiplier;
  final double surgeAmount;
  final bool isSurgeActive;
  final double subtotal;
  final double taxAmount;
  final double totalFare;
  final double estimatedDistance;
  final double estimatedDuration;
  final String? polyline;

  const FareEstimate({
    required this.vehicleType,
    required this.baseFare,
    required this.distanceFare,
    required this.timeFare,
    required this.surgeMultiplier,
    required this.surgeAmount,
    required this.isSurgeActive,
    required this.subtotal,
    required this.taxAmount,
    required this.totalFare,
    required this.estimatedDistance,
    required this.estimatedDuration,
    this.polyline,
  });

  @override
  List<Object?> get props => [
    vehicleType, baseFare, distanceFare, timeFare, surgeMultiplier,
    surgeAmount, isSurgeActive, subtotal, taxAmount, totalFare,
    estimatedDistance, estimatedDuration, polyline,
  ];
}

class RideDriver extends Equatable {
  final int id;
  final String name;
  final String? phone;
  final double rating;
  final double? latitude;
  final double? longitude;
  final String? vehicleMake;
  final String? vehicleModel;
  final String? vehicleColor;
  final String? vehiclePlateNumber;
  final String? photo;

  const RideDriver({
    required this.id,
    required this.name,
    this.phone,
    required this.rating,
    this.latitude,
    this.longitude,
    this.vehicleMake,
    this.vehicleModel,
    this.vehicleColor,
    this.vehiclePlateNumber,
    this.photo,
  });

  @override
  List<Object?> get props => [id, name, phone, rating, latitude, longitude, vehicleMake, vehicleModel, vehicleColor, vehiclePlateNumber, photo];
}

class Ride extends Equatable {
  final int id;
  final int riderId;
  final int? driverId;
  final int vehicleTypeId;
  final String status;
  final String pickupAddress;
  final double pickupLatitude;
  final double pickupLongitude;
  final String dropoffAddress;
  final double dropoffLatitude;
  final double dropoffLongitude;
  final double totalFare;
  final String paymentMethod;
  final RideDriver? driver;
  final String? ridePin;
  final String? vehicleTypeName;
  final String? createdAt;
  final int? rating;
  final String? ratingComment;
  final double? baseFare;
  final double? distanceFare;
  final double? timeFare;
  final double? taxAmount;
  final double? discount;
  final String? promoCode;
  // Lifecycle & payment details
  final String? paymentStatus;
  final String? cancelledBy;
  final String? cancellationReason;
  final double? cancellationFee;
  final String? completedAt;
  final String? cancelledAt;
  final double? distanceKm;
  final int? durationMinutes;

  const Ride({
    required this.id,
    required this.riderId,
    this.driverId,
    required this.vehicleTypeId,
    required this.status,
    required this.pickupAddress,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.dropoffAddress,
    required this.dropoffLatitude,
    required this.dropoffLongitude,
    required this.totalFare,
    required this.paymentMethod,
    this.driver,
    this.ridePin,
    this.vehicleTypeName,
    this.createdAt,
    this.rating,
    this.ratingComment,
    this.baseFare,
    this.distanceFare,
    this.timeFare,
    this.taxAmount,
    this.discount,
    this.promoCode,
    this.paymentStatus,
    this.cancelledBy,
    this.cancellationReason,
    this.cancellationFee,
    this.completedAt,
    this.cancelledAt,
    this.distanceKm,
    this.durationMinutes,
  });

  @override
  List<Object?> get props => [id, riderId, driverId, vehicleTypeId, status, pickupAddress, pickupLatitude, pickupLongitude, dropoffAddress, dropoffLatitude, dropoffLongitude, totalFare, paymentMethod, driver, ridePin, vehicleTypeName, createdAt, rating, ratingComment, baseFare, distanceFare, timeFare, taxAmount, discount, promoCode, paymentStatus, cancelledBy, cancellationReason, cancellationFee, completedAt, cancelledAt, distanceKm, durationMinutes];
}

class PaymentMethodInfo extends Equatable {
  final String id;
  final String name;
  final String type;
  final String? iconUrl;
  final bool isActive;

  const PaymentMethodInfo({
    required this.id,
    required this.name,
    required this.type,
    this.iconUrl,
    this.isActive = true,
  });

  factory PaymentMethodInfo.fromJson(Map<String, dynamic> json) {
    // Backend sends: { name, display_name, is_enabled } (with optional id/type).
    final rawId = (json['id'] ?? json['name'])?.toString() ?? '';
    return PaymentMethodInfo(
      id: rawId,
      name: json['display_name'] ?? json['name'] ?? '',
      type: json['type'] ?? 'online',
      iconUrl: json['icon_url'],
      isActive: json['is_active'] ?? json['is_enabled'] ?? true,
    );
  }

  @override
  List<Object?> get props => [id, name, type, iconUrl, isActive];
}

class PaymentInitData extends Equatable {
  final String? paymentId;
  final String? orderId;
  final String? clientSecret;
  final Map<String, dynamic>? additionalData;

  const PaymentInitData({
    this.paymentId,
    this.orderId,
    this.clientSecret,
    this.additionalData,
  });

  factory PaymentInitData.fromJson(Map<String, dynamic> json) {
    return PaymentInitData(
      paymentId: json['payment_id']?.toString(),
      orderId: json['order_id']?.toString(),
      clientSecret: json['client_secret']?.toString(),
      additionalData: json['data'] as Map<String, dynamic>?,
    );
  }

  @override
  List<Object?> get props => [paymentId, orderId, clientSecret, additionalData];
}
