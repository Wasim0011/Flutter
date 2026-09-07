import '../../domain/entities/cart.dart';

class CartModel extends Cart {
  const CartModel({
    super.storeId,
    super.store,
    required super.items,
    required super.summary,
    super.couponCode,
    super.couponDiscount,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    return CartModel(
      storeId: json['store_id'] as int?,
      store: json['store'] != null ? CartStoreModel.fromJson(json['store']) : null,
      items: (json['items'] as List?)
              ?.map((e) => CartItemModel.fromJson(e))
              .toList() ??
          [],
      summary: CartSummaryModel.fromJson(json['summary'] ?? {}),
      couponCode: json['coupon_code'] as String?,
      couponDiscount: _parseDouble(json['coupon_discount']),
    );
  }

  factory CartModel.empty() {
    return const CartModel(
      items: [],
      summary: CartSummaryModel(
        itemsCount: 0,
        uniqueItems: 0,
        subtotal: 0,
        total: 0,
        totalWithDelivery: 0,
      ),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() => {
        'store_id': storeId,
        // Persist the store object so it survives Hive round-trips.
        // Without this, cart.store is null after every app restart until
        // the next server fetch, causing the delivery time to show the
        // fallback '10-15' value instead of the real preparation_time.
        'store': store != null ? (store as CartStoreModel).toJson() : null,
        'items': items.map((e) => (e as CartItemModel).toJson()).toList(),
        'summary': (summary as CartSummaryModel).toJson(),
        'coupon_code': couponCode,
        'coupon_discount': couponDiscount,
      };
}

class CartItemModel extends CartItem {
  const CartItemModel({
    required super.id,
    required super.productId,
    required super.productName,
    super.productImage,
    required super.price,
    super.comparePrice,
    required super.quantity,
    super.unit,
    super.variantId,
    super.variantName,
    super.synced,
    super.storeId,
    super.inStock,
    super.availableQuantity,
    super.categoryId,
    super.isPrescriptionRequired,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    // Handle nested product object from backend
    final product = json['product'] as Map<String, dynamic>?;
    
    return CartItemModel(
      id: json['id'] as int? ?? 0,
      productId: json['product_id'] as int? ?? product?['id'] as int? ?? 0,
      productName: product?['name'] as String? ?? json['product_name'] as String? ?? '',
      productImage: product?['image'] as String? ?? json['product_image'] as String?,
      price: _parseDouble(json['price'] ?? product?['price']),
      comparePrice: _parseDouble(product?['compare_price'] ?? json['compare_price']),
      quantity: json['quantity'] as int? ?? 1,
      unit: json['unit'] as String?,
      variantId: json['variant_id'] as int?,
      variantName: json['variant_name'] as String?,
      synced: json['synced'] as bool? ?? true,
      storeId: product?['store_id'] as int?,
      inStock: product?['in_stock'] as bool? ?? true,
      availableQuantity: product?['available_quantity'] as int? ?? 0,
      categoryId: product?['category_id'] as int?,
      isPrescriptionRequired: product?['is_prescription_required'] == true ||
          product?['is_prescription_required'] == 1 ||
          product?['health_info']?['is_prescription_required'] == true ||
          product?['health_info']?['is_prescription_required'] == 1 ||
          json['is_prescription_required'] == true ||
          json['is_prescription_required'] == 1,
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
        'product_name': productName,
        'product_image': productImage,
        'price': price,
        'compare_price': comparePrice,
        'quantity': quantity,
        'unit': unit,
        'variant_id': variantId,
        'variant_name': variantName,
        'synced': synced,
        'store_id': storeId,
        'in_stock': inStock,
        'available_quantity': availableQuantity,
        'category_id': categoryId,
      };

  @override
  CartItemModel copyWith({
    int? id,
    int? productId,
    String? productName,
    String? productImage,
    double? price,
    double? comparePrice,
    int? quantity,
    String? unit,
    int? variantId,
    String? variantName,
    bool? synced,
    int? storeId,
    bool? inStock,
    int? availableQuantity,
    int? categoryId,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      price: price ?? this.price,
      comparePrice: comparePrice ?? this.comparePrice,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      variantId: variantId ?? this.variantId,
      variantName: variantName ?? this.variantName,
      synced: synced ?? this.synced,
      storeId: storeId ?? this.storeId,
      inStock: inStock ?? this.inStock,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      categoryId: categoryId ?? this.categoryId,
    );
  }
}

class CartSummaryModel extends CartSummary {
  const CartSummaryModel({
    required super.itemsCount,
    required super.uniqueItems,
    required super.subtotal,
    super.discount,
    super.deliveryCharge,
    super.deliveryBreakdown,
    super.tax,
    required super.total,
    required super.totalWithDelivery,
  });

  factory CartSummaryModel.fromJson(Map<String, dynamic> json) {
    return CartSummaryModel(
      itemsCount: json['items_count'] as int? ?? 0,
      uniqueItems: json['unique_items'] as int? ?? 0,
      subtotal: _parseDouble(json['subtotal']),
      discount: _parseDouble(json['discount']),
      deliveryCharge: _parseDouble(json['delivery_charge']),
      deliveryBreakdown: json['delivery_breakdown'] != null
          ? DeliveryBreakdownModel.fromJson(json['delivery_breakdown'])
          : null,
      tax: _parseDouble(json['tax']),
      total: _parseDouble(json['total']),
      totalWithDelivery: _parseDouble(json['total_with_delivery']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() => {
        'items_count': itemsCount,
        'unique_items': uniqueItems,
        'subtotal': subtotal,
        'discount': discount,
        'delivery_charge': deliveryCharge,
        'delivery_breakdown': deliveryBreakdown != null
            ? (deliveryBreakdown as DeliveryBreakdownModel).toJson()
            : null,
        'tax': tax,
        'total': total,
        'total_with_delivery': totalWithDelivery,
      };
}

class DeliveryBreakdownModel extends DeliveryBreakdown {
  const DeliveryBreakdownModel({
    required super.strategy,
    required super.method,
    required super.baseFee,
    required super.distanceFee,
    required super.zoneFee,
    required super.total,
    required super.isFree,
    required super.breakdownText,
    required super.steps,
  });

  factory DeliveryBreakdownModel.fromJson(Map<String, dynamic> json) {
    return DeliveryBreakdownModel(
      strategy: json['strategy'] as String? ?? '',
      method: json['method'] as String? ?? '',
      baseFee: _parseDouble(json['base_fee']),
      distanceFee: _parseDouble(json['distance_fee']),
      zoneFee: _parseDouble(json['zone_fee']),
      total: _parseDouble(json['total']),
      isFree: json['is_free'] as bool? ?? false,
      breakdownText: json['breakdown_text'] as String? ?? '',
      steps: (json['steps'] as List?)?.map((e) => e as String).toList() ?? [],
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() => {
        'strategy': strategy,
        'method': method,
        'base_fee': baseFee,
        'distance_fee': distanceFee,
        'zone_fee': zoneFee,
        'total': total,
        'is_free': isFree,
        'breakdown_text': breakdownText,
        'steps': steps,
      };
}

class CartStoreModel extends CartStore {
  const CartStoreModel({
    required super.id,
    required super.name,
    super.logo,
    super.address,
    super.preparationTime,
    super.deliveryEnabled = true,
    super.pickupEnabled = true,
  });

  factory CartStoreModel.fromJson(Map<String, dynamic> json) {
    return CartStoreModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      logo: json['logo'] as String?,
      address: json['address'] as String?,
      preparationTime: (json['preparation_time'] ?? json['delivery_time'])?.toString(),
      deliveryEnabled: json['delivery_enabled'] as bool? ?? true,
      pickupEnabled: json['pickup_enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'logo': logo,
        'address': address,
        'preparation_time': preparationTime,
        'delivery_enabled': deliveryEnabled,
        'pickup_enabled': pickupEnabled,
      };
}
