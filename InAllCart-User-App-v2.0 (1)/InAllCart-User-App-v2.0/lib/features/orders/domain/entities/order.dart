import 'package:equatable/equatable.dart';
import '../../../address/domain/entities/address.dart';

class Order extends Equatable {
  final int id;
  final String orderNumber;
  final OrderStatus status;
  final List<OrderItem> items;
  final OrderPricing pricing;
  final Address? address;
  final OrderPayment payment;
  final String? notes;
  final String? deliveryOtp;
  final OrderTimestamps timestamps;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.items,
    required this.pricing,
    this.address,
    required this.payment,
    this.notes,
    this.deliveryOtp,
    required this.timestamps,
  });

  @override
  List<Object?> get props => [
        id,
        orderNumber,
        status,
        items,
        pricing,
        address,
        payment,
        notes,
        deliveryOtp,
        timestamps,
      ];
}

class OrderItem extends Equatable {
  final int id;
  final int productId;
  final int? variantId;
  final String productName;
  final String? variantName;
  final String? productImage;
  final String productSku;
  final int quantity;
  final double price;
  final double total;

  const OrderItem({
    required this.id,
    required this.productId,
    this.variantId,
    required this.productName,
    this.variantName,
    this.productImage,
    required this.productSku,
    required this.quantity,
    required this.price,
    required this.total,
  });

  @override
  List<Object?> get props => [
        id,
        productId,
        variantId,
        productName,
        variantName,
        productImage,
        productSku,
        quantity,
        price,
        total,
      ];
}

class OrderStatus extends Equatable {
  final String value;
  final String label;
  final String color;

  const OrderStatus({
    required this.value,
    required this.label,
    required this.color,
  });

  bool get isPending => value == 'pending';
  bool get isConfirmed => value == 'confirmed';
  bool get isPacked => value == 'packed';
  bool get isPickedUp => value == 'picked_up';
  bool get isOutForDelivery => value == 'out_for_delivery';
  bool get isDelivered => value == 'delivered';
  bool get isCancelled => value == 'cancelled';
  bool get canBeCancelled => isPending || isConfirmed || isPacked;

  @override
  List<Object?> get props => [value, label, color];
}

class OrderPricing extends Equatable {
  final double subtotal;
  final double discount;
  final double deliveryFee;
  final double driverTip;
  final double tax;
  final double total;
  final String? formattedSubtotal;
  final String? formattedDiscount;
  final String? formattedDeliveryFee;
  final String? formattedDriverTip;
  final String? formattedTax;
  final String? formattedTotal;
  final String? currency;
  final String? currencySymbol;

  const OrderPricing({
    required this.subtotal,
    this.discount = 0,
    this.deliveryFee = 0,
    this.driverTip = 0,
    this.tax = 0,
    required this.total,
    this.formattedSubtotal,
    this.formattedDiscount,
    this.formattedDeliveryFee,
    this.formattedDriverTip,
    this.formattedTax,
    this.formattedTotal,
    this.currency,
    this.currencySymbol,
  });

  @override
  List<Object?> get props => [
        subtotal,
        discount,
        deliveryFee,
        driverTip,
        tax,
        total,
        formattedSubtotal,
        formattedDiscount,
        formattedDeliveryFee,
        formattedDriverTip,
        formattedTax,
        formattedTotal,
        currency,
        currencySymbol,
      ];
}

class OrderPayment extends Equatable {
  final String method;
  final String status;
  final String? transactionId;
  final double? walletAmount;

  const OrderPayment({
    required this.method,
    required this.status,
    this.transactionId,
    this.walletAmount,
  });

  bool get isPaid => status == 'paid';
  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';
  bool get hasWalletPayment => walletAmount != null && walletAmount! > 0;

  @override
  List<Object?> get props => [method, status, transactionId, walletAmount];
}

class OrderTimestamps extends Equatable {
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? confirmedAt;
  final DateTime? packedAt;
  final DateTime? pickedUpAt;
  final DateTime? outForDeliveryAt;
  final DateTime? deliveredAt;

  const OrderTimestamps({
    required this.createdAt,
    this.updatedAt,
    this.confirmedAt,
    this.packedAt,
    this.pickedUpAt,
    this.outForDeliveryAt,
    this.deliveredAt,
  });

  @override
  List<Object?> get props => [
        createdAt,
        updatedAt,
        confirmedAt,
        packedAt,
        pickedUpAt,
        outForDeliveryAt,
        deliveredAt,
      ];
}

class OrderTrackingTimeline extends Equatable {
  final String status;
  final String label;
  final bool completed;
  final DateTime? date;

  const OrderTrackingTimeline({
    required this.status,
    required this.label,
    required this.completed,
    this.date,
  });

  @override
  List<Object?> get props => [status, label, completed, date];
}
