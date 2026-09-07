import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/category.dart';
import '../repositories/category_repository.dart';

class GetCategories {
  final CategoryRepository _repository;
  GetCategories(this._repository);

  Future<Either<Failure, List<Category>>> call({bool forceRefresh = false}) => 
      _repository.getCategories(forceRefresh: forceRefresh);
}

class GetFeaturedCategories {
  final CategoryRepository _repository;
  GetFeaturedCategories(this._repository);

  Future<Either<Failure, List<Category>>> call({int limit = 8, bool forceRefresh = false}) =>
      _repository.getFeaturedCategories(limit: limit, forceRefresh: forceRefresh);
}

class GetCategoryById {
  final CategoryRepository _repository;
  GetCategoryById(this._repository);

  Future<Either<Failure, Category>> call(int id) => _repository.getCategoryById(id);
}
