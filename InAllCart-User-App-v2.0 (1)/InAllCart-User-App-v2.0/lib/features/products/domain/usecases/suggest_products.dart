import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/product_repository.dart';

class SuggestProducts {
  final ProductRepository _repository;

  SuggestProducts(this._repository);

  Future<Either<Failure, Map<String, dynamic>>> call(String query) async {
    return _repository.suggestProducts(query);
  }
}
