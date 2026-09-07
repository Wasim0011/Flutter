import '../../../address/data/models/address_model.dart';
import '../../domain/entities/order.dart';

class OrderModel extends Order {
  const OrderModel({
    required super.id,
    required super.orderNumber,
    required super.status,
    required super.items,
    required super.pricing,
    super.address,
    required super.payment,
    super.notes,
    super.deliveryOtp,
    required super.timestamps,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as int,
      orderNumber: json['order_number'] as String,
      status: OrderStatusModel.fromJson(json['status'] as Map<String, dynamic>),
      items: (json['items'] as List?)
              ?.map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pricing: OrderPricingModel.fromJson(json['pricing'] as Map<String, dynamic>),
      address: json['address'] != null
          ? AddressModel.fromJson(json['address'] as Map<String, dynamic>)
          : null,
      payment: OrderPaymentModel.fromJson(json['payment'] as Map<String, dynamic>),
      notes: json['notes'] as String?,
      deliveryOtp: (json['delivery_otp'] ?? json['otp'])?.toString(),
      timestamps: OrderTimestampsModel.fromJson(json['timestamps'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_number': orderNumber,
        'status': (status as OrderStatusModel).toJson(),
        'items': items.map((e) => (e as OrderItemModel).toJson()).toList(),
        'pricing': (pricing as OrderPricingModel).toJson(),
        'address': address != null ? (address as AddressModel).toJson() : null,
        'payment': (payment as OrderPaymentModel).toJson(),
        'notes': notes,
        'delivery_otp': deliveryOtp,
        'timestamps': (timestamps as OrderTimestampsModel).toJson(),
      };
}

class OrderItemModel extends OrderItem {
  const OrderItemModel({
    required super.id,
    required super.productId,
    super.variantId,
    required super.productName,
    super.variantName,
    super.productImage,
    required super.productSku,
    required super.quantity,
    required super.price,
    required super.total,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    
    // Try cached flat field first, then nested product object (from API response)
    final productImage = json['product_image'] as String?
        ?? product?['primary_image']?['url'] as String?
        ?? product?['primary_image']?['image'] as String?;

    return OrderItemModel(
      id: json['id'] as int,
      productId: product?['id'] as int? ?? json['product_id'] as int? ?? 0,
      variantId: json['variant_id'] as int?,
      productName: json['product_name'] as String? ?? product?['name'] as String? ?? '',
      variantName: json['variant_name'] as String?,
      productImage: productImage,
      productSku: json['product_sku'] as String? ?? '',
      quantity: json['quantity'] as int,
      price: _parseDouble(json['price']),
      total: _parseDouble(json['total']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'product_id': productId,
        'variant_id': variantId,
        'product_name': productName,
        'variant_name': variantName,
        'product_image': productImage,
        'product_sku': productSku,
        'quantity': quantity,
        'price': price,
        'total': total,
      };
}

class OrderStatusModel extends OrderStatus {
  const OrderStatusModel({
    required super.value,
    required super.label,
    required super.color,
  });

  factory OrderStatusModel.fromJson(Map<String, dynamic> json) {
    return OrderStatusModel(
      value: json['value'] as String,
      label: json['label'] as String,
      color: json['color'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'value': value,
        'label': label,
        'color': color,
      };
}

class OrderPricingModel extends OrderPricing {
  const OrderPricingModel({
    required super.subtotal,
    super.discount,
    super.deliveryFee,
    super.driverTip,
    super.tax,
    required super.total,
    super.formattedSubtotal,
    super.formattedDiscount,
    super.formattedDeliveryFee,
    super.formattedDriverTip,
    super.formattedTax,
    super.formattedTotal,
    super.currency,
    super.currencySymbol,
  });

  factory OrderPricingModel.fromJson(Map<String, dynamic> json) {
    return OrderPricingModel(
      subtotal: _parseDouble(json['subtotal']),
      discount: _parseDouble(json['discount']),
      deliveryFee: _parseDouble(json['delivery_fee']),
      driverTip: _parseDouble(json['driver_tip']),
      tax: _parseDouble(json['tax']),
      total: _parseDouble(json['total']),
      formattedSubtotal: json['formatted_subtotal'] as String?,
      formattedDiscount: json['formatted_discount'] as String?,
      formattedDeliveryFee: json['formatted_delivery_fee'] as String?,
      formattedDriverTip: json['formatted_driver_tip'] as String?,
      formattedTax: json['formatted_tax'] as String?,
      formattedTotal: json['formatted_total'] as String?,
      currency: json['currency'] as String?,
      currencySymbol: json['currency_symbol'] as String?,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() => {
        'subtotal': subtotal,
        'discount': discount,
        'delivery_fee': deliveryFee,
        'driver_tip': driverTip,
        'tax': tax,
        'total': total,
        'formatted_subtotal': formattedSubtotal,
        'formatted_discount': formattedDiscount,
        'formatted_delivery_fee': formattedDeliveryFee,
        'formatted_driver_tip': formattedDriverTip,
        'formatted_tax': formattedTax,
        'formatted_total': formattedTotal,
        'currency': currency,
        'currency_symbol': currencySymbol,
      };
}

class OrderPaymentModel extends OrderPayment {
  const OrderPaymentModel({
    required super.method,
    required super.status,
    super.transactionId,
    super.walletAmount,
  });

  factory OrderPaymentModel.fromJson(Map<String, dynamic> json) {
    return OrderPaymentModel(
      method: json['method'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      transactionId: json['transaction_id'] as String?,
      walletAmount: _parseDouble(json['wallet_amount']),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() => {
        'method': method,
        'status': status,
        'transaction_id': transactionId,
        'wallet_amount': walletAmount,
      };
}

class OrderTimestampsModel extends OrderTimestamps {
  const OrderTimestampsModel({
    required super.createdAt,
    super.updatedAt,
    super.confirmedAt,
    super.packedAt,
    super.pickedUpAt,
    super.outForDeliveryAt,
    super.deliveredAt,
  });

  factory OrderTimestampsModel.fromJson(Map<String, dynamic> json) {
    return OrderTimestampsModel(
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at'] as String)
          : null,
      packedAt: json['packed_at'] != null
          ? DateTime.parse(json['packed_at'] as String)
          : null,
      pickedUpAt: json['picked_up_at'] != null
          ? DateTime.parse(json['picked_up_at'] as String)
          : null,
      outForDeliveryAt: json['out_for_delivery_at'] != null
          ? DateTime.parse(json['out_for_delivery_at'] as String)
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'confirmed_at': confirmedAt?.toIso8601String(),
        'packed_at': packedAt?.toIso8601String(),
        'picked_up_at': pickedUpAt?.toIso8601String(),
        'out_for_delivery_at': outForDeliveryAt?.toIso8601String(),
        'delivered_at': deliveredAt?.toIso8601String(),
      };
}
