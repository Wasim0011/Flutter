import 'package:equatable/equatable.dart';
import '../../../../core/constants/app_constants.dart';

class Category extends Equatable {
  final int id;
  final String name;
  final String? slug;
  final String? description;
  final String? imageUrl;
  final int sortOrder;
  final Category? parent;
  final List<Category> children;
  final int? productsCount;
  final CategoryFlags flags;

  const Category({
    required this.id,
    required this.name,
    this.slug,
    this.description,
    this.imageUrl,
    this.sortOrder = 0,
    this.parent,
    this.children = const [],
    this.productsCount,
    required this.flags,
  });

  bool get hasChildren => children.isNotEmpty || (flags.hasChildren);

  @override
  List<Object?> get props => [id, name, slug, imageUrl, sortOrder, productsCount, flags];
}

class CategoryFlags extends Equatable {
  final bool isActive;
  final bool isFeatured;
  final bool hasChildren;

  const CategoryFlags({
    required this.isActive,
    required this.isFeatured,
    this.hasChildren = false,
  });

  @override
  List<Object?> get props => [isActive, isFeatured, hasChildren];
}
