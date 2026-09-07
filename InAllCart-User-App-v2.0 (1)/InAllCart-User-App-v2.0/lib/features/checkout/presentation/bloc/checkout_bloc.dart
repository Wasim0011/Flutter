import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/checkout_data.dart';
import '../../../orders/domain/entities/order.dart' as order_entity;
import '../../../orders/domain/usecases/place_order.dart';
import '../../../address/domain/entities/address.dart';
import '../../../cart/domain/entities/cart.dart';
import '../../../../core/services/payment_gateway_service.dart';

// Events
abstract class CheckoutEvent extends Equatable {
  const CheckoutEvent();

  @override
  List<Object?> get props => [];
}

class InitializeCheckout extends CheckoutEvent {
  final Cart cart;
  const InitializeCheckout(this.cart);

  @override
  List<Object?> get props => [cart];
}

class LoadPaymentMethods extends CheckoutEvent {}

class SelectAddress extends CheckoutEvent {
  final Address address;
  const SelectAddress(this.address);

  @override
  List<Object?> get props => [address];
}

class SelectPaymentMethod extends CheckoutEvent {
  final PaymentMethod method;
  const SelectPaymentMethod(this.method);

  @override
  List<Object?> get props => [method];
}

class UpdateOrderNotes extends CheckoutEvent {
  final String notes;
  const UpdateOrderNotes(this.notes);

  @override
  List<Object?> get props => [notes];
}

class ToggleWallet extends CheckoutEvent {
  final bool useWallet;
  const ToggleWallet(this.useWallet);

  @override
  List<Object?> get props => [useWallet];
}

class PlaceOrderEvent extends CheckoutEvent {
  /// [context] is kept here only for payment-gateway SDK calls that require
  /// a BuildContext (Paystack, Flutterwave, PhonePe, Paytm overlay UIs).
  /// It is NOT stored in BLoC state — it is used transiently inside the
  /// handler and never serialised or compared.
  ///
  /// For COD and wallet-only orders no context is needed; pass
  /// `BuildContext? context = null` and the handler skips gateway processing.
  final BuildContext? context;

  const PlaceOrderEvent([this.context]);

  @override
  List<Object?> get props => []; // context intentionally excluded from equality
}

/// Atomic order placement — carries all required data so no sequential
/// event-chaining race condition can occur. Use this instead of firing
/// InitializeCheckout → SelectAddress → SelectPaymentMethod → PlaceOrderEvent
/// back-to-back.
class PlaceOrderDirectEvent extends CheckoutEvent {
  final Cart cart;
  final Address address;
  final PaymentMethod? paymentMethod;
  final bool useWallet;
  final String orderType;
  final double driverTip;
  final String? prescriptionImagePath;

  /// [context] is only needed for online payment gateway SDK overlays.
  /// COD and wallet-only orders do not require it.
  final BuildContext? context;

  const PlaceOrderDirectEvent({
    required this.cart,
    required this.address,
    this.paymentMethod,
    required this.useWallet,
    this.orderType = 'delivery',
    this.driverTip = 0.0,
    this.prescriptionImagePath,
    this.context,
  });

  @override
  List<Object?> get props => [cart, address, paymentMethod, useWallet, orderType, driverTip, prescriptionImagePath];
  // context intentionally excluded from equality
}

class ProcessPaymentEvent extends CheckoutEvent {
  final order_entity.Order order;

  /// [context] is required for gateway SDK overlays (Paystack, Flutterwave,
  /// PhonePe, Paytm). It is used transiently and never stored in state.
  final BuildContext context;

  const ProcessPaymentEvent(this.order, this.context);

  @override
  List<Object?> get props => [order]; // context excluded from equality
}

// States
abstract class CheckoutState extends Equatable {
  final CheckoutData? checkoutData;
  final List<PaymentMethodInfo> paymentMethods;

  const CheckoutState({
    this.checkoutData,
    this.paymentMethods = const [],
  });

  @override
  List<Object?> get props => [checkoutData, paymentMethods];
}

class CheckoutInitial extends CheckoutState {}

class CheckoutLoading extends CheckoutState {
  const CheckoutLoading({super.checkoutData, super.paymentMethods});
}

class CheckoutReady extends CheckoutState {
  const CheckoutReady({
    required super.checkoutData,
    required super.paymentMethods,
  });
}

class CheckoutProcessing extends CheckoutState {
  const CheckoutProcessing({super.checkoutData, super.paymentMethods});
}

class CheckoutPaymentProcessing extends CheckoutState {
  final order_entity.Order order;

  const CheckoutPaymentProcessing({
    required this.order,
    super.checkoutData,
    super.paymentMethods,
  });

  @override
  List<Object?> get props => [order, checkoutData, paymentMethods];
}

class CheckoutSuccess extends CheckoutState {
  final order_entity.Order order;

  const CheckoutSuccess({
    required this.order,
    super.checkoutData,
    super.paymentMethods,
  });

  @override
  List<Object?> get props => [order, checkoutData, paymentMethods];
}

class CheckoutError extends CheckoutState {
  final String message;

  const CheckoutError({
    required this.message,
    super.checkoutData,
    super.paymentMethods,
  });

  @override
  List<Object?> get props => [message, checkoutData, paymentMethods];
}

// BLoC
class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  final PaymentGatewayService _paymentService;
  final PlaceOrder _placeOrder;

  /// Injected at construction time from the AuthBloc so payment gateways
  /// receive the user's real email instead of an empty string.
  final String _userEmail;
  final String _userPhone;

  CheckoutBloc(
    this._paymentService,
    this._placeOrder, {
    String userEmail = '',
    String userPhone = '',
  })  : _userEmail = userEmail,
        _userPhone = userPhone,
        super(CheckoutInitial()) {
    on<InitializeCheckout>(_onInitializeCheckout);
    on<LoadPaymentMethods>(_onLoadPaymentMethods);
    on<SelectAddress>(_onSelectAddress);
    on<SelectPaymentMethod>(_onSelectPaymentMethod);
    on<UpdateOrderNotes>(_onUpdateOrderNotes);
    on<ToggleWallet>(_onToggleWallet);
    on<PlaceOrderEvent>(_onPlaceOrder);
    on<PlaceOrderDirectEvent>(_onPlaceOrderDirect);
    on<ProcessPaymentEvent>(_onProcessPayment);
  }

  void _onInitializeCheckout(
    InitializeCheckout event,
    Emitter<CheckoutState> emit,
  ) {
    final existing = state.checkoutData;
    emit(CheckoutReady(
      // If checkout was already initialized, refresh the cart and carry the
      // cart's coupon code forward so it is sent with the order request.
      // All other user selections (address, payment method, notes, wallet)
      // are preserved.
      checkoutData: existing != null
          ? existing.copyWith(
              cart: event.cart,
              couponCode: event.cart.couponCode,
            )
          : CheckoutData(
              cart: event.cart,
              couponCode: event.cart.couponCode,
            ),
      paymentMethods: state.paymentMethods,
    ));
  }

  Future<void> _onLoadPaymentMethods(
    LoadPaymentMethods event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(CheckoutLoading(
      checkoutData: state.checkoutData,
      paymentMethods: state.paymentMethods,
    ));

    try {
      final methods = await _paymentService.getPaymentMethods();
      emit(CheckoutReady(
        checkoutData: state.checkoutData,
        paymentMethods: methods,
      ));
    } catch (e) {
      emit(CheckoutError(
        message: 'Failed to load payment methods: $e',
        checkoutData: state.checkoutData,
        paymentMethods: state.paymentMethods,
      ));
    }
  }

  void _onSelectAddress(SelectAddress event, Emitter<CheckoutState> emit) {
    final currentData = state.checkoutData;
    
    if (currentData != null) {
      final updatedData = currentData.copyWith(selectedAddress: event.address);
      
      emit(CheckoutReady(
        checkoutData: updatedData,
        paymentMethods: state.paymentMethods,
      ));
    }
  }

  void _onSelectPaymentMethod(
    SelectPaymentMethod event,
    Emitter<CheckoutState> emit,
  ) {
    final currentData = state.checkoutData;
    if (currentData != null) {
      emit(CheckoutReady(
        checkoutData: currentData.copyWith(
          selectedPaymentMethod: PaymentMethod(
            id: event.method.id,
            name: event.method.name,
            type: event.method.type,
            icon: event.method.icon,
            isEnabled: event.method.isEnabled,
            config: event.method.config,
          ),
        ),
        paymentMethods: state.paymentMethods,
      ));
    }
  }

  void _onUpdateOrderNotes(
    UpdateOrderNotes event,
    Emitter<CheckoutState> emit,
  ) {
    final currentData = state.checkoutData;
    if (currentData != null) {
      emit(CheckoutReady(
        checkoutData: currentData.copyWith(notes: event.notes),
        paymentMethods: state.paymentMethods,
      ));
    }
  }

  void _onToggleWallet(
    ToggleWallet event,
    Emitter<CheckoutState> emit,
  ) {
    final currentData = state.checkoutData;
    if (currentData != null) {
      emit(CheckoutReady(
        checkoutData: currentData.copyWith(useWallet: event.useWallet),
        paymentMethods: state.paymentMethods,
      ));
    }
  }

  Future<void> _onPlaceOrder(
    PlaceOrderEvent event,
    Emitter<CheckoutState> emit,
  ) async {
    final checkoutData = state.checkoutData;
    
    if (checkoutData == null || !checkoutData.isValid) {
      emit(CheckoutError(
        message: 'Please complete all required fields',
        checkoutData: checkoutData,
        paymentMethods: state.paymentMethods,
      ));
      return;
    }

    emit(CheckoutProcessing(
      checkoutData: checkoutData,
      paymentMethods: state.paymentMethods,
    ));

    try {
      // Determine payment method
      // If wallet is used and payment method is null, use 'wallet' as payment method
      String paymentMethodType;
      bool isWalletOnly = false;
      
      if (checkoutData.selectedPaymentMethod != null) {
        paymentMethodType = checkoutData.selectedPaymentMethod!.type;
      } else if (checkoutData.useWallet) {
        // Wallet covers full amount, no other payment method needed
        paymentMethodType = 'wallet';
        isWalletOnly = true;
      } else {
        emit(CheckoutError(
          message: 'Please select a payment method',
          checkoutData: checkoutData,
          paymentMethods: state.paymentMethods,
        ));
        return;
      }
      
      // Create order request
      final request = PlaceOrderRequest(
        items: checkoutData.cart.items
            .map((item) => OrderItemRequest(
                  productId: item.productId,
                  quantity: item.quantity,
                  variantId: item.variantId,
                ))
            .toList(),
        addressId: checkoutData.selectedAddress!.id,
        paymentMethod: paymentMethodType,
        notes: checkoutData.notes,
        couponCode: checkoutData.couponCode,
        useWallet: checkoutData.useWallet,
      );

      // Place order via repository
      final result = await _placeOrder(request);

      result.fold(
        (failure) {
          emit(CheckoutError(
            message: failure.message,
            checkoutData: checkoutData,
            paymentMethods: state.paymentMethods,
          ));
        },
        (order) {
          // If payment is COD or wallet-only, order is complete
          final isCOD = checkoutData.selectedPaymentMethod?.isCOD ?? false;
          if (isCOD || isWalletOnly) {
            emit(CheckoutSuccess(
              order: order,
              checkoutData: checkoutData,
              paymentMethods: state.paymentMethods,
            ));
          } else {
            // Process online payment — context is required for gateway SDKs.
            if (event.context != null) {
              add(ProcessPaymentEvent(order, event.context!));
            } else {
              emit(CheckoutError(
                message: 'Payment context unavailable. Please retry.',
                checkoutData: checkoutData,
                paymentMethods: state.paymentMethods,
              ));
            }
          }
        },
      );
    } catch (e) {
      emit(CheckoutError(
        message: 'Failed to place order: $e',
        checkoutData: checkoutData,
        paymentMethods: state.paymentMethods,
      ));
    }
  }

  /// Atomic order placement — all required data is passed in a single event,
  /// eliminating the sequential-event race condition of the old flow.
  Future<void> _onPlaceOrderDirect(
    PlaceOrderDirectEvent event,
    Emitter<CheckoutState> emit,
  ) async {
    // Build a fresh CheckoutData from the event payload so we never rely on
    // stale BLoC state that may not have settled from prior events.
    final checkoutData = CheckoutData(
      cart: event.cart,
      selectedAddress: event.address,
      selectedPaymentMethod: event.paymentMethod,
      useWallet: event.useWallet,
      // Carry coupon code from the cart entity (Bug 4 fix).
      couponCode: event.cart.couponCode,
      // Preserve notes from existing checkout state if available.
      notes: state.checkoutData?.notes,
    );

    if (!checkoutData.isValid) {
      emit(CheckoutError(
        message: 'Please complete all required fields',
        checkoutData: checkoutData,
        paymentMethods: state.paymentMethods,
      ));
      return;
    }

    emit(CheckoutProcessing(
      checkoutData: checkoutData,
      paymentMethods: state.paymentMethods,
    ));

    try {
      String paymentMethodType;
      bool isWalletOnly = false;

      if (checkoutData.selectedPaymentMethod != null) {
        paymentMethodType = checkoutData.selectedPaymentMethod!.type;
      } else if (checkoutData.useWallet) {
        paymentMethodType = 'wallet';
        isWalletOnly = true;
      } else {
        emit(CheckoutError(
          message: 'Please select a payment method',
          checkoutData: checkoutData,
          paymentMethods: state.paymentMethods,
        ));
        return;
      }

      final request = PlaceOrderRequest(
        items: checkoutData.cart.items
            .map((item) => OrderItemRequest(
                  productId: item.productId,
                  quantity: item.quantity,
                  variantId: item.variantId,
                ))
            .toList(),
        addressId: checkoutData.selectedAddress!.id,
        paymentMethod: paymentMethodType,
        orderType: event.orderType,
        driverTip: event.driverTip,
        notes: checkoutData.notes,
        couponCode: checkoutData.couponCode,
        useWallet: checkoutData.useWallet,
        prescriptionImagePath: event.prescriptionImagePath,
      );

      final result = await _placeOrder(request);

      result.fold(
        (failure) {
          emit(CheckoutError(
            message: failure.message,
            checkoutData: checkoutData,
            paymentMethods: state.paymentMethods,
          ));
        },
        (order) {
          final isCOD = checkoutData.selectedPaymentMethod?.isCOD ?? false;
          if (isCOD || isWalletOnly) {
            emit(CheckoutSuccess(
              order: order,
              checkoutData: checkoutData,
              paymentMethods: state.paymentMethods,
            ));
          } else {
            if (event.context != null) {
              add(ProcessPaymentEvent(order, event.context!));
            } else {
              emit(CheckoutError(
                message: 'Payment context unavailable. Please retry.',
                checkoutData: checkoutData,
                paymentMethods: state.paymentMethods,
              ));
            }
          }
        },
      );
    } catch (e) {
      emit(CheckoutError(
        message: 'Failed to place order: $e',
        checkoutData: state.checkoutData,
        paymentMethods: state.paymentMethods,
      ));
    }
  }

  Future<void> _onProcessPayment(
    ProcessPaymentEvent event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(CheckoutPaymentProcessing(
      order: event.order,
      checkoutData: state.checkoutData,
      paymentMethods: state.paymentMethods,
    ));

    final checkoutData = state.checkoutData;
    if (checkoutData == null || checkoutData.selectedPaymentMethod == null) {
      emit(CheckoutError(
        message: 'Payment method not selected',
        checkoutData: checkoutData,
        paymentMethods: state.paymentMethods,
      ));
      return;
    }

    final paymentMethod = checkoutData.selectedPaymentMethod!;

    try {
      // Step 1: Initialize payment with backend
      final initData = await _paymentService.initializePayment(
        orderId: event.order.id,
        amount: event.order.pricing.total,
        paymentMethod: paymentMethod.type,
        currency: 'USD', // Get from config
      );

      // Step 2: Process payment based on gateway type
      PaymentSuccessData? paymentResult;

      // The gateway-specific calls below need a live BuildContext to present
      // their native payment UIs. Bail out if the checkout view is gone.
      if (!event.context.mounted) return;

      switch (paymentMethod.type.toLowerCase()) {
        case 'razorpay':
          paymentResult = await _processRazorpayPayment(
            initData: initData,
            checkoutData: checkoutData,
          );
          break;

        case 'stripe':
          paymentResult = await _processStripePayment(
            initData: initData,
            checkoutData: checkoutData,
          );
          break;

        case 'paystack':
          paymentResult = await _processPaystackPayment(
            initData: initData,
            checkoutData: checkoutData,
            context: event.context,
          );
          break;

        case 'flutterwave':
          paymentResult = await _processFlutterwavePayment(
            initData: initData,
            checkoutData: checkoutData,
            context: event.context,
          );
          break;

        case 'phonepe':
          paymentResult = await _processPhonePePayment(
            initData: initData,
            checkoutData: checkoutData,
            context: event.context,
          );
          break;

        case 'paytm':
          paymentResult = await _processPaytmPayment(
            initData: initData,
            checkoutData: checkoutData,
            context: event.context,
          );
          break;

        default:
          throw Exception('Unsupported payment method: ${paymentMethod.type}');
      }

      if (paymentResult != null) {
        // Step 3: Verify payment with backend
        final verified = await _paymentService.verifyPayment(
          orderId: event.order.id,
          paymentId: paymentResult.paymentId,
          paymentMethod: paymentMethod.type,
          additionalData: {
            if (paymentResult.signature != null)
              'signature': paymentResult.signature,
          },
        );

        if (verified) {
          emit(CheckoutSuccess(
            order: event.order,
            checkoutData: checkoutData,
            paymentMethods: state.paymentMethods,
          ));
        } else {
          emit(CheckoutError(
            message: 'Payment verification failed',
            checkoutData: checkoutData,
            paymentMethods: state.paymentMethods,
          ));
        }
      }
    } catch (e) {
      emit(CheckoutError(
        message: 'Payment processing failed: $e',
        checkoutData: checkoutData,
        paymentMethods: state.paymentMethods,
      ));
    }
  }

  Future<PaymentSuccessData?> _processRazorpayPayment({
    required PaymentInitData initData,
    required CheckoutData checkoutData,
  }) async {
    final completer = Completer<PaymentSuccessData?>();

    await _paymentService.processRazorpayPayment(
      initData: initData,
      name: checkoutData.selectedAddress?.name ?? '',
      email: _userEmail,
      phone: checkoutData.selectedAddress?.phone ?? _userPhone,
      onSuccess: (data) {
        completer.complete(data);
      },
      onError: (error) {
        completer.completeError(error.message);
      },
    );

    return completer.future;
  }

  Future<PaymentSuccessData?> _processStripePayment({
    required PaymentInitData initData,
    required CheckoutData checkoutData,
  }) async {
    return await _paymentService.processStripePayment(
      initData: initData,
      email: _userEmail,
    );
  }

  Future<PaymentSuccessData?> _processPaystackPayment({
    required PaymentInitData initData,
    required CheckoutData checkoutData,
    required BuildContext context,
  }) async {
    return await _paymentService.processPaystackPayment(
      initData: initData,
      context: context,
    );
  }

  Future<PaymentSuccessData?> _processFlutterwavePayment({
    required PaymentInitData initData,
    required CheckoutData checkoutData,
    required BuildContext context,
  }) async {
    return await _paymentService.processFlutterwavePayment(
      initData: initData,
      context: context,
    );
  }

  Future<PaymentSuccessData?> _processPhonePePayment({
    required PaymentInitData initData,
    required CheckoutData checkoutData,
    required BuildContext context,
  }) async {
    return await _paymentService.processPhonePePayment(
      initData: initData,
      context: context,
    );
  }

  Future<PaymentSuccessData?> _processPaytmPayment({
    required PaymentInitData initData,
    required CheckoutData checkoutData,
    required BuildContext context,
  }) async {
    return await _paymentService.processPaytmPayment(
      initData: initData,
      context: context,
    );
  }
}
