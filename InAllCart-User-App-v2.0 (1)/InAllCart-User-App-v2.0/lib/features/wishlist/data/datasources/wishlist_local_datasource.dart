import 'package:hive_flutter/hive_flutter.dart';

abstract class WishlistLocalDataSource {
  Future<List<int>> getWishlistProductIds();
  Future<void> addToWishlist(int productId);
  Future<void> removeFromWishlist(int productId);
  Future<bool> isInWishlist(int productId);
  Future<void> clearWishlist();
}

class WishlistLocalDataSourceImpl implements WishlistLocalDataSource {
  final Box<List> _wishlistBox;
  static const String _wishlistKey = 'wishlist_product_ids';

  WishlistLocalDataSourceImpl(this._wishlistBox);

  @override
  Future<List<int>> getWishlistProductIds() async {
    final list = _wishlistBox.get(_wishlistKey, defaultValue: []);
    return list?.cast<int>() ?? [];
  }

  @override
  Future<void> addToWishlist(int productId) async {
    final list = await getWishlistProductIds();
    if (!list.contains(productId)) {
      list.add(productId);
      await _wishlistBox.put(_wishlistKey, list);
    }
  }

  @override
  Future<void> removeFromWishlist(int productId) async {
    final list = await getWishlistProductIds();
    if (list.contains(productId)) {
      list.remove(productId);
      await _wishlistBox.put(_wishlistKey, list);
    }
  }

  @override
  Future<bool> isInWishlist(int productId) async {
    final list = await getWishlistProductIds();
    return list.contains(productId);
  }

  @override
  Future<void> clearWishlist() async {
    await _wishlistBox.delete(_wishlistKey);
  }
}
