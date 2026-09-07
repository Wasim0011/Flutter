import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetProductsByIds {
  final ProductRepository repository;

  GetProductsByIds(this.repository);

  Future<Either<Failure, List<Product>>> call(List<int> ids) async {
    return await repository.getProductsByIds(ids);
  }
}
