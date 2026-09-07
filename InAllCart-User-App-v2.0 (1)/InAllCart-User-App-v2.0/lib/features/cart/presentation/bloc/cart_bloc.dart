import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/cart.dart';
import '../../domain/usecases/cart_usecases.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class LoadCart extends CartEvent {}

class AddToCartEvent extends CartEvent {
  final int productId;
  final int quantity;
  final int? variantId;
  final String? productName;
  final String? productImage;
  final double? price;

  const AddToCartEvent({
    required this.productId,
    this.quantity = 1,
    this.variantId,
    this.productName,
    this.productImage,
    this.price,
  });

  @override
  List<Object?> get props => [productId, quantity, variantId];
}

class UpdateCartItemEvent extends CartEvent {
  final int itemId;
  final int quantity;

  const UpdateCartItemEvent({
    required this.itemId,
    required this.quantity,
  });

  @override
  List<Object?> get props => [itemId, quantity];
}

class RemoveFromCartEvent extends CartEvent {
  final int itemId;
  const RemoveFromCartEvent(this.itemId);

  @override
  List<Object?> get props => [itemId];
}

class ClearCartEvent extends CartEvent {}

class ApplyCouponEvent extends CartEvent {
  final String code;
  const ApplyCouponEvent(this.code);

  @override
  List<Object?> get props => [code];
}

class RemoveCouponEvent extends CartEvent {}

class SyncCartEvent extends CartEvent {}

/// Trigger a pre-checkout stock/price validation.
class ValidateCartEvent extends CartEvent {}

/// Internal event — emits [CartLoaded] with a pre-fetched cart.
/// Used by the debounce timer in [_onUpdateCartItem] to push the server
/// cart into the BLoC's event queue safely without a second network call.
class _EmitCartLoaded extends CartEvent {
  final Cart cart;
  const _EmitCartLoaded(this.cart);

  @override
  List<Object?> get props => [cart];
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

abstract class CartState extends Equatable {
  final Cart cart;
  const CartState(this.cart);

  @override
  List<Object?> get props => [cart];
}

class CartInitial extends CartState {
  const CartInitial()
      : super(const Cart(
          items: [],
          summary: CartSummary(
            itemsCount: 0,
            uniqueItems: 0,
            subtotal: 0,
            total: 0,
            totalWithDelivery: 0,
          ),
        ));
}

class CartLoading extends CartState {
  const CartLoading(super.cart);
}

/// Cart is loaded and up-to-date.
class CartLoaded extends CartState {
  const CartLoaded(super.cart);
}

/// An optimistic mutation is in-flight.
/// The [cart] field already reflects the expected outcome so the UI can
/// update instantly without waiting for the server response.
class CartUpdating extends CartState {
  const CartUpdating(super.cart);
}

class CartError extends CartState {
  final String message;
  const CartError(super.cart, this.message);

  @override
  List<Object?> get props => [cart, message];
}

class CartAuthRequired extends CartState {
  final String message;
  const CartAuthRequired(super.cart, this.message);

  @override
  List<Object?> get props => [cart, message];
}

class CartNoInternet extends CartState {
  final String message;
  const CartNoInternet(super.cart, this.message);

  @override
  List<Object?> get props => [cart, message];
}

class CartSyncing extends CartState {
  const CartSyncing(super.cart);
}

/// Validation completed — [issues] is empty when the cart is clean.
class CartValidated extends CartState {
  final List<Map<String, dynamic>> issues;
  const CartValidated(super.cart, this.issues);

  bool get isValid => issues.isEmpty;

  @override
  List<Object?> get props => [cart, issues];
}

// ---------------------------------------------------------------------------
// BLoC
// ---------------------------------------------------------------------------

class CartBloc extends Bloc<CartEvent, CartState> {
  final GetCart _getCart;
  final AddToCart _addToCart;
  final UpdateCartItem _updateCartItem;
  final LocalUpdateCartItem _localUpdateCartItem;
  final RemoveFromCart _removeFromCart;
  final ClearCart _clearCart;
  final ApplyCoupon _applyCoupon;
  final RemoveCoupon _removeCoupon;
  final SyncCart _syncCart;
  final ValidateCart _validateCart;

  /// Debounce timer for quantity update events.
  /// Rapid ± taps are collapsed into a single server call fired 400 ms after
  /// the last tap, preventing a queue of in-flight requests that could resolve
  /// out of order and leave the cart in a stale state.
  Timer? _quantityDebounce;

  CartBloc(
    this._getCart,
    this._addToCart,
    this._updateCartItem,
    this._localUpdateCartItem,
    this._removeFromCart,
    this._clearCart,
    this._applyCoupon,
    this._removeCoupon,
    this._syncCart,
    this._validateCart,
  ) : super(CartInitial()) {
    on<LoadCart>(_onLoadCart);
    on<AddToCartEvent>(_onAddToCart);
    on<UpdateCartItemEvent>(_onUpdateCartItem);
    on<RemoveFromCartEvent>(_onRemoveFromCart);
    on<ClearCartEvent>(_onClearCart);
    on<ApplyCouponEvent>(_onApplyCoupon);
    on<RemoveCouponEvent>(_onRemoveCoupon);
    on<SyncCartEvent>(_onSyncCart);
    on<ValidateCartEvent>(_onValidateCart);
    on<_EmitCartLoaded>(_onEmitCartLoaded);
  }

  @override
  Future<void> close() {
    _quantityDebounce?.cancel();
    return super.close();
  }

  // -------------------------------------------------------------------------
  // Handlers
  // -------------------------------------------------------------------------

  Future<void> _onLoadCart(LoadCart event, Emitter<CartState> emit) async {
    emit(CartLoading(state.cart));
    final result = await _getCart();
    result.fold(
      (failure) => emit(CartError(state.cart, failure.message)),
      (cart) => emit(CartLoaded(cart)),
    );
  }

  /// Optimistic add — emits [CartUpdating] with the expected cart immediately,
  /// then reconciles with the server response.
  Future<void> _onAddToCart(AddToCartEvent event, Emitter<CartState> emit) async {
    // Emit updating with current cart so the UI can show a spinner on the
    // specific item without blocking the whole page.
    emit(CartUpdating(state.cart));

    final result = await _addToCart(
      productId: event.productId,
      quantity: event.quantity,
      variantId: event.variantId,
      productName: event.productName,
      productImage: event.productImage,
      price: event.price,
    );

    result.fold(
      (failure) {
        if (failure is UnauthorizedFailure) {
          emit(CartAuthRequired(state.cart, 'Please login to add items to cart'));
        } else if (failure is NetworkFailure) {
          emit(CartNoInternet(state.cart, failure.message));
        } else {
          emit(CartError(state.cart, failure.message));
        }
      },
      (cart) => emit(CartLoaded(cart)),
    );
  }

  /// Optimistic update with debounce.
  ///
  /// How it works:
  ///   1. Every tap immediately updates Hive locally via [_localUpdateCartItem]
  ///      (a direct local datasource call — no server round-trip, no double-write).
  ///   2. The debounce timer is reset on every tap.
  ///   3. Only after 400 ms of silence does the server call fire via
  ///      [_updateCartItem], which sends the final quantity and returns the
  ///      authoritative server cart — no second LoadCart round-trip needed.
  ///
  /// Previous bug: both the immediate path and the debounce timer called
  /// [_updateCartItem], which internally does local-update + server-call.
  /// This caused a double Hive write on every debounce fire and could send
  /// two server requests for a single quantity change.
  Future<void> _onUpdateCartItem(
    UpdateCartItemEvent event,
    Emitter<CartState> emit,
  ) async {
    // 1. Apply optimistic local-only update immediately so the UI is instant.
    //    We call the use case in guest mode (local path only) by checking
    //    whether we're a guest, or we call the local datasource directly via
    //    the repository's local-only helper.
    emit(CartUpdating(state.cart));

    final localResult = await _localUpdateCartItem(
      itemId: event.itemId,
      quantity: event.quantity,
    );

    localResult.fold(
      (failure) {
        emit(CartError(state.cart, failure.message));
        return;
      },
      (localCart) => emit(CartLoaded(localCart)),
    );

    // 2. Debounce the server call — cancel any pending timer and restart it.
    //    Only the last tap in a rapid sequence reaches the server.
    _quantityDebounce?.cancel();
    _quantityDebounce = Timer(const Duration(milliseconds: 400), () async {
      if (isClosed) return;

      // Server-only call — the local state is already correct from step 1.
      final serverResult = await _updateCartItem(
        itemId: event.itemId,
        quantity: event.quantity,
      );

      if (!isClosed) {
        serverResult.fold(
          (failure) => add(LoadCart()), // fallback: full reload on server error
          (serverCart) => add(_EmitCartLoaded(serverCart)),
        );
      }
    });
  }

  /// Optimistic remove — same pattern as update.
  Future<void> _onRemoveFromCart(
    RemoveFromCartEvent event,
    Emitter<CartState> emit,
  ) async {
    emit(CartUpdating(state.cart));

    final result = await _removeFromCart(event.itemId);

    result.fold(
      (failure) => emit(CartError(state.cart, failure.message)),
      (cart) => emit(CartLoaded(cart)),
    );
  }

  Future<void> _onClearCart(ClearCartEvent event, Emitter<CartState> emit) async {
    emit(CartUpdating(state.cart));

    final result = await _clearCart();

    result.fold(
      (failure) => emit(CartError(state.cart, failure.message)),
      (cart) => emit(CartLoaded(cart)),
    );
  }

  Future<void> _onApplyCoupon(
    ApplyCouponEvent event,
    Emitter<CartState> emit,
  ) async {
    emit(CartUpdating(state.cart));

    final result = await _applyCoupon(event.code);

    result.fold(
      (failure) => emit(CartError(state.cart, failure.message)),
      (cart) => emit(CartLoaded(cart)),
    );
  }

  Future<void> _onRemoveCoupon(
    RemoveCouponEvent event,
    Emitter<CartState> emit,
  ) async {
    emit(CartUpdating(state.cart));

    final result = await _removeCoupon();

    result.fold(
      (failure) => emit(CartError(state.cart, failure.message)),
      (cart) => emit(CartLoaded(cart)),
    );
  }

  /// Sync guest cart to server after login.
  /// Uses the cart returned by syncCart() directly — no second getCart() call.
  Future<void> _onSyncCart(SyncCartEvent event, Emitter<CartState> emit) async {
    emit(CartSyncing(state.cart));

    final result = await _syncCart();

    result.fold(
      (failure) => emit(CartError(state.cart, failure.message)),
      // syncCart() now returns the merged Cart directly — eliminates the
      // previous double round-trip (sync + getCart).
      (cart) => emit(CartLoaded(cart)),
    );
  }

  Future<void> _onValidateCart(
    ValidateCartEvent event,
    Emitter<CartState> emit,
  ) async {
    // Don't show a loading spinner — validation is a silent pre-flight check.
    final result = await _validateCart();

    result.fold(
      (failure) => emit(CartError(state.cart, failure.message)),
      (issues) => emit(CartValidated(state.cart, issues)),
    );
  }

  /// Internal handler — emits [CartLoaded] with the cart provided by the
  /// debounce timer in [_onUpdateCartItem].
  void _onEmitCartLoaded(_EmitCartLoaded event, Emitter<CartState> emit) {
    emit(CartLoaded(event.cart));
  }
}
