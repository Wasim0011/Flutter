import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/category.dart';

abstract class CategoryRepository {
  Future<Either<Failure, List<Category>>> getCategories({bool forceRefresh = false});
  Future<Either<Failure, List<Category>>> getFeaturedCategories({int limit = 8, bool forceRefresh = false});
  Future<Either<Failure, Category>> getCategoryById(int id);
}
