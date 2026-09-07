import '../../features/categories/domain/entities/category.dart';

class CategoryUtils {
  /// Recursively find a category by its ID in a list of categories
  static Category? findCategoryById(List<Category> categories, int id) {
    return findCategoryWithParent(categories, id)?.category;
  }

  /// Recursively find a category and its parent by ID
  static CategoryResult? findCategoryWithParent(List<Category> categories, int id, {Category? parent}) {
    for (var category in categories) {
      if (category.id == id) {
        return CategoryResult(category, parent);
      }
      
      if (category.children.isNotEmpty) {
        final found = findCategoryWithParent(category.children, id, parent: category);
        if (found != null) {
          return found;
        }
      }
    }
    return null;
  }
}

class CategoryResult {
  final Category category;
  final Category? parent;
  CategoryResult(this.category, this.parent);
}

