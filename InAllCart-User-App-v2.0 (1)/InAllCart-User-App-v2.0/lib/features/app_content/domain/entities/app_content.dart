import 'package:equatable/equatable.dart';

enum ContentType { product, category, brand, media, store }
enum ContentStyle { style1, style2, style3, style4 }
enum ContentSource { custom, recent, featured }
enum ContentLinkType { none, product, category, brand, store, url }
enum BackgroundType { color, image, gif, video }

class AppContent extends Equatable {
  final int id;
  final int? headerTabId;
  final ContentType type;
  final ContentStyle style;
  final String? title;
  final bool showTitle;
  final String? subtitle;
  final bool showSubtitle;
  final ContentSource? source;
  final int sortOrder;
  
  // For product/category/brand widgets
  final List<ContentProduct>? products;
  final List<ContentCategory>? categories;
  final List<ContentBrand>? brands;
  final ContentBackground? background;
  final int? gridColumns;
  final int? gridRows;
  final bool enableHorizontalAnimation;
  final bool showOnCategoryScreen;
  final bool showViewAll;
  
  // For media widgets
  final ContentMedia? media;
  final ContentLink? link;
  // For store widgets
  final List<ContentStore>? stores;
  final List<MediaItem>? mediaItems;

  const AppContent({
    required this.id,
    this.headerTabId,
    required this.type,
    required this.style,
    this.title,
    required this.showTitle,
    this.subtitle,
    required this.showSubtitle,
    this.source,
    required this.sortOrder,
    this.products,
    this.categories,
    this.brands,
    this.stores,
    this.background,
    this.gridColumns,
    this.gridRows,
    this.enableHorizontalAnimation = false,
    this.showOnCategoryScreen = false,
    this.showViewAll = false,
    this.media,
    this.link,
    this.mediaItems,
  });

  @override
  List<Object?> get props => [
    id, headerTabId, type, style, title, showTitle, subtitle, showSubtitle, 
    source, sortOrder, gridColumns, gridRows, enableHorizontalAnimation, 
    showOnCategoryScreen, showViewAll, mediaItems, stores
  ];
}

class ContentProduct extends Equatable {
  final int id;
  final String name;
  final double price;
  final double? comparePrice;
  final String? image;
  final String? unit;
  final double? rating;
  final int? reviewCount;
  final bool inStock;

  const ContentProduct({
    required this.id,
    required this.name,
    required this.price,
    this.comparePrice,
    this.image,
    this.unit,
    this.rating,
    this.reviewCount,
    this.inStock = true,
  });

  @override
  List<Object?> get props => [id, name, price, comparePrice, image, unit, rating, reviewCount, inStock];
}

class ContentCategory extends Equatable {
  final int id;
  final String name;
  final String? image;
  final List<ContentProduct>? products; // For style_3

  const ContentCategory({
    required this.id,
    required this.name,
    this.image,
    this.products,
  });

  @override
  List<Object?> get props => [id, name, image, products];
}

class ContentBrand extends Equatable {
  final int id;
  final String name;
  final String? logo;

  const ContentBrand({
    required this.id,
    required this.name,
    this.logo,
  });

  @override
  List<Object?> get props => [id, name, logo];
}

class ContentStore extends Equatable {
  final int id;
  final String name;
  final String? logo;
  final double? rating;
  final String? deliveryTime;
  final bool isPromoted;
  final String? coverImage;
  final String? discountText;

  const ContentStore({
    required this.id,
    required this.name,
    this.logo,
    this.rating,
    this.deliveryTime,
    this.isPromoted = false,
    this.coverImage,
    this.discountText,
  });

  @override
  List<Object?> get props => [id, name, logo, rating, deliveryTime, isPromoted, coverImage, discountText];
}

class ContentBackground extends Equatable {
  final bool enabled;
  final BackgroundType? type;
  final String? color;
  final String? mediaUrl;

  const ContentBackground({
    required this.enabled,
    this.type,
    this.color,
    this.mediaUrl,
  });

  @override
  List<Object?> get props => [enabled, type, color, mediaUrl];
}

class ContentMedia extends Equatable {
  final String? url;
  final String? type;
  final int height;
  final int? width;

  const ContentMedia({this.url, this.type, required this.height, this.width});

  @override
  List<Object?> get props => [url, type, height, width];
}

class ContentLink extends Equatable {
  final ContentLinkType type;
  final int? id;
  final String? url;

  const ContentLink({required this.type, this.id, this.url});

  @override
  List<Object?> get props => [type, id, url];
}

class MediaItem extends Equatable {
  final String url;
  final String type;
  final ContentLinkType linkType;
  final int? linkId;
  final String? linkUrl;

  const MediaItem({
    required this.url,
    required this.type,
    required this.linkType,
    this.linkId,
    this.linkUrl,
  });

  @override
  List<Object?> get props => [url, type, linkType, linkId, linkUrl];
}
