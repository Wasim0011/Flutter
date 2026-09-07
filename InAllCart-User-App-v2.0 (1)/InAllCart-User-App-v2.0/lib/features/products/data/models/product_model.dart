import '../../domain/entities/product.dart';
import '../../../../core/constants/app_constants.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.name,
    required super.slug,
    super.sku,
    required super.price,
    required super.description,
    required super.inventory,
    super.unit,
    super.weight,
    super.brand,
    super.barcode,
    super.category,
    super.images,
    super.primaryImage,
    required super.flags,
    super.variants,
    super.store,
    super.deliveryTime,
    super.rating,
    super.reviewCount,
    super.vendorSku,
    super.hsnCode,
    super.taxRate,
    super.taxClass,
    super.weightUnit,
    super.dates,
    super.healthInfo,
    super.policy,
    super.prepTime,
    super.availableTime,
    super.video,
    super.searchTags,
    super.createdAt,
    super.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // 1. Identify the product's image URL
    final String? primaryUrl = _findProductImageUrl(json);

    // 2. Parse the images array for the gallery
    final dynamic rawImages = json['images'] ?? json['product_images'] ?? json['gallery'] ?? json['media'];
    List<ProductImageModel> imagesList = [];
    if (rawImages is List) {
      imagesList = _parseImageList(rawImages);
    } else if (rawImages is String && rawImages.isNotEmpty) {
      imagesList = [ProductImageModel(id: 0, url: AppConstants.getFullMediaUrl(rawImages))];
    }

    // Ensure our identified primary image is at the start of the list
    if (primaryUrl != null && !imagesList.any((img) => img.url == primaryUrl)) {
      imagesList.insert(0, ProductImageModel(id: 0, url: primaryUrl, isPrimary: true));
    }

    return ProductModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name']?.toString() ?? 'Unnamed Product',
      slug: json['slug']?.toString() ?? '',
      sku: json['sku']?.toString(),
      vendorSku: json['vendor_sku']?.toString(),
      hsnCode: json['hsn_code']?.toString(),
      taxRate: _parseDoubleNullable(json['tax_rate']),
      taxClass: json['tax_class']?.toString(),
      price: ProductPriceModel.fromJson(json['price'] ?? json),
      description: ProductDescriptionModel.fromJson(json['description'] ?? json),
      inventory: ProductInventoryModel.fromJson(json['inventory'] ?? json),
      unit: (json['unit'] ?? json['weight_unit'])?.toString(),
      weight: _parseDoubleNullable(json['weight']),
      weightUnit: json['weight_unit']?.toString(),
      brand: json['brand']?.toString(),
      barcode: json['barcode']?.toString(),
      category: json['category'] != null && json['category'] is Map && (json['category'] as Map).isNotEmpty
          ? ProductCategoryModel.fromJson(json['category'])
          : null,
      images: imagesList,
      primaryImage: primaryUrl != null ? ProductImageModel(id: 0, url: primaryUrl, isPrimary: true) : null,
      flags: ProductFlagsModel.fromJson(json['flags'] ?? json),
      variants: _parseVariantsList(json),
      store: json['store'] != null && json['store'] is Map && (json['store'] as Map).isNotEmpty
          ? ProductStoreModel.fromJson(json['store'])
          : null,
      deliveryTime: json['delivery_time']?.toString(),
      rating: _parseDoubleNullable(json['rating']),
      reviewCount: _parseIntNullable(json['review_count']),
      dates: json['dates'] != null && json['dates'] is Map
          ? ProductDates(
        manufactureDate: json['dates']['manufacture_date'] != null ? DateTime.tryParse(json['dates']['manufacture_date']) : null,
        expiryDate: json['dates']['expiry_date'] != null ? DateTime.tryParse(json['dates']['expiry_date']) : null,
        shelfLifeDays: _parseIntNullable(json['dates']['shelf_life_days']),
      )
          : null,
      healthInfo: (json['health_info'] != null && json['health_info'] is Map) || json['is_prescription_required'] != null
          ? ProductHealthInfo(
        isVeg: json['health_info']?['is_veg'] == null
            ? null
            : (json['health_info']['is_veg'] == true || json['health_info']['is_veg'] == 1 || json['health_info']['is_veg'] == '1'),
        isHalal: json['health_info']?['is_halal'] == true || json['health_info']?['is_halal'] == 1,
        isPrescriptionRequired: json['health_info']?['is_prescription_required'] == true ||
            json['health_info']?['is_prescription_required'] == 1 ||
            json['is_prescription_required'] == true ||
            json['is_prescription_required'] == 1 ||
            json['is_prescription_required'] == '1',
        genericName: json['health_info']?['generic_name']?.toString(),
        nutritionInfo: json['health_info']?['nutrition_info']?.toString(),
      )
          : null,
      policy: json['policy'] != null && json['policy'] is Map
          ? ProductPolicy(
        returnPeriodDays: _parseIntNullable(json['policy']['return_period_days']) ?? 7,
        replacementPeriodDays: _parseIntNullable(json['policy']['replacement_period_days']) ?? 7,
        warrantySummary: json['policy']['warranty_summary']?.toString(),
        guaranteeSummary: json['policy']['guarantee_summary']?.toString(),
        deliveredByLeadHours: _parseIntNullable(json['policy']['delivered_by_lead_hours']) ?? 24,
      )
          : null,
      prepTime: json['prep_time'] != null && json['prep_time'] is Map
          ? ProductPrepTime(
        min: _parseIntNullable(json['prep_time']['min']),
        max: _parseIntNullable(json['prep_time']['max']),
        unit: json['prep_time']['unit']?.toString() ?? 'minutes',
      )
          : null,
      availableTime: json['available_time'] != null && json['available_time'] is Map
          ? ProductAvailableTime(
        starts: json['available_time']['starts']?.toString(),
        ends: json['available_time']['ends']?.toString(),
      )
          : null,
      video: json['video'] != null && json['video'] is Map
          ? ProductVideo(
        type: json['video']['type']?.toString(),
        url: json['video']['url']?.toString(),
      )
          : null,
      searchTags: json['search_tags']?.toString(),
      createdAt: json['timestamps']?['created_at'] != null
          ? DateTime.tryParse(json['timestamps']['created_at'])
          : null,
      updatedAt: json['timestamps']?['updated_at'] != null
          ? DateTime.tryParse(json['timestamps']['updated_at'])
          : null,
    );
  }

  /// Targeted logic to find a product image while ignoring shared category/store/brand icons.
  static String? _findProductImageUrl(Map<String, dynamic> json) {
    // Stage 1: Explicit Product keys that aren't usually shared
    final specificKeys = ['product_image', 'primary_image', 'featured_image', 'base_image', 'cover'];
    for (final key in specificKeys) {
      final val = json[key];
      if (val is String && val.isNotEmpty) return AppConstants.getFullMediaUrl(val);
      if (val is Map && val.isNotEmpty) {
        final img = _searchImageInMap(val as Map<String, dynamic>);
        if (img != null) return img;
      }
    }

    // Stage 2: Product image arrays (Always unique to the product)
    final imagesField = json['images'] ?? json['product_images'] ?? json['gallery'] ?? json['media'];
    if (imagesField is List && imagesField.isNotEmpty) {
      for (final item in imagesField) {
        if (item is String && item.isNotEmpty) return AppConstants.getFullMediaUrl(item);
        if (item is Map) {
          final img = _searchImageInMap(item as Map<String, dynamic>);
          if (img != null) return img;
        }
      }
    }

    // Stage 3: Generic keys but ONLY if they are directly on the product and NOT inside a category/store map
    // We scan the map but skip known shared objects
    for (final entry in json.entries) {
      final key = entry.key.toLowerCase();
      final val = entry.value;

      // SKIP these objects completely - they contain shared metadata images
      if (key == 'category' || key == 'store' || key == 'brand' || key == 'vendor') continue;

      if (val is String && val.isNotEmpty && (key == 'image' || key == 'image_url' || key == 'thumbnail' || key == 'thumb' || key == 'url')) {
        if (val.contains('.') || val.contains('/')) return AppConstants.getFullMediaUrl(val);
      }
    }

    // Stage 4: Check attributes map (common in some product CMS)
    if (json['attributes'] is Map) {
      return _findProductImageUrl(json['attributes'] as Map<String, dynamic>);
    }

    // Stage 5 (Sub-task 6 root cause fix): confirmed via live API inspection
    // that this backend's product LISTING endpoint (used for category
    // browsing) does NOT send any top-level image field at all - no
    // "image"/"images"/"product_images"/"gallery"/"media"/"thumbnail" key
    // exists on the product JSON. The only picture data present is on each
    // entry in "variants" (or "variations"), the same per-variant "image"
    // field ProductVariantModel.fromJson already reads. This is why the
    // product detail page (a different, fuller endpoint) shows images fine
    // while the category grid never found one to display. Fall back to the
    // default/first variant's image here so listing screens have something
    // to show.
    final variantsField = json['variants'] ?? json['variations'];
    if (variantsField is List && variantsField.isNotEmpty) {
      // Prefer the variant explicitly marked as default, if any.
      Map<String, dynamic>? preferred;
      for (final v in variantsField) {
        if (v is Map && (v['is_default'] == true || v['is_default'] == 1)) {
          preferred = Map<String, dynamic>.from(v);
          break;
        }
      }

      final candidates = <Map<String, dynamic>>[
        if (preferred != null) preferred,
        for (final v in variantsField)
          if (v is Map) Map<String, dynamic>.from(v),
      ];

      for (final variant in candidates) {
        final variantImage = variant['image'] ?? variant['image_url'] ?? variant['path'] ?? variant['photo'];
        if (variantImage is String && variantImage.isNotEmpty) {
          return AppConstants.getFullMediaUrl(variantImage);
        }
        if (variantImage is Map && variantImage.isNotEmpty) {
          final img = _searchImageInMap(Map<String, dynamic>.from(variantImage));
          if (img != null) return img;
        }
      }
    }

    return null;
  }

  /// Helper to search for image strings within a Map
  static String? _searchImageInMap(Map<String, dynamic> map) {
    final keys = ['url', 'path', 'src', 'file', 'original', 'large', 'medium', 'original_url'];
    for (final key in keys) {
      final val = map[key];
      if (val is String && val.isNotEmpty && val.contains('.')) return AppConstants.getFullMediaUrl(val);
      if (val is Map) {
        final nested = _searchImageInMap(val as Map<String, dynamic>);
        if (nested != null) return nested;
      }
    }
    return null;
  }

  static List<ProductImageModel> _parseImageList(dynamic jsonList) {
    if (jsonList == null || jsonList is! List) return [];
    final List<ProductImageModel> list = [];
    for (final item in jsonList) {
      if (item is String && item.isNotEmpty) {
        list.add(ProductImageModel(id: 0, url: AppConstants.getFullMediaUrl(item)));
      } else if (item is Map) {
        final String? url = _searchImageInMap(item as Map<String, dynamic>);
        if (url != null) {
          list.add(ProductImageModel(id: item['id'] ?? 0, url: url));
        }
      }
    }
    return list;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static double? _parseDoubleNullable(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _parseIntNullable(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'sku': sku,
    'price': (price as ProductPriceModel).toJson(),
    'description': (description as ProductDescriptionModel).toJson(),
    'inventory': (inventory as ProductInventoryModel).toJson(),
    'unit': unit,
    'weight': weight,
    'brand': brand,
    'barcode': barcode,
    'category': category != null
        ? (category as ProductCategoryModel).toJson()
        : null,
    'images': images.map((e) => (e as ProductImageModel).toJson()).toList(),
    'primary_image': primaryImage != null
        ? (primaryImage as ProductImageModel).toJson()
        : null,
    'flags': (flags as ProductFlagsModel).toJson(),
    'variants': variants.map((e) => (e as ProductVariantModel).toJson()).toList(),
    'store': store != null
        ? (store as ProductStoreModel).toJson()
        : null,
    'delivery_time': deliveryTime,
  };

  static List<ProductVariantModel> _parseVariantsList(Map<String, dynamic> json) {
    final rawVariants = json['variants'] ?? json['variations'] ?? json['product_variants'];
    if (rawVariants is List && rawVariants.isNotEmpty) {
      return rawVariants
          .where((e) => e != null && e is Map<String, dynamic>)
          .map((e) => ProductVariantModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final foodGroups = json['food_variation_groups'];
    if (foodGroups is List && foodGroups.isNotEmpty) {
      final List<ProductVariantModel> list = [];
      int idCounter = 1;
      final basePrice = _parseDouble(json['price']?['amount'] ?? json['price']);
      for (final group in foodGroups) {
        if (group is Map && group['options'] is List) {
          final groupName = group['name']?.toString() ?? 'Option';
          for (final opt in group['options']) {
            if (opt is Map) {
              final optName = opt['option_name']?.toString() ?? opt['name']?.toString() ?? groupName;
              final optPrice = double.tryParse(opt['price']?.toString() ?? '0') ?? 0.0;
              final totalPrice = basePrice + optPrice;
              list.add(ProductVariantModel(
                id: opt['id'] is int ? opt['id'] : idCounter++,
                name: '$groupName: $optName',
                sku: opt['sku']?.toString() ?? 'VAR-$idCounter',
                mrp: totalPrice,
                sellingPrice: totalPrice,
                quantity: 100,
                unitName: optName,
                isDefault: list.isEmpty,
                isActive: true,
              ));
            }
          }
        }
      }
      if (list.isNotEmpty) return list;
    }

    return [];
  }
}

class ProductPriceModel extends ProductPrice {
  const ProductPriceModel({
    required super.amount,
    required super.formatted,
    super.comparePrice,
    super.discountPercent,
  });

  factory ProductPriceModel.fromJson(Map<String, dynamic> json) {
    // Handle both flat and nested price objects
    final dynamic amountVal = json['amount'] ?? json['price'] ?? json['selling_price'];
    final dynamic compareVal = json['compare_price'] ?? json['mrp'] ?? json['regular_price'];

    return ProductPriceModel(
      amount: _parseDouble(amountVal),
      formatted: json['formatted']?.toString() ?? '',
      comparePrice: _parseDoubleNullable(compareVal),
      discountPercent: _parseDoubleNullable(json['discount_percent']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static double? _parseDoubleNullable(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'formatted': formatted,
    'compare_price': comparePrice,
    'discount_percent': discountPercent,
  };
}

class ProductDescriptionModel extends ProductDescription {
  const ProductDescriptionModel({super.short, super.full});

  factory ProductDescriptionModel.fromJson(Map<String, dynamic> json) {
    return ProductDescriptionModel(
      short: (json['short'] ?? json['short_description'] ?? json['summary'])?.toString(),
      full: (json['full'] ?? json['description'] ?? json['long_description'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {'short': short, 'full': full};
}

class ProductInventoryModel extends ProductInventory {
  const ProductInventoryModel({
    required super.quantity,
    super.lowStockThreshold,
    required super.inStock,
    required super.isLowStock,
  });

  factory ProductInventoryModel.fromJson(Map<String, dynamic> json) {
    final int q = _parseInt(json['quantity'] ?? json['stock'] ?? json['stock_quantity'] ?? 100);
    return ProductInventoryModel(
      quantity: q,
      lowStockThreshold: _parseIntNullable(json['low_stock_threshold']),
      inStock: json['in_stock'] is bool ? json['in_stock'] : (q > 0),
      isLowStock: json['is_low_stock'] is bool ? json['is_low_stock'] : (q < 5),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int? _parseIntNullable(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() => {
    'quantity': quantity,
    'low_stock_threshold': lowStockThreshold,
    'in_stock': inStock,
    'is_low_stock': isLowStock,
  };
}

class ProductCategoryModel extends ProductCategory {
  const ProductCategoryModel({
    required super.id,
    required super.name,
    super.slug,
    super.imageUrl,
  });

  factory ProductCategoryModel.fromJson(Map<String, dynamic> json) {
    return ProductCategoryModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString(),
      imageUrl: AppConstants.getFullMediaUrl((json['image_url'] ?? json['image'] ?? json['icon'] ?? json['path'])?.toString()),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'image_url': imageUrl,
  };
}

class ProductImageModel extends ProductImage {
  const ProductImageModel({
    required super.id,
    required super.url,
    super.thumbnail,
    super.isPrimary,
    super.sortOrder,
  });

  factory ProductImageModel.fromJson(Map<String, dynamic> json) {
    String? rawUrl;
    final fields = [
      'url', 'path', 'image', 'file', 'image_url', 'full_url', 'src',
      'original', 'large', 'medium', 'small', 'thumbnail', 'thumb',
      'base_image', 'featured_image', 'original_url', 'preview_url', 'base'
    ];
    for (final f in fields) {
      final val = json[f];
      if (val != null && (val is String) && val.isNotEmpty && (val.contains('.') || val.contains('/'))) {
        rawUrl = val;
        break;
      }
      if (val is Map && val.isNotEmpty) {
        // Handle nested maps like "original": {"url": "..."}
        final nested = val as Map<String, dynamic>;
        for (final nf in fields) {
          final nval = nested[nf];
          if (nval != null && nval is String && nval.isNotEmpty && (nval.contains('.') || nval.contains('/'))) {
            rawUrl = nval;
            break;
          }
        }
        if (rawUrl != null) break;
      }
    }

    // Final fallback: Check ANY string value in the map
    if (rawUrl == null) {
      for (final val in json.values) {
        if (val is String && val.isNotEmpty && (val.contains('.') && (val.contains('/') || val.startsWith('http')))) {
          rawUrl = val;
          break;
        }
      }
    }

    return ProductImageModel(
      id: json['id'] as int? ?? 0,
      url: AppConstants.getFullMediaUrl(rawUrl ?? ''),
      thumbnail: AppConstants.getFullMediaUrl((json['thumbnail'] ?? json['thumb'] ?? json['small'] ?? json['medium'])?.toString()),
      isPrimary: json['is_primary'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'url': url,
    'thumbnail': thumbnail,
    'is_primary': isPrimary,
    'sort_order': sortOrder,
  };
}

class ProductFlagsModel extends ProductFlags {
  const ProductFlagsModel({
    required super.isActive,
    required super.isFeatured,
  });

  factory ProductFlagsModel.fromJson(Map<String, dynamic> json) {
    return ProductFlagsModel(
      isActive: json['is_active'] is bool ? json['is_active'] : true,
      isFeatured: json['is_featured'] is bool ? json['is_featured'] : false,
    );
  }

  Map<String, dynamic> toJson() => {
    'is_active': isActive,
    'is_featured': isFeatured,
  };
}

class ProductVariantModel extends ProductVariant {
  const ProductVariantModel({
    required super.id,
    super.name,
    super.sku,
    required super.mrp,
    required super.sellingPrice,
    required super.quantity,
    super.unitName,
    super.unitValue,
    super.isActive,
    super.isDefault,
    super.image,
  });

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    final pricing = json['pricing'] as Map<String, dynamic>?;
    final unit = json['unit'] as Map<String, dynamic>?;
    final inventory = json['inventory'] as Map<String, dynamic>?;

    final mrpVal = _parseDouble(pricing?['mrp'] ?? json['mrp'] ?? json['price']);
    final sellingPriceVal = _parseDouble(pricing?['selling_price'] ?? json['selling_price'] ?? json['price']);

    return ProductVariantModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: (json['name'] ?? json['display_name'])?.toString(),
      sku: json['sku']?.toString(),
      mrp: mrpVal > 0 ? mrpVal : sellingPriceVal,
      sellingPrice: sellingPriceVal,
      quantity: _parseInt(inventory?['quantity'] ?? json['quantity'] ?? 100),
      unitName: (unit?['name'] ?? json['unit_name'])?.toString(),
      unitValue: _parseDoubleNullable(unit?['value'] ?? json['unit_value']),
      isActive: json['is_active'] is bool ? json['is_active'] : true,
      isDefault: json['is_default'] is bool ? json['is_default'] : false,
      image: AppConstants.getFullMediaUrl((json['image'] ?? json['image_url'] ?? json['path'])?.toString()),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static double? _parseDoubleNullable(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sku': sku,
    'mrp': mrp,
    'selling_price': sellingPrice,
    'quantity': quantity,
    'unit_name': unitName,
    'unit_value': unitValue,
    'is_active': isActive,
    'is_default': isDefault,
    'image': image,
  };
}

class ProductStoreModel extends ProductStore {
  const ProductStoreModel({
    required super.id,
    required super.name,
    super.logo,
    super.slug,
  });

  factory ProductStoreModel.fromJson(Map<String, dynamic> json) {
    return ProductStoreModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name']?.toString() ?? '',
      logo: AppConstants.getFullMediaUrl(json['logo']?.toString()),
      slug: json['slug']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'logo': logo,
    'slug': slug,
  };
}