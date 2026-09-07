import 'package:equatable/equatable.dart';
import '../../../../core/constants/app_constants.dart';

class Product extends Equatable {
  final int id;
  final String name;
  final String slug;
  final String? sku;
  final ProductPrice price;
  final ProductDescription description;
  final ProductInventory inventory;
  final String? unit;
  final double? weight;
  final String? brand;
  final String? barcode;
  final ProductCategory? category;
  final List<ProductImage> images;
  final ProductImage? primaryImage;
  final ProductFlags flags;
  final List<ProductVariant> variants;
  final ProductStore? store;
  final String? deliveryTime;
  final double? rating;
  final int? reviewCount;

  // Extended Attributes
  final String? vendorSku;
  final String? hsnCode;
  final double? taxRate;
  final String? taxClass;
  final String? weightUnit;
  final ProductDates? dates;
  final ProductHealthInfo? healthInfo;
  final ProductPolicy? policy;
  final ProductPrepTime? prepTime;
  final ProductAvailableTime? availableTime;
  final ProductVideo? video;
  final String? searchTags;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Product({
    required this.id,
    required this.name,
    required this.slug,
    this.sku,
    this.vendorSku,
    this.hsnCode,
    this.taxRate,
    this.taxClass,
    required this.price,
    required this.description,
    required this.inventory,
    this.unit,
    this.weight,
    this.weightUnit,
    this.brand,
    this.barcode,
    this.category,
    this.images = const [],
    this.primaryImage,
    required this.flags,
    this.variants = const [],
    this.store,
    this.deliveryTime,
    this.rating,
    this.reviewCount,
    this.dates,
    this.healthInfo,
    this.policy,
    this.prepTime,
    this.availableTime,
    this.video,
    this.searchTags,
    this.createdAt,
    this.updatedAt,
  });

  String get imageUrl {
    if (primaryImage != null && primaryImage!.url.isNotEmpty) return primaryImage!.url;
    if (images.isNotEmpty && images.first.url.isNotEmpty) return images.first.url;
    return '';
  }
  bool get hasDiscount => price.comparePrice != null && price.comparePrice! > price.amount;
  bool get hasVariants => variants.isNotEmpty;
  
  @override
  List<Object?> get props => [id, name, slug, price, inventory, updatedAt];
}

class ProductPrice extends Equatable {
  final double amount;
  final String formatted;
  final double? comparePrice;
  final double? discountPercent;

  const ProductPrice({
    required this.amount,
    required this.formatted,
    this.comparePrice,
    this.discountPercent,
  });

  @override
  List<Object?> get props => [amount, formatted, comparePrice, discountPercent];
}

class ProductDescription extends Equatable {
  final String? short;
  final String? full;

  const ProductDescription({this.short, this.full});

  @override
  List<Object?> get props => [short, full];
}

class ProductInventory extends Equatable {
  final int quantity;
  final int? lowStockThreshold;
  final bool inStock;
  final bool isLowStock;

  const ProductInventory({
    required this.quantity,
    this.lowStockThreshold,
    required this.inStock,
    required this.isLowStock,
  });

  @override
  List<Object?> get props => [quantity, inStock, isLowStock];
}

class ProductCategory extends Equatable {
  final int id;
  final String name;
  final String? slug;
  final String? imageUrl;

  const ProductCategory({
    required this.id,
    required this.name,
    this.slug,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [id, name, slug];
}

class ProductImage extends Equatable {
  final int id;
  final String url;
  final String? thumbnail;
  final bool isPrimary;
  final int sortOrder;

  const ProductImage({
    required this.id,
    required this.url,
    this.thumbnail,
    this.isPrimary = false,
    this.sortOrder = 0,
  });

  @override
  List<Object?> get props => [id, url, isPrimary];
}

class ProductFlags extends Equatable {
  final bool isActive;
  final bool isFeatured;

  const ProductFlags({
    required this.isActive,
    required this.isFeatured,
  });

  @override
  List<Object?> get props => [isActive, isFeatured];
}

class ProductVariant extends Equatable {
  final int id;
  final String? name;
  final String? sku;
  final double mrp;
  final double sellingPrice;
  final int quantity;
  final String? unitName;
  final double? unitValue;
  final bool isActive;
  final bool isDefault;
  final String? image;

  const ProductVariant({
    required this.id,
    this.name,
    this.sku,
    required this.mrp,
    required this.sellingPrice,
    required this.quantity,
    this.unitName,
    this.unitValue,
    this.isActive = true,
    this.isDefault = false,
    this.image,
  });

  bool get inStock => quantity > 0 && isActive;
  bool get isSoldOut => !inStock;
  double get discountPercent => mrp > sellingPrice ? ((mrp - sellingPrice) / mrp) * 100 : 0;
  
  String get displayName {
    if (name != null && name!.trim().isNotEmpty) return name!;
    if (unitValue != null && unitName != null) {
      return '$unitValue $unitName'.trim();
    }
    if (sku != null && sku!.isNotEmpty) {
      final parts = sku!.split('-');
      if (parts.length > 2) {
        return parts.sublist(2).join(' / ');
      }
      return sku!;
    }
    return 'Default';
  }

  @override
  List<Object?> get props => [id, name, sellingPrice, quantity, isActive];
}

class ProductStore extends Equatable {
  final int id;
  final String name;
  final String? logo;
  final String? slug;

  const ProductStore({
    required this.id,
    required this.name,
    this.logo,
    this.slug,
  });

  @override
  List<Object?> get props => [id, name];
}

class ProductDates extends Equatable {
  final DateTime? manufactureDate;
  final DateTime? expiryDate;
  final int? shelfLifeDays;

  const ProductDates({
    this.manufactureDate,
    this.expiryDate,
    this.shelfLifeDays,
  });

  @override
  List<Object?> get props => [manufactureDate, expiryDate, shelfLifeDays];
}

class ProductHealthInfo extends Equatable {
  final bool? isVeg;
  final bool isHalal;
  final bool isPrescriptionRequired;
  final String? genericName;
  final String? nutritionInfo;

  const ProductHealthInfo({
    this.isVeg,
    this.isHalal = false,
    this.isPrescriptionRequired = false,
    this.genericName,
    this.nutritionInfo,
  });

  @override
  List<Object?> get props => [isVeg, isHalal, isPrescriptionRequired, genericName, nutritionInfo];
}

class ProductPolicy extends Equatable {
  final int returnPeriodDays;
  final int replacementPeriodDays;
  final String? warrantySummary;
  final String? guaranteeSummary;
  final int deliveredByLeadHours;

  const ProductPolicy({
    this.returnPeriodDays = 7,
    this.replacementPeriodDays = 7,
    this.warrantySummary,
    this.guaranteeSummary,
    this.deliveredByLeadHours = 24,
  });

  @override
  List<Object?> get props => [returnPeriodDays, replacementPeriodDays, warrantySummary, guaranteeSummary, deliveredByLeadHours];
}

class ProductPrepTime extends Equatable {
  final int? min;
  final int? max;
  final String unit;

  const ProductPrepTime({this.min, this.max, this.unit = 'minutes'});

  @override
  List<Object?> get props => [min, max, unit];
}

class ProductAvailableTime extends Equatable {
  final String? starts;
  final String? ends;

  const ProductAvailableTime({this.starts, this.ends});

  @override
  List<Object?> get props => [starts, ends];
}

class ProductVideo extends Equatable {
  final String? type;
  final String? url;

  const ProductVideo({this.type, this.url});

  @override
  List<Object?> get props => [type, url];
}
