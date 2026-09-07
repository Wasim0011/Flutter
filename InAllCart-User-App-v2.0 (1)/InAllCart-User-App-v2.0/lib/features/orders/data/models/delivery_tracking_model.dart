import '../../domain/entities/delivery_tracking.dart';
import 'delivery_tracking_model_extended.dart';

class DeliveryTrackingModel extends DeliveryTracking {
  const DeliveryTrackingModel({
    required super.orderId,
    required super.orderNumber,
    required super.status,
    super.currentLocation,
    super.deliveryPartner,
    required super.destination,
    super.store,
    super.items,
    super.totalItems,
    super.totalSavings,
    super.subtotal,
    super.total,
    super.trackingMedia,
    super.etaMinutes,
    super.estimatedDeliveryAt,
    required super.trackingAvailable,
  });

  factory DeliveryTrackingModel.fromJson(Map<String, dynamic> json) {
    return DeliveryTrackingModel(
      orderId: json['order_id'] as int,
      orderNumber: json['order_number'] as String,
      status: json['status'] as String,
      currentLocation: json['current_location'] != null
          ? DeliveryLocationModel.fromJson(json['current_location'] as Map<String, dynamic>)
          : null,
      deliveryPartner: json['delivery_partner'] != null
          ? DeliveryPartnerModel.fromJson(json['delivery_partner'] as Map<String, dynamic>)
          : null,
      destination: DeliveryDestinationModel.fromJson(json['destination'] as Map<String, dynamic>),
      store: json['store'] != null
          ? DeliveryStoreModelExtended.fromJson(json['store'] as Map<String, dynamic>)
          : null,
      items: json['items'] != null
          ? (json['items'] as List).map((item) {
              final itemMap = Map<String, dynamic>.from(item as Map);
              return OrderItemModel.fromJson(itemMap);
            }).toList()
          : [],
      totalItems: json['total_items'] as int? ?? 0,
      totalSavings: _parseDouble(json['total_savings']),
      subtotal: _parseDouble(json['subtotal']),
      total: _parseDouble(json['total']),
      trackingMedia: json['tracking_media'] != null
          ? (json['tracking_media'] as List).map((media) {
              final mediaMap = Map<String, dynamic>.from(media as Map);
              return TrackingMediaModel.fromJson(mediaMap);
            }).toList()
          : [],
      etaMinutes: json['eta_minutes'] as int?,
      estimatedDeliveryAt: json['estimated_delivery_at'] != null
          ? DateTime.parse(json['estimated_delivery_at'] as String)
          : null,
      trackingAvailable: json['tracking_available'] as bool,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'order_number': orderNumber,
      'status': status,
      'current_location': currentLocation != null
          ? (currentLocation as DeliveryLocationModel).toJson()
          : null,
      'delivery_partner': deliveryPartner != null
          ? (deliveryPartner as DeliveryPartnerModel).toJson()
          : null,
      'destination': (destination as DeliveryDestinationModel).toJson(),
      'store': store != null
          ? (store is DeliveryStoreModelExtended
              ? (store as DeliveryStoreModelExtended).toJson()
              : (store as DeliveryStoreModel).toJson())
          : null,
      'eta_minutes': etaMinutes,
      'estimated_delivery_at': estimatedDeliveryAt?.toIso8601String(),
      'tracking_available': trackingAvailable,
    };
  }
}

class DeliveryLocationModel extends DeliveryLocation {
  const DeliveryLocationModel({
    required super.latitude,
    required super.longitude,
    super.updatedAt,
  });

  factory DeliveryLocationModel.fromJson(Map<String, dynamic> json) {
    // Handle null values for latitude/longitude
    final lat = json['latitude'];
    final lng = json['longitude'];
    
    return DeliveryLocationModel(
      latitude: lat != null ? (lat is num ? lat.toDouble() : double.tryParse(lat.toString()) ?? 0.0) : 0.0,
      longitude: lng != null ? (lng is num ? lng.toDouble() : double.tryParse(lng.toString()) ?? 0.0) : 0.0,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class DeliveryPartnerModel extends DeliveryPartner {
  const DeliveryPartnerModel({
    required super.id,
    required super.name,
    super.phone,
    super.photo,
    super.rating,
  });

  factory DeliveryPartnerModel.fromJson(Map<String, dynamic> json) {
    return DeliveryPartnerModel(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      photo: json['photo'] as String?,
      rating: _parseDouble(json['rating']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'photo': photo,
      'rating': rating,
    };
  }
}

class DeliveryDestinationModel extends DeliveryDestination {
  const DeliveryDestinationModel({
    super.latitude,
    super.longitude,
    required super.address,
    required super.city,
  });

  factory DeliveryDestinationModel.fromJson(Map<String, dynamic> json) {
    return DeliveryDestinationModel(
      latitude: json['latitude'] != null ? (json['latitude'] is num ? (json['latitude'] as num).toDouble() : double.tryParse(json['latitude'].toString())) : null,
      longitude: json['longitude'] != null ? (json['longitude'] is num ? (json['longitude'] as num).toDouble() : double.tryParse(json['longitude'].toString())) : null,
      address: json['address'] as String,
      city: json['city'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'city': city,
    };
  }
}

class DeliveryStoreModel extends DeliveryStore {
  const DeliveryStoreModel({
    required super.name,
    required super.latitude,
    required super.longitude,
  });

  factory DeliveryStoreModel.fromJson(Map<String, dynamic> json) {
    return DeliveryStoreModel(
      name: json['name'] as String,
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
    };
  }
}

class TrackingHistoryPointModel extends TrackingHistoryPoint {
  const TrackingHistoryPointModel({
    required super.latitude,
    required super.longitude,
    super.speed,
    required super.status,
    required super.recordedAt,
  });

  factory TrackingHistoryPointModel.fromJson(Map<String, dynamic> json) {
    return TrackingHistoryPointModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      status: json['status'] as String,
      recordedAt: DateTime.parse(json['recorded_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'status': status,
      'recorded_at': recordedAt.toIso8601String(),
    };
  }
}
