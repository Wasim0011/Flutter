import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/cart.dart';
import '../repositories/cart_repository.dart';

class GetCart {
  final CartRepository _repository;
  GetCart(this._repository);
  Future<Either<Failure, Cart>> call() => _repository.getCart();
}

class AddToCart {
  final CartRepository _repository;
  AddToCart(this._repository);
  Future<Either<Failure, Cart>> call({
    required int productId,
    required int quantity,
    int? variantId,
    String? productName,
    String? productImage,
    double? price,
  }) =>
      _repository.addToCart(
        productId: productId,
        quantity: quantity,
        variantId: variantId,
        productName: productName,
        productImage: productImage,
        price: price,
      );
}

class UpdateCartItem {
  final CartRepository _repository;
  UpdateCartItem(this._repository);
  Future<Either<Failure, Cart>> call({
    required int itemId,
    required int quantity,
  }) =>
      _repository.updateCartItem(itemId: itemId, quantity: quantity);
}

/// Local-only quantity update — writes to Hive without touching the server.
/// Used by [CartBloc._onUpdateCartItem] for the immediate optimistic step so
/// the debounce timer's server call doesn't double-write to local storage.
class LocalUpdateCartItem {
  final CartRepository _repository;
  LocalUpdateCartItem(this._repository);
  Future<Either<Failure, Cart>> call({
    required int itemId,
    required int quantity,
  }) =>
      _repository.localUpdateCartItem(itemId: itemId, quantity: quantity);
}

class RemoveFromCart {
  final CartRepository _repository;
  RemoveFromCart(this._repository);
  Future<Either<Failure, Cart>> call(int itemId) =>
      _repository.removeFromCart(itemId);
}

class ClearCart {
  final CartRepository _repository;
  ClearCart(this._repository);
  Future<Either<Failure, Cart>> call() => _repository.clearCart();
}

class ApplyCoupon {
  final CartRepository _repository;
  ApplyCoupon(this._repository);
  Future<Either<Failure, Cart>> call(String code) =>
      _repository.applyCoupon(code);
}

class RemoveCoupon {
  final CartRepository _repository;
  RemoveCoupon(this._repository);
  Future<Either<Failure, Cart>> call() => _repository.removeCoupon();
}

class SyncCart {
  final CartRepository _repository;
  SyncCart(this._repository);
  /// Returns the merged cart directly — eliminates the second getCart() call
  /// that the BLoC previously made after sync completed.
  Future<Either<Failure, Cart>> call() => _repository.syncCart();
}

/// Pre-checkout validation — checks stock availability and price drift
/// for all items in the cart without modifying it.
class ValidateCart {
  final CartRepository _repository;
  ValidateCart(this._repository);
  Future<Either<Failure, List<Map<String, dynamic>>>> call() =>
      _repository.validateCart();
}
