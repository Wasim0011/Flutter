import 'package:equatable/equatable.dart';

/// Delivery tracking entity - represents real-time delivery location and status
class DeliveryTracking extends Equatable {
  final int orderId;
  final String orderNumber;
  final String status;
  final DeliveryLocation? currentLocation;
  final DeliveryPartner? deliveryPartner;
  final DeliveryDestination destination;
  final DeliveryStore? store;
  final List<OrderItem> items;
  final int totalItems;
  final double totalSavings;
  final double subtotal;
  final double total;
  final List<TrackingMedia> trackingMedia;
  final int? etaMinutes;
  final DateTime? estimatedDeliveryAt;
  final bool trackingAvailable;

  const DeliveryTracking({
    required this.orderId,
    required this.orderNumber,
    required this.status,
    this.currentLocation,
    this.deliveryPartner,
    required this.destination,
    this.store,
    this.items = const [],
    this.totalItems = 0,
    this.totalSavings = 0,
    this.subtotal = 0,
    this.total = 0,
    this.trackingMedia = const [],
    this.etaMinutes,
    this.estimatedDeliveryAt,
    required this.trackingAvailable,
  });

  @override
  List<Object?> get props => [
        orderId,
        orderNumber,
        status,
        currentLocation,
        deliveryPartner,
        destination,
        store,
        items,
        totalItems,
        totalSavings,
        subtotal,
        total,
        trackingMedia,
        etaMinutes,
        estimatedDeliveryAt,
        trackingAvailable,
      ];
}

class DeliveryLocation extends Equatable {
  final double latitude;
  final double longitude;
  final DateTime? updatedAt;

  const DeliveryLocation({
    required this.latitude,
    required this.longitude,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [latitude, longitude, updatedAt];
}

class DeliveryPartner extends Equatable {
  final int id;
  final String name;
  final String? phone;
  final String? photo;
  final double rating;

  const DeliveryPartner({
    required this.id,
    required this.name,
    this.phone,
    this.photo,
    this.rating = 0,
  });

  @override
  List<Object?> get props => [id, name, phone, photo, rating];
}

class DeliveryDestination extends Equatable {
  final double? latitude;
  final double? longitude;
  final String address;
  final String city;

  const DeliveryDestination({
    this.latitude,
    this.longitude,
    required this.address,
    required this.city,
  });

  @override
  List<Object?> get props => [latitude, longitude, address, city];
}

class DeliveryStore extends Equatable {
  final int? id;
  final String name;
  final double latitude;
  final double longitude;
  final String? image;
  final String? phone;

  const DeliveryStore({
    this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.image,
    this.phone,
  });

  @override
  List<Object?> get props => [id, name, latitude, longitude, image, phone];
}

/// Order item for tracking screen
class OrderItem extends Equatable {
  final int id;
  final String productName;
  final String? variantName;
  final int quantity;
  final double price;
  final double originalPrice;
  final double total;
  final String? image;

  const OrderItem({
    required this.id,
    required this.productName,
    this.variantName,
    required this.quantity,
    required this.price,
    required this.originalPrice,
    required this.total,
    this.image,
  });

  @override
  List<Object?> get props => [
        id,
        productName,
        variantName,
        quantity,
        price,
        originalPrice,
        total,
        image,
      ];
}

/// Tracking media widget (carousel)
class TrackingMedia extends Equatable {
  final int? id;
  final String? title;
  final String? subtitle;
  final String? image;
  final String? actionType;
  final String? actionValue;

  const TrackingMedia({
    this.id,
    this.title,
    this.subtitle,
    this.image,
    this.actionType,
    this.actionValue,
  });

  @override
  List<Object?> get props => [id, title, subtitle, image, actionType, actionValue];
}

/// Tracking history point for route replay
class TrackingHistoryPoint extends Equatable {
  final double latitude;
  final double longitude;
  final double? speed;
  final String status;
  final DateTime recordedAt;

  const TrackingHistoryPoint({
    required this.latitude,
    required this.longitude,
    this.speed,
    required this.status,
    required this.recordedAt,
  });

  @override
  List<Object?> get props => [latitude, longitude, speed, status, recordedAt];
}
