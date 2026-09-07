import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/cart.dart';

abstract class CartRepository {
  Future<Either<Failure, Cart>> getCart();
  Future<Either<Failure, Cart>> addToCart({
    required int productId,
    required int quantity,
    int? variantId,
    String? productName,
    String? productImage,
    double? price,
  });
  Future<Either<Failure, Cart>> updateCartItem({
    required int itemId,
    required int quantity,
  });

  /// Local-only update — writes to Hive without a server call.
  /// Used by the BLoC's immediate optimistic step before the debounced
  /// server call fires, preventing a double Hive write per tap.
  Future<Either<Failure, Cart>> localUpdateCartItem({
    required int itemId,
    required int quantity,
  });

  Future<Either<Failure, Cart>> removeFromCart(int itemId);
  Future<Either<Failure, Cart>> clearCart();
  Future<Either<Failure, Cart>> applyCoupon(String code);
  Future<Either<Failure, Cart>> removeCoupon();

  /// Sync guest cart items to the server after login.
  /// Returns the merged server cart directly — no second round-trip needed.
  Future<Either<Failure, Cart>> syncCart();

  /// Validate cart items for stock availability and price changes.
  /// Returns a list of issue descriptors; empty list means cart is clean.
  Future<Either<Failure, List<Map<String, dynamic>>>> validateCart();
}
