import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/cart_model.dart';

/// Result of a batch sync operation.
/// [cart] is the merged server cart; [errors] contains per-item failures
/// (empty when all items synced successfully).
class CartSyncResult {
  final CartModel cart;
  final List<Map<String, dynamic>> errors;

  const CartSyncResult({required this.cart, required this.errors});
}

abstract class CartRemoteDataSource {
  Future<CartModel> getCart();
  Future<CartModel> addToCart({
    required int productId,
    required int quantity,
    int? variantId,
  });
  Future<CartModel> updateCartItem({
    required int itemId,
    required int quantity,
  });
  Future<CartModel> removeFromCart(int itemId);
  Future<CartModel> clearCart();
  Future<CartModel> applyCoupon(String code);
  Future<CartModel> removeCoupon();

  /// Batch-sync guest cart items to the server in a single round-trip.
  /// Returns [CartSyncResult] containing the merged cart and any per-item errors.
  Future<CartSyncResult> batchSyncItems(List<CartItemModel> items);

  /// Validate cart items for stock/price issues before checkout.
  /// Returns a list of issue maps; empty list means cart is clean.
  Future<List<Map<String, dynamic>>> validateCart();
}

class CartRemoteDataSourceImpl implements CartRemoteDataSource {
  final ApiClient _apiClient;

  CartRemoteDataSourceImpl(this._apiClient);

  @override
  Future<CartModel> getCart() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.cart,
    );
    return CartModel.fromJson(response['data'] ?? {});
  }

  @override
  Future<CartModel> addToCart({
    required int productId,
    required int quantity,
    int? variantId,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.cartItems,
      data: {
        'product_id': productId,
        'quantity': quantity,
        if (variantId != null) 'variant_id': variantId,
      },
    );
    return CartModel.fromJson(response['data'] ?? {});
  }

  @override
  Future<CartModel> updateCartItem({
    required int itemId,
    required int quantity,
  }) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      ApiEndpoints.cartItem(itemId.toString()),
      data: {'quantity': quantity},
    );
    return CartModel.fromJson(response['data'] ?? {});
  }

  @override
  Future<CartModel> removeFromCart(int itemId) async {
    final response = await _apiClient.delete<Map<String, dynamic>>(
      ApiEndpoints.cartItem(itemId.toString()),
    );
    return CartModel.fromJson(response['data'] ?? {});
  }

  @override
  Future<CartModel> clearCart() async {
    final response = await _apiClient.delete<Map<String, dynamic>>(
      ApiEndpoints.cart,
    );
    return CartModel.fromJson(response['data'] ?? {});
  }

  @override
  Future<CartModel> applyCoupon(String code) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.applyCoupon,
      data: {'coupon_code': code},
    );
    return CartModel.fromJson(response['data'] ?? {});
  }

  @override
  Future<CartModel> removeCoupon() async {
    final response = await _apiClient.delete<Map<String, dynamic>>(
      ApiEndpoints.removeCoupon,
    );
    return CartModel.fromJson(response['data'] ?? {});
  }

  /// Single round-trip batch sync — replaces the old sequential N-request loop.
  /// The backend upserts each item and returns the merged cart plus any
  /// per-item errors (partial failure).
  @override
  Future<CartSyncResult> batchSyncItems(List<CartItemModel> items) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.cartSync,
      data: {
        'items': items
            .map((item) => {
                  'product_id': item.productId,
                  'quantity': item.quantity,
                  if (item.variantId != null) 'variant_id': item.variantId,
                })
            .toList(),
      },
    );

    final cart = CartModel.fromJson(response['data'] ?? {});

    // Collect per-item errors returned by the server (partial sync failure).
    final rawErrors = response['sync_errors'] as List? ?? [];
    final errors = rawErrors
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return CartSyncResult(cart: cart, errors: errors);
  }

  @override
  Future<List<Map<String, dynamic>>> validateCart() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.cartValidate,
    );
    final data = response['data'] as Map<String, dynamic>? ?? {};
    final issues = data['issues'] as List? ?? [];
    return issues.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
