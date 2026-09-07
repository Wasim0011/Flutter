import '../../domain/repositories/wishlist_repository.dart';
import '../datasources/wishlist_local_datasource.dart';

class WishlistRepositoryImpl implements WishlistRepository {
  final WishlistLocalDataSource localDataSource;

  WishlistRepositoryImpl(this.localDataSource);

  @override
  Future<List<int>> getWishlistProductIds() {
    return localDataSource.getWishlistProductIds();
  }

  @override
  Future<void> toggleWishlistProduct(int productId) async {
    final isInWishlist = await localDataSource.isInWishlist(productId);
    if (isInWishlist) {
      await localDataSource.removeFromWishlist(productId);
    } else {
      await localDataSource.addToWishlist(productId);
    }
  }

  @override
  Future<bool> isProductInWishlist(int productId) {
    return localDataSource.isInWishlist(productId);
  }

  @override
  Future<void> clearWishlist() {
    return localDataSource.clearWishlist();
  }
}
