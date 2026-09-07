import '../../domain/entities/category.dart';
import '../../../../core/constants/app_constants.dart';

class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.name,
    super.slug,
    super.description,
    super.imageUrl,
    super.sortOrder,
    super.parent,
    super.children,
    super.productsCount,
    required super.flags,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String?,
      description: json['description'] as String?,
      imageUrl: AppConstants.getFullMediaUrl((json['image'] ?? json['image_url']) as String?),
      sortOrder: json['sort_order'] as int? ?? 0,
      parent: json['parent'] != null && json['parent'] is Map && (json['parent'] as Map).isNotEmpty
          ? CategoryModel.fromJson(json['parent'])
          : null,
      children: (json['children'] as List?)
              ?.map((e) => CategoryModel.fromJson(e))
              .toList() ??
          [],
      productsCount: json['products_count'] as int?,
      flags: CategoryFlagsModel.fromJson(json['flags'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'description': description,
        'image': imageUrl,
        'sort_order': sortOrder,
        'products_count': productsCount,
        'flags': (flags as CategoryFlagsModel).toJson(),
        'children': children.map((c) {
          if (c is CategoryModel) {
            return c.toJson();
          }
          // Fallback for non-CategoryModel children (shouldn't happen)
          return {
            'id': c.id,
            'name': c.name,
            'slug': c.slug,
            'description': c.description,
            'image': c.imageUrl,
            'sort_order': c.sortOrder,
            'products_count': c.productsCount,
            'flags': {'is_active': c.flags.isActive, 'is_featured': c.flags.isFeatured, 'has_children': c.flags.hasChildren},
            'children': [],
          };
        }).toList(),
      };
}

class CategoryFlagsModel extends CategoryFlags {
  const CategoryFlagsModel({
    required super.isActive,
    required super.isFeatured,
    super.hasChildren,
  });

  factory CategoryFlagsModel.fromJson(Map<String, dynamic> json) {
    return CategoryFlagsModel(
      isActive: json['is_active'] as bool? ?? true,
      isFeatured: json['is_featured'] as bool? ?? false,
      hasChildren: json['has_children'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'is_active': isActive,
        'is_featured': isFeatured,
        'has_children': hasChildren,
      };
}
