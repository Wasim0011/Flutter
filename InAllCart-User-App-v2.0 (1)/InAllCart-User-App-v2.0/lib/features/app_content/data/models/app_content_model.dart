import '../../domain/entities/app_content.dart';

class AppContentModel extends AppContent {
  const AppContentModel({
    required super.id,
    super.headerTabId,
    required super.type,
    required super.style,
    super.title,
    required super.showTitle,
    super.subtitle,
    required super.showSubtitle,
    super.source,
    required super.sortOrder,
    super.products,
    super.categories,
    super.brands,
    super.background,
    super.gridColumns,
    super.gridRows,
    super.enableHorizontalAnimation,
    super.showOnCategoryScreen,
    super.showViewAll,
    super.media,
    super.link,
    super.mediaItems,
    super.stores,
  });

  factory AppContentModel.fromJson(Map<String, dynamic> json) {
    return AppContentModel(
      id: json['id'] as int,
      headerTabId: json['header_tab_id'] as int?,
      type: _parseType(json['type'] as String),
      style: _parseStyle(json['style'] as String),
      title: json['title'] as String?,
      showTitle: json['show_title'] as bool? ?? true,
      subtitle: json['subtitle'] as String?,
      showSubtitle: json['show_subtitle'] as bool? ?? false,
      source: json['source'] != null ? _parseSource(json['source'] as String) : null,
      sortOrder: json['sort_order'] as int? ?? 0,
      products: json['products'] != null
          ? (json['products'] as List).map((p) => ContentProductModel.fromJson(p)).toList()
          : null,
      categories: json['categories'] != null
          ? (json['categories'] as List).map((c) => ContentCategoryModel.fromJson(c)).toList()
          : null,
      brands: json['brands'] != null
          ? (json['brands'] as List).map((b) => ContentBrandModel.fromJson(b)).toList()
          : null,
      background: json['background'] != null 
          ? ContentBackgroundModel.fromJson(json['background']) 
          : null,
      gridColumns: json['grid_columns'] as int?,
      gridRows: json['grid_rows'] as int?,
      enableHorizontalAnimation: json['enable_horizontal_animation'] as bool? ?? false,
      showOnCategoryScreen: json['show_on_category_screen'] as bool? ?? false,
      showViewAll: json['show_view_all'] as bool? ?? false,
      media: json['media'] != null ? ContentMediaModel.fromJson(json['media']) : null,
      link: json['link'] != null ? ContentLinkModel.fromJson(json['link']) : null,
      mediaItems: json['media_items'] != null
          ? (json['media_items'] as List).map((m) => MediaItemModel.fromJson(m)).toList()
          : null,
      stores: json['stores'] != null
          ? (json['stores'] as List).map((s) => ContentStoreModel.fromJson(s)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'header_tab_id': headerTabId,
      'type': type.name,
      'style': style == ContentStyle.style4 ? 'style_4' : 'style_${style.index + 1}',
      'title': title,
      'show_title': showTitle,
      'subtitle': subtitle,
      'show_subtitle': showSubtitle,
      'source': source?.name,
      'sort_order': sortOrder,
      'products': products?.map((p) => (p as ContentProductModel).toJson()).toList(),
      'categories': categories?.map((c) => (c as ContentCategoryModel).toJson()).toList(),
      'brands': brands?.map((b) => (b as ContentBrandModel).toJson()).toList(),
      'background': background != null ? (background as ContentBackgroundModel).toJson() : null,
      'grid_columns': gridColumns,
      'grid_rows': gridRows,
      'enable_horizontal_animation': enableHorizontalAnimation,
      'show_on_category_screen': showOnCategoryScreen,
      'show_view_all': showViewAll,
      'media': media != null ? (media as ContentMediaModel).toJson() : null,
      'link': link != null ? (link as ContentLinkModel).toJson() : null,
      'media_items': mediaItems?.map((m) => (m as MediaItemModel).toJson()).toList(),
      'stores': stores?.map((s) => (s as ContentStoreModel).toJson()).toList(),
    };
  }

  static ContentType _parseType(String type) {
    switch (type) {
      case 'product': return ContentType.product;
      case 'category': return ContentType.category;
      case 'brand': return ContentType.brand;
      case 'media': return ContentType.media;
      case 'store': return ContentType.store;
      default: return ContentType.product;
    }
  }

  static ContentStyle _parseStyle(String style) {
    switch (style) {
      case 'style_1': return ContentStyle.style1;
      case 'style_2': return ContentStyle.style2;
      case 'style_3': return ContentStyle.style3;
      case 'style_4': return ContentStyle.style4;
      default: return ContentStyle.style1;
    }
  }

  static ContentSource _parseSource(String source) {
    switch (source) {
      case 'custom': return ContentSource.custom;
      case 'recent': return ContentSource.recent;
      case 'featured': return ContentSource.featured;
      default: return ContentSource.featured;
    }
  }
}


class ContentProductModel extends ContentProduct {
  const ContentProductModel({
    required super.id,
    required super.name,
    required super.price,
    super.comparePrice,
    super.image,
    super.unit,
    super.rating,
    super.reviewCount,
    super.inStock,
  });

  factory ContentProductModel.fromJson(Map<String, dynamic> json) {
    return ContentProductModel(
      id: json['id'] as int,
      name: json['name'] as String,
      price: _parseDouble(json['price']),
      comparePrice: json['compare_price'] != null ? _parseDouble(json['compare_price']) : null,
      image: json['image'] as String?,
      unit: json['unit'] as String?,
      rating: json['rating'] != null ? _parseDouble(json['rating']) : null,
      reviewCount: json['review_count'] as int?,
      inStock: json['in_stock'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'compare_price': comparePrice,
    'image': image,
    'unit': unit,
    'rating': rating,
    'review_count': reviewCount,
  };

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class ContentCategoryModel extends ContentCategory {
  const ContentCategoryModel({
    required super.id,
    required super.name,
    super.image,
    super.products,
  });

  factory ContentCategoryModel.fromJson(Map<String, dynamic> json) {
    return ContentCategoryModel(
      id: json['id'] as int,
      name: json['name'] as String,
      image: json['image'] as String?,
      products: json['products'] != null
          ? (json['products'] as List).map((p) => ContentProductModel.fromJson(p)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'image': image,
    'products': products?.map((p) => (p as ContentProductModel).toJson()).toList(),
  };
}

class ContentBrandModel extends ContentBrand {
  const ContentBrandModel({
    required super.id,
    required super.name,
    super.logo,
  });

  factory ContentBrandModel.fromJson(Map<String, dynamic> json) {
    return ContentBrandModel(
      id: json['id'] as int,
      name: json['name'] as String,
      logo: json['logo'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'logo': logo,
  };
}

class ContentStoreModel extends ContentStore {
  const ContentStoreModel({
    required super.id,
    required super.name,
    super.logo,
    super.rating,
    super.deliveryTime,
    super.isPromoted = false,
    super.discountText,
    super.coverImage,
  });

  factory ContentStoreModel.fromJson(Map<String, dynamic> json) {
    return ContentStoreModel(
      id: json['id'] as int,
      name: json['name'] as String,
      logo: json['logo'] as String?,
      rating: json['rating'] != null ? _parseDouble(json['rating']) : null,
      deliveryTime: json['delivery_time'] as String?,
      isPromoted: json['is_promoted'] as bool? ?? false,
      discountText: json['discount_text'] as String?,
      coverImage: json['cover_image'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'logo': logo,
    'rating': rating,
    'delivery_time': deliveryTime,
    'is_promoted': isPromoted,
    'discount_text': discountText,
    'cover_image': coverImage,
  };

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class ContentMediaModel extends ContentMedia {
  const ContentMediaModel({super.url, super.type, required super.height, super.width});

  factory ContentMediaModel.fromJson(Map<String, dynamic> json) {
    return ContentMediaModel(
      url: json['url'] as String?,
      type: json['type'] as String?,
      height: json['height'] as int? ?? 200,
      width: json['width'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    'type': type,
    'height': height,
    'width': width,
  };
}

class ContentLinkModel extends ContentLink {
  const ContentLinkModel({required super.type, super.id, super.url});

  factory ContentLinkModel.fromJson(Map<String, dynamic> json) {
    return ContentLinkModel(
      type: _parseLinkType(json['type'] as String?),
      id: json['id'] as int?,
      url: json['url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'id': id,
    'url': url,
  };

  static ContentLinkType _parseLinkType(String? type) {
    switch (type) {
      case 'product': return ContentLinkType.product;
      case 'category': return ContentLinkType.category;
      case 'brand': return ContentLinkType.brand;
      case 'store': return ContentLinkType.store;
      case 'url': return ContentLinkType.url;
      default: return ContentLinkType.none;
    }
  }
}

class ContentBackgroundModel extends ContentBackground {
  const ContentBackgroundModel({
    required super.enabled,
    super.type,
    super.color,
    super.mediaUrl,
  });

  factory ContentBackgroundModel.fromJson(Map<String, dynamic> json) {
    return ContentBackgroundModel(
      enabled: json['enabled'] as bool? ?? false,
      type: json['type'] != null ? _parseBackgroundType(json['type'] as String) : null,
      color: json['color'] as String?,
      mediaUrl: json['media_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'type': type?.name,
    'color': color,
    'media_url': mediaUrl,
  };

  static BackgroundType _parseBackgroundType(String type) {
    switch (type) {
      case 'color': return BackgroundType.color;
      case 'image': return BackgroundType.image;
      case 'gif': return BackgroundType.gif;
      case 'video': return BackgroundType.video;
      default: return BackgroundType.color;
    }
  }
}

class MediaItemModel extends MediaItem {
  const MediaItemModel({
    required super.url,
    required super.type,
    required super.linkType,
    super.linkId,
    super.linkUrl,
  });

  factory MediaItemModel.fromJson(Map<String, dynamic> json) {
    return MediaItemModel(
      url: json['url'] as String,
      type: json['type'] as String,
      linkType: _parseLinkType(json['link_type'] as String?),
      linkId: json['link_id'] as int?,
      linkUrl: json['link_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    'type': type,
    'link_type': linkType.name,
    'link_id': linkId,
    'link_url': linkUrl,
  };

  static ContentLinkType _parseLinkType(String? type) {
    switch (type) {
      case 'product': return ContentLinkType.product;
      case 'category': return ContentLinkType.category;
      case 'brand': return ContentLinkType.brand;
      case 'store': return ContentLinkType.store;
      case 'url': return ContentLinkType.url;
      default: return ContentLinkType.none;
    }
  }
}
