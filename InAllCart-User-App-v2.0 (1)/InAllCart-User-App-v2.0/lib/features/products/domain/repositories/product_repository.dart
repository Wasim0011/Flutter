import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/product.dart';

abstract class ProductRepository {
  Future<Either<Failure, List<Product>>> getProducts({
    int page = 1,
    int perPage = 15,
    String? search,
    int? categoryId,
    double? minPrice,
    double? maxPrice,
    String? brand,
    int? brandId,
    int? storeId,
    bool forceRefresh = false,
  });

  Future<Either<Failure, List<Product>>> getFeaturedProducts({
    int limit = 10,
    bool forceRefresh = false,
  });

  Future<Either<Failure, Product>> getProductById(
    int id, {
    bool forceRefresh = false,
  });

  Future<Either<Failure, List<Product>>> getProductsByCategory(
    int categoryId, {
    int page = 1,
  });

  Future<Either<Failure, List<Product>>> searchProducts(
    String query, {
    int page = 1,
  });

  Future<Either<Failure, List<Product>>> getRelatedProducts(
    int productId, {
    int limit = 6,
  });

  Future<Either<Failure, List<Product>>> getProductsByIds(List<int> ids);

  Future<Either<Failure, Map<String, dynamic>>> suggestProducts(String query);
}
