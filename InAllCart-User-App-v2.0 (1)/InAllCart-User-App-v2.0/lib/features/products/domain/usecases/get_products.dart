import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetProducts {
  final ProductRepository _repository;

  GetProducts(this._repository);

  Future<Either<Failure, List<Product>>> call({
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
  }) {
    return _repository.getProducts(
      page: page,
      perPage: perPage,
      search: search,
      categoryId: categoryId,
      minPrice: minPrice,
      maxPrice: maxPrice,
      brand: brand,
      brandId: brandId,
      storeId: storeId,
      forceRefresh: forceRefresh,
    );
  }
}

class GetFeaturedProducts {
  final ProductRepository _repository;

  GetFeaturedProducts(this._repository);

  Future<Either<Failure, List<Product>>> call({
    int limit = 10,
    bool forceRefresh = false,
  }) {
    return _repository.getFeaturedProducts(
      limit: limit,
      forceRefresh: forceRefresh,
    );
  }
}

class GetProductById {
  final ProductRepository _repository;

  GetProductById(this._repository);

  Future<Either<Failure, Product>> call(int id, {bool forceRefresh = false}) {
    return _repository.getProductById(id, forceRefresh: forceRefresh);
  }
}

class GetProductsByCategory {
  final ProductRepository _repository;

  GetProductsByCategory(this._repository);

  Future<Either<Failure, List<Product>>> call(int categoryId, {int page = 1}) {
    return _repository.getProductsByCategory(categoryId, page: page);
  }
}

class SearchProducts {
  final ProductRepository _repository;

  SearchProducts(this._repository);

  Future<Either<Failure, List<Product>>> call(String query, {int page = 1}) {
    return _repository.searchProducts(query, page: page);
  }
}

class GetRelatedProducts {
  final ProductRepository _repository;

  GetRelatedProducts(this._repository);

  Future<Either<Failure, List<Product>>> call(int productId, {int limit = 6}) {
    return _repository.getRelatedProducts(productId, limit: limit);
  }
}
