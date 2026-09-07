import 'package:equatable/equatable.dart';
import '../../../address/domain/entities/address.dart';
import '../../../cart/domain/entities/cart.dart';

class CheckoutData extends Equatable {
  final Cart cart;
  final Address? selectedAddress;
  final PaymentMethod? selectedPaymentMethod;
  final String? notes;
  final String? couponCode;
  final bool useWallet;

  const CheckoutData({
    required this.cart,
    this.selectedAddress,
    this.selectedPaymentMethod,
    this.notes,
    this.couponCode,
    this.useWallet = false,
  });

  bool get isValid {
    // Address is always required regardless of payment method.
    if (cart.isEmpty || selectedAddress == null) {
      return false;
    }

    // Wallet-only: wallet toggle is on and no other payment method is needed.
    // The place-order logic validates whether the wallet balance actually
    // covers the full amount — we just confirm the address is present here.
    if (useWallet && selectedPaymentMethod == null) {
      return true;
    }

    // For all other cases a payment method must be selected.
    return selectedPaymentMethod != null;
  }

  CheckoutData copyWith({
    Cart? cart,
    Address? selectedAddress,
    PaymentMethod? selectedPaymentMethod,
    String? notes,
    String? couponCode,
    bool? useWallet,
  }) {
    return CheckoutData(
      cart: cart ?? this.cart,
      selectedAddress: selectedAddress ?? this.selectedAddress,
      selectedPaymentMethod: selectedPaymentMethod ?? this.selectedPaymentMethod,
      notes: notes ?? this.notes,
      couponCode: couponCode ?? this.couponCode,
      useWallet: useWallet ?? this.useWallet,
    );
  }

  @override
  List<Object?> get props => [
        cart,
        selectedAddress,
        selectedPaymentMethod,
        notes,
        couponCode,
        useWallet,
      ];
}

class PaymentMethod extends Equatable {
  final String id;
  final String name;
  final String type; // cod, razorpay, stripe, paystack, flutterwave, phonepe, paytm
  final String? icon;
  final bool isEnabled;
  final Map<String, dynamic>? config;

  const PaymentMethod({
    required this.id,
    required this.name,
    required this.type,
    this.icon,
    this.isEnabled = true,
    this.config,
  });

  bool get isCOD => type == 'cod';
  bool get isOnline => !isCOD;

  @override
  List<Object?> get props => [id, name, type, icon, isEnabled, config];
}

class PlaceOrderRequest extends Equatable {
  final List<OrderItemRequest> items;
  final int addressId;
  final String paymentMethod;
  final String orderType;
  final double driverTip;
  final String? notes;
  final String? couponCode;
  final bool useWallet;
  final String? prescriptionImagePath;

  const PlaceOrderRequest({
    required this.items,
    required this.addressId,
    required this.paymentMethod,
    this.orderType = 'delivery',
    this.driverTip = 0.0,
    this.notes,
    this.couponCode,
    this.useWallet = false,
    this.prescriptionImagePath,
  });

  Map<String, dynamic> toJson() => {
        'items': items.map((e) => e.toJson()).toList(),
        'address_id': addressId,
        'payment_method': paymentMethod,
        'order_type': orderType,
        'driver_tip': driverTip,
        if (notes != null) 'notes': notes,
        if (couponCode != null) 'coupon_code': couponCode,
        'use_wallet': useWallet,
        if (prescriptionImagePath != null) 'prescription_image': prescriptionImagePath,
      };

  @override
  List<Object?> get props => [items, addressId, paymentMethod, orderType, driverTip, notes, couponCode, useWallet, prescriptionImagePath];
}

class OrderItemRequest extends Equatable {
  final int productId;
  final int quantity;
  final int? variantId;

  const OrderItemRequest({
    required this.productId,
    required this.quantity,
    this.variantId,
  });

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'quantity': quantity,
        if (variantId != null) 'variant_id': variantId,
      };

  @override
  List<Object?> get props => [productId, quantity, variantId];
}
