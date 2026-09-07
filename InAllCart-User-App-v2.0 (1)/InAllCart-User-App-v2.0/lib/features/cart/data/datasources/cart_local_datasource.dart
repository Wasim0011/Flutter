import 'package:hive/hive.dart';

import '../../domain/entities/cart.dart';
import '../models/cart_model.dart';

/// Local data source for cart - PRIMARY storage for offline-first approach
abstract class CartLocalDataSource {
  Future<CartModel> getCart();
  Future<void> saveCart(CartModel cart);
  Future<CartModel> addItem(CartItemModel item);
  Future<CartModel> updateItem(int itemId, int quantity);
  Future<CartModel> removeItem(int itemId);
  Future<void> clearCart();
  Future<List<CartItemModel>> getUnsyncedItems();
  Future<void> markItemAsSynced(int itemId);
  Future<void> markAllAsSynced();
}

class CartLocalDataSourceImpl implements CartLocalDataSource {
  static const String _boxName = 'cart';
  static const String _cartKey = 'current_cart';

  Future<Box<Map>> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox<Map>(_boxName);
    }
    return Hive.box<Map>(_boxName);
  }

  @override
  Future<CartModel> getCart() async {
    try {
      final box = await _getBox();
      final data = box.get(_cartKey);
      if (data != null) {
        return CartModel.fromJson(Map<String, dynamic>.from(data));
      }
      return CartModel.empty();
    } catch (e) {
      return CartModel.empty();
    }
  }

  @override
  Future<void> saveCart(CartModel cart) async {
    try {
      final box = await _getBox();
      await box.put(_cartKey, cart.toJson());
    } catch (e) {
      // Silent fail
    }
  }

  @override
  Future<CartModel> addItem(CartItemModel item) async {
    final cart = await getCart();
    final items = List<CartItem>.from(cart.items);

    // ── Store isolation (mirrors backend single-store-cart enforcement) ──────
    // A guest can only hold items from one store at a time. If the incoming
    // item belongs to a different store, throw so the caller can surface a
    // clear "clear your cart first" message — identical to the backend error.
    if (items.isNotEmpty && item.storeId != null) {
      final cartStoreId = items
          .map((i) => (i as CartItemModel).storeId)
          .firstWhere((id) => id != null, orElse: () => null);
      if (cartStoreId != null && cartStoreId != item.storeId) {
        throw Exception(
          'Cannot add items from different stores. Please clear your cart first.',
        );
      }
    }

    // Check if item already exists (same product + same variant)
    final existingIndex = items.indexWhere(
      (i) => i.productId == item.productId && i.variantId == item.variantId,
    );

    if (existingIndex >= 0) {
      // Update quantity
      final existing = items[existingIndex] as CartItemModel;
      items[existingIndex] = existing.copyWith(
        quantity: existing.quantity + item.quantity,
        synced: false,
      );
    } else {
      // Add new item with local ID
      final newItem = item.copyWith(
        id: DateTime.now().millisecondsSinceEpoch,
        synced: false,
      );
      items.add(newItem);
    }

    final updatedCart = _recalculateCart(items, cart.couponCode, cart.couponDiscount);
    await saveCart(updatedCart);
    return updatedCart;
  }

  @override
  Future<CartModel> updateItem(int itemId, int quantity) async {
    final cart = await getCart();
    final items = List<CartItem>.from(cart.items);
    
    final index = items.indexWhere((i) => i.id == itemId);
    if (index >= 0) {
      if (quantity <= 0) {
        items.removeAt(index);
      } else {
        final item = items[index] as CartItemModel;
        items[index] = item.copyWith(quantity: quantity, synced: false);
      }
    }
    
    final updatedCart = _recalculateCart(items, cart.couponCode, cart.couponDiscount);
    await saveCart(updatedCart);
    return updatedCart;
  }

  @override
  Future<CartModel> removeItem(int itemId) async {
    final cart = await getCart();
    final items = List<CartItem>.from(cart.items);
    
    items.removeWhere((i) => i.id == itemId);
    
    final updatedCart = _recalculateCart(items, cart.couponCode, cart.couponDiscount);
    await saveCart(updatedCart);
    return updatedCart;
  }

  @override
  Future<void> clearCart() async {
    try {
      final box = await _getBox();
      await box.delete(_cartKey);
    } catch (e) {
      // Silent fail
    }
  }

  @override
  Future<List<CartItemModel>> getUnsyncedItems() async {
    final cart = await getCart();
    return cart.items
        .where((item) => !item.synced)
        .map((item) => item as CartItemModel)
        .toList();
  }

  @override
  Future<void> markItemAsSynced(int itemId) async {
    final cart = await getCart();
    final items = cart.items.map((item) {
      if (item.id == itemId) {
        return (item as CartItemModel).copyWith(synced: true);
      }
      return item;
    }).toList();
    
    final updatedCart = CartModel(
      items: items,
      summary: cart.summary,
      couponCode: cart.couponCode,
      couponDiscount: cart.couponDiscount,
    );
    await saveCart(updatedCart);
  }

  @override
  Future<void> markAllAsSynced() async {
    final cart = await getCart();
    final items = cart.items.map((item) {
      return (item as CartItemModel).copyWith(synced: true);
    }).toList();
    
    final updatedCart = CartModel(
      items: items,
      summary: cart.summary,
      couponCode: cart.couponCode,
      couponDiscount: cart.couponDiscount,
    );
    await saveCart(updatedCart);
  }

  CartModel _recalculateCart(List<CartItem> items, String? couponCode, double? couponDiscount) {
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.total);
    final discount = couponDiscount ?? 0;
    final total = subtotal - discount;
    final itemsCount = items.fold<int>(0, (sum, item) => sum + item.quantity);
    
    return CartModel(
      items: items,
      summary: CartSummaryModel(
        itemsCount: itemsCount,
        uniqueItems: items.length,
        subtotal: subtotal,
        discount: discount,
        total: total > 0 ? total : 0,
        totalWithDelivery: total > 0 ? total : 0,
      ),
      couponCode: couponCode,
      couponDiscount: couponDiscount,
    );
  }
}
