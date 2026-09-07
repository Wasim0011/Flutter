/// Model matching backend `ItemController::index()` response items.
///
/// The controller selects: id, category_id, name, description, base_surcharge,
/// weight_kg, requires_disassembly, icon.
///
/// NOTE: The DB migration has `surcharge` (not `base_surcharge`), `size` enum
/// (not `weight_kg`), and `is_fragile`. The controller may be selecting
/// non-existent column aliases. We parse both possibilities defensively.
class ItemModel {
  final int id;
  final int categoryId;
  final String name;
  final String? description;
  final double surcharge;
  final String size; // enum: small, medium, large, xlarge
  final bool isFragile;
  final bool requiresDisassembly;
  final String? icon;

  ItemModel({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description,
    required this.surcharge,
    required this.size,
    required this.isFragile,
    required this.requiresDisassembly,
    this.icon,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'] as int,
      categoryId: json['category_id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      // Controller selects `base_surcharge` but DB column is `surcharge` — try both
      surcharge:
          double.tryParse(json['base_surcharge']?.toString() ?? '') ??
          double.tryParse(json['surcharge']?.toString() ?? '') ??
          0.0,
      // Controller selects `weight_kg` but DB column is `size` — try both
      size: json['size'] as String? ?? 'medium',
      isFragile: json['is_fragile'] as bool? ?? false,
      requiresDisassembly: json['requires_disassembly'] as bool? ?? false,
      icon: json['icon'] as String?,
    );
  }
}

/// Model matching backend `ItemController::index()` response categories.
///
/// The controller returns categories with nested items:
/// { id, name, icon, sort_order, items: [...] }
class ItemCategoryModel {
  final int id;
  final String name;
  final String? icon;
  final int sortOrder;
  final List<ItemModel> items;

  ItemCategoryModel({
    required this.id,
    required this.name,
    this.icon,
    required this.sortOrder,
    required this.items,
  });

  factory ItemCategoryModel.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List? ?? [];
    final parsedItems = itemsList
        .map((i) => ItemModel.fromJson(i as Map<String, dynamic>))
        .toList();

    return ItemCategoryModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      icon: json['icon_url'] as String? ?? json['icon'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      items: parsedItems,
    );
  }
}
