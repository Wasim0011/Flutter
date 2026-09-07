
abstract class WishlistRepository {
  Future<List<int>> getWishlistProductIds();
  Future<void> toggleWishlistProduct(int productId);
  Future<bool> isProductInWishlist(int productId);
  Future<void> clearWishlist();
}
