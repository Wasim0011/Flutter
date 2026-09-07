import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/home_header_config.dart';

class HomeHeaderConfigModel extends HomeHeaderConfig {
  const HomeHeaderConfigModel({
    required super.tabsActive,
    required super.backgroundActive,
    required super.cardsActive,
    super.tabsHorizontalStyle,
    super.moduleIconStyle,
    super.serviceUnavailable,
    required super.tabs,
  });

  factory HomeHeaderConfigModel.fromJson(Map<String, dynamic> json) {
    final tabsList = (json['tabs'] as List?)
            ?.map((e) => HomeHeaderTabModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return HomeHeaderConfigModel(
      tabsActive: json['tabs_active'] ?? false,
      backgroundActive: json['background_active'] ?? false,
      cardsActive: json['cards_active'] ?? false,
      tabsHorizontalStyle: json['tabs_horizontal_style'] ?? false,
      moduleIconStyle: json['module_icon_style'] ?? 'image_and_name',
      serviceUnavailable: json['service_unavailable'] ?? false,
      tabs: tabsList,
    );
  }

  Map<String, dynamic> toJson() => {
        'tabs_active': tabsActive,
        'background_active': backgroundActive,
        'cards_active': cardsActive,
        'tabs_horizontal_style': tabsHorizontalStyle,
        'module_icon_style': moduleIconStyle,
        'tabs': tabs.map((e) => (e as HomeHeaderTabModel).toJson()).toList(),
      };

  factory HomeHeaderConfigModel.defaultConfig() => const HomeHeaderConfigModel(
        tabsActive: false,
        backgroundActive: false,
        cardsActive: false,
        moduleIconStyle: 'image_and_name',
        tabs: [],
      );
}

class HomeHeaderTabModel extends HomeHeaderTab {
  const HomeHeaderTabModel({
    required super.id,
    super.categoryId,
    required super.name,
    super.tabDisplayName,
    super.categoryImage,
    super.useHeaderName,
    super.cardsHorizontal,
    super.isHorizontalStyle,
    super.stickyHeaderColor,
    super.topHeaderBackground,
    super.background,
    required super.cards,
  });

  factory HomeHeaderTabModel.fromJson(Map<String, dynamic> json) {
    final topBgJson = json['top_header_background'] as Map<String, dynamic>?;
    final backgroundJson = json['background'] as Map<String, dynamic>?;
    final cardsList = (json['cards'] as List?)
            ?.map((e) => HomeHeaderCardModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    // Convert category/icon image URL to full URL
    final rawCategoryImage = (json['icon_url'] ?? json['icon'] ?? json['category_image']) as String?;
    final fullCategoryImage = AppConstants.getFullMediaUrl(rawCategoryImage);

    return HomeHeaderTabModel(
      id: json['id'] ?? 0,
      categoryId: json['category_id'],
      name: json['name'] ?? 'All',
      tabDisplayName: json['tab_display_name'],
      categoryImage: fullCategoryImage.isNotEmpty ? fullCategoryImage : null,
      useHeaderName: json['use_header_name'] ?? false,
      cardsHorizontal: json['cards_horizontal'] ?? false,
      isHorizontalStyle: json['is_horizontal_style'] ?? false,
      stickyHeaderColor: json['sticky_header_color'],
      topHeaderBackground: topBgJson != null
          ? TopHeaderBackgroundModel.fromJson(topBgJson)
          : null,
      background: backgroundJson != null
          ? HomeHeaderBackgroundModel.fromJson(backgroundJson)
          : null,
      cards: cardsList,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category_id': categoryId,
        'name': name,
        'tab_display_name': tabDisplayName,
        'category_image': categoryImage,
        'use_header_name': useHeaderName,
        'cards_horizontal': cardsHorizontal,
        'is_horizontal_style': isHorizontalStyle,
        'sticky_header_color': stickyHeaderColor,
        'top_header_background': topHeaderBackground != null
            ? (topHeaderBackground is TopHeaderBackgroundModel
                ? (topHeaderBackground as TopHeaderBackgroundModel).toJson()
                : {
                    'type': topHeaderBackground!.type.name,
                    'color1': topHeaderBackground!.color1,
                    'color2': topHeaderBackground!.color2,
                    'style': topHeaderBackground!.style.name,
                    'image_url': topHeaderBackground!.imageUrl,
                  })
            : null,
        'background': background != null
            ? (background as HomeHeaderBackgroundModel).toJson()
            : null,
        'cards': cards.map((e) => (e as HomeHeaderCardModel).toJson()).toList(),
      };
}

class TopHeaderBackgroundModel extends TopHeaderBackground {
  const TopHeaderBackgroundModel({
    super.type,
    super.color1,
    super.color2,
    super.style,
    super.imageUrl,
  });

  factory TopHeaderBackgroundModel.fromJson(Map<String, dynamic> json) {
    final rawUrl = json['image_url'] as String?;
    final fullUrl = AppConstants.getFullMediaUrl(rawUrl);

    final rawC1 = json['color1'] as String?;
    final rawC2 = json['color2'] as String?;

    return TopHeaderBackgroundModel(
      type: _parseBgType(json['type']),
      color1: (rawC1 != null && rawC1.isNotEmpty) ? rawC1 : null,
      color2: (rawC2 != null && rawC2.isNotEmpty) ? rawC2 : null,
      style: _parseStyle(json['style']),
      imageUrl: fullUrl.isNotEmpty ? fullUrl : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'color1': color1,
        'color2': color2,
        'style': style.name,
        'image_url': imageUrl,
      };

  static TopHeaderBgType _parseBgType(String? type) {
    return switch (type) {
      'solid' => TopHeaderBgType.solid,
      'image' => TopHeaderBgType.image,
      _ => TopHeaderBgType.gradient,
    };
  }

  static GradientStyle _parseStyle(String? style) {
    return switch (style) {
      'bottom_to_top' => GradientStyle.bottomToTop,
      'left_to_right' => GradientStyle.leftToRight,
      'right_to_left' => GradientStyle.rightToLeft,
      'top_left_to_bottom_right' => GradientStyle.topLeftToBottomRight,
      'bottom_right_to_top_left' => GradientStyle.bottomRightToTopLeft,
      'top_right_to_bottom_left' => GradientStyle.topRightToBottomLeft,
      'bottom_left_to_top_right' => GradientStyle.bottomLeftToTopRight,
      'diagonal' => GradientStyle.topLeftToBottomRight,
      _ => GradientStyle.topToBottom,
    };
  }
}

class HomeHeaderBackgroundModel extends HomeHeaderBackground {
  const HomeHeaderBackgroundModel({
    required super.type,
    super.url,
  });

  factory HomeHeaderBackgroundModel.fromJson(Map<String, dynamic> json) {
    // Convert relative URL to full URL
    final rawUrl = json['url'] as String?;
    final fullUrl = AppConstants.getFullMediaUrl(rawUrl);
    
    return HomeHeaderBackgroundModel(
      type: _parseBackgroundType(json['type']),
      url: fullUrl.isNotEmpty ? fullUrl : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'url': url,
      };

  static BackgroundType _parseBackgroundType(String? type) {
    return switch (type) {
      'video' => BackgroundType.video,
      'gif' => BackgroundType.gif,
      _ => BackgroundType.image,
    };
  }
}

class HomeHeaderCardModel extends HomeHeaderCard {
  const HomeHeaderCardModel({
    required super.id,
    super.imageUrl,
    required super.linkType,
    super.linkId,
    super.linkUrl,
  });

  factory HomeHeaderCardModel.fromJson(Map<String, dynamic> json) {
    // Convert relative URL to full URL
    final rawImageUrl = json['image_url'] as String?;
    final fullImageUrl = AppConstants.getFullMediaUrl(rawImageUrl);
    
    return HomeHeaderCardModel(
      id: json['id'] ?? 0,
      imageUrl: fullImageUrl.isNotEmpty ? fullImageUrl : null,
      linkType: _parseLinkType(json['link_type']),
      linkId: json['link_id'],
      linkUrl: json['link_url'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'image_url': imageUrl,
        'link_type': linkType.name,
        'link_id': linkId,
        'link_url': linkUrl,
      };

  static CardLinkType _parseLinkType(String? type) {
    return switch (type) {
      'product' => CardLinkType.product,
      'store' => CardLinkType.store,
      'url' => CardLinkType.url,
      _ => CardLinkType.category,
    };
  }
}

/// Response wrapper with ETag support
class HomeHeaderResponse {
  final HomeHeaderConfigModel? config;
  final bool notModified;
  final String? etag;

  HomeHeaderResponse({
    this.config,
    this.notModified = false,
    this.etag,
  });
}
