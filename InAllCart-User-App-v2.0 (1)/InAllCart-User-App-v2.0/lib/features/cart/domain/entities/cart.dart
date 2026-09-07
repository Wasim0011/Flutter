import 'package:equatable/equatable.dart';

class Cart extends Equatable {
  final int? storeId;
  final CartStore? store;
  final List<CartItem> items;
  final CartSummary summary;
  final String? couponCode;
  final double? couponDiscount;

  const Cart({
    this.storeId,
    this.store,
    required this.items,
    required this.summary,
    this.couponCode,
    this.couponDiscount,
  });

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => summary.subtotal;
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  bool get isSingleVendor => storeId != null;

  CartItem? getItem(int productId, {int? variantId}) {
    try {
      return items.firstWhere(
        (item) => item.productId == productId && item.variantId == variantId,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [storeId, store, items, summary, couponCode, couponDiscount];
}

class CartStore extends Equatable {
  final int id;
  final String name;
  final String? logo;
  final String? address;
  final String? preparationTime;
  final bool deliveryEnabled;
  final bool pickupEnabled;

  const CartStore({
    required this.id,
    required this.name,
    this.logo,
    this.address,
    this.preparationTime,
    this.deliveryEnabled = true,
    this.pickupEnabled = true,
  });

  @override
  List<Object?> get props => [id, name, logo, address, preparationTime, deliveryEnabled, pickupEnabled];
}

class CartItem extends Equatable {
  final int id;
  final int productId;
  final String productName;
  final String? productImage;
  final double price;
  final double? comparePrice;
  final int quantity;
  final String? unit;
  final int? variantId;
  final String? variantName;
  final bool synced; // For offline support
  final int? storeId;
  final bool inStock;
  final int availableQuantity;
  final int? categoryId;
  final bool isPrescriptionRequired;

  const CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.price,
    this.comparePrice,
    required this.quantity,
    this.unit,
    this.variantId,
    this.variantName,
    this.synced = true,
    this.storeId,
    this.inStock = true,
    this.availableQuantity = 0,
    this.categoryId,
    this.isPrescriptionRequired = false,
  });

  double get total => price * quantity;
  bool get hasStockIssue => !inStock || quantity > availableQuantity;
  bool get hasDiscount => comparePrice != null && comparePrice! > price;

  CartItem copyWith({
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
    return CartItem(
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

  @override
  List<Object?> get props => [
        id,
        productId,
        quantity,
        variantId,
        synced,
        storeId,
        inStock,
        availableQuantity,
      ];
}

class CartSummary extends Equatable {
  final int itemsCount;
  final int uniqueItems;
  final double subtotal;
  final double discount;
  final double deliveryCharge;
  final DeliveryBreakdown? deliveryBreakdown;
  final double tax;
  final double total;
  final double totalWithDelivery;

  const CartSummary({
    required this.itemsCount,
    required this.uniqueItems,
    required this.subtotal,
    this.discount = 0,
    this.deliveryCharge = 0,
    this.deliveryBreakdown,
    this.tax = 0,
    required this.total,
    required this.totalWithDelivery,
  });

  @override
  List<Object?> get props => [
        itemsCount,
        uniqueItems,
        subtotal,
        discount,
        deliveryCharge,
        deliveryBreakdown,
        tax,
        total,
        totalWithDelivery,
      ];
}

class DeliveryBreakdown extends Equatable {
  final String strategy;
  final String method;
  final double baseFee;
  final double distanceFee;
  final double zoneFee;
  final double total;
  final bool isFree;
  final String breakdownText;
  final List<String> steps;

  const DeliveryBreakdown({
    required this.strategy,
    required this.method,
    required this.baseFee,
    required this.distanceFee,
    required this.zoneFee,
    required this.total,
    required this.isFree,
    required this.breakdownText,
    required this.steps,
  });

  @override
  List<Object?> get props => [
        strategy,
        method,
        baseFee,
        distanceFee,
        zoneFee,
        total,
        isFree,
        breakdownText,
        steps,
      ];
}
