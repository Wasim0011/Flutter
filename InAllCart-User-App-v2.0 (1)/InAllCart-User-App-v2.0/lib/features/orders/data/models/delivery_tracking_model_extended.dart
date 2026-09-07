// Extended models for Premium-style tracking
import '../../domain/entities/delivery_tracking.dart';

class OrderItemModel extends OrderItem {
  const OrderItemModel({
    required super.id,
    required super.productName,
    super.variantName,
    required super.quantity,
    required super.price,
    required super.originalPrice,
    required super.total,
    super.image,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as int,
      productName: json['product_name'] as String,
      variantName: json['variant_name'] as String?,
      quantity: json['quantity'] as int,
      price: _parseDouble(json['price']),
      originalPrice: _parseDouble(json['original_price']),
      total: _parseDouble(json['total']),
      image: json['image'] as String?,
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
      'product_name': productName,
      'variant_name': variantName,
      'quantity': quantity,
      'price': price,
      'original_price': originalPrice,
      'total': total,
      'image': image,
    };
  }
}

class TrackingMediaModel extends TrackingMedia {
  const TrackingMediaModel({
    super.id,
    super.title,
    super.subtitle,
    super.image,
    super.actionType,
    super.actionValue,
  });

  factory TrackingMediaModel.fromJson(Map<String, dynamic> json) {
    return TrackingMediaModel(
      id: json['id'] as int?,
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      image: json['image'] as String?,
      actionType: json['action_type'] as String?,
      actionValue: json['action_value'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'image': image,
      'action_type': actionType,
      'action_value': actionValue,
    };
  }
}

class DeliveryStoreModelExtended extends DeliveryStore {
  const DeliveryStoreModelExtended({
    super.id,
    required super.name,
    required super.latitude,
    required super.longitude,
    super.image,
    super.phone,
  });

  factory DeliveryStoreModelExtended.fromJson(Map<String, dynamic> json) {
    return DeliveryStoreModelExtended(
      id: json['id'] as int?,
      name: json['name'] as String,
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      image: json['image'] as String?,
      phone: json['phone'] as String?,
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
      'latitude': latitude,
      'longitude': longitude,
      'image': image,
      'phone': phone,
    };
  }
}
