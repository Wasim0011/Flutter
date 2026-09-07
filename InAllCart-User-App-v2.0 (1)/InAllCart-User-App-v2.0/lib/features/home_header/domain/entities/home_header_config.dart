import 'package:equatable/equatable.dart';

/// Home header configuration from backend
class HomeHeaderConfig extends Equatable {
  final bool tabsActive;
  final bool backgroundActive;
  final bool cardsActive;
  final bool tabsHorizontalStyle; // Global toggle for Zepto style
  final String moduleIconStyle; // 'image_only' or 'image_and_name'
  final bool serviceUnavailable;
  final List<HomeHeaderTab> tabs;

  const HomeHeaderConfig({
    required this.tabsActive,
    required this.backgroundActive,
    required this.cardsActive,
    this.tabsHorizontalStyle = false,
    this.moduleIconStyle = 'image_and_name',
    this.serviceUnavailable = false,
    required this.tabs,
  });

  /// Get the first tab (or empty fallback if no tabs)
  HomeHeaderTab? get defaultTab {
    if (tabs.isEmpty) return const HomeHeaderTab.empty();
    return tabs.first;
  }

  @override
  List<Object?> get props => [tabsActive, backgroundActive, cardsActive, tabsHorizontalStyle, moduleIconStyle, serviceUnavailable, tabs];
}

/// A single tab in the home header
class HomeHeaderTab extends Equatable {
  final int id;
  final int? categoryId;
  final String name;
  final String? tabDisplayName;
  final String? categoryImage;
  final bool useHeaderName;
  final bool cardsHorizontal; // Per-header: horizontal scroll or grid
  final bool isHorizontalStyle; // Horizontal Image Only Style (Zepto)
  final String? stickyHeaderColor;
  final TopHeaderBackground? topHeaderBackground;
  final HomeHeaderBackground? background;
  final List<HomeHeaderCard> cards;

  const HomeHeaderTab({
    required this.id,
    this.categoryId,
    required this.name,
    this.tabDisplayName,
    this.categoryImage,
    this.useHeaderName = false,
    this.cardsHorizontal = false,
    this.isHorizontalStyle = false,
    this.stickyHeaderColor,
    this.topHeaderBackground,
    this.background,
    required this.cards,
  });

  const HomeHeaderTab.empty()
      : id = 0,
        categoryId = null,
        name = 'All',
        tabDisplayName = null,
        categoryImage = null,
        useHeaderName = false,
        cardsHorizontal = false,
        isHorizontalStyle = false,
        stickyHeaderColor = null,
        topHeaderBackground = null,
        background = null,
        cards = const [];

  /// Check if this tab has a category assigned (for showing in filter tabs)
  bool get hasCategory => categoryId != null;

  /// Get display name for tab
  String get displayName => tabDisplayName ?? name;

  /// Check if this tab has enough cards to display (minimum 3)
  bool get hasCards => cards.length >= 3;

  /// Get cards for display (all cards up to 6 for horizontal, 3 or 6 for grid)
  List<HomeHeaderCard> get displayCards {
    // Return all cards up to 6 - the widget will handle layout
    return cards.take(6).toList();
  }

  /// Get cards for grid display (up to 12)
  List<HomeHeaderCard> get gridDisplayCards {
    return cards.take(12).toList();
  }

  @override
  List<Object?> get props => [id, categoryId, name, tabDisplayName, categoryImage, useHeaderName, cardsHorizontal, isHorizontalStyle, stickyHeaderColor, topHeaderBackground, background, cards];
}

enum TopHeaderBgType { gradient, solid, image }
enum GradientStyle {
  topToBottom,
  bottomToTop,
  leftToRight,
  rightToLeft,
  topLeftToBottomRight,
  bottomRightToTopLeft,
  topRightToBottomLeft,
  bottomLeftToTopRight,
  diagonal, // legacy alias for topLeftToBottomRight
}

/// Background for Top Header Bar (Location, Searchbar, Module Tabs)
class TopHeaderBackground extends Equatable {
  final TopHeaderBgType type;
  final String? color1;
  final String? color2;
  final GradientStyle style;
  final String? imageUrl;

  const TopHeaderBackground({
    this.type = TopHeaderBgType.gradient,
    this.color1,
    this.color2,
    this.style = GradientStyle.topToBottom,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [type, color1, color2, style, imageUrl];
}

/// Background media for a tab
class HomeHeaderBackground extends Equatable {
  final BackgroundType type;
  final String? url;

  const HomeHeaderBackground({
    required this.type,
    this.url,
  });

  bool get hasMedia => url != null && url!.isNotEmpty;

  @override
  List<Object?> get props => [type, url];
}

enum BackgroundType { image, video, gif }

/// Quick access card (image only, links to category/product/store/url)
class HomeHeaderCard extends Equatable {
  final int id;
  final String? imageUrl;
  final CardLinkType linkType;
  final int? linkId;
  final String? linkUrl;

  const HomeHeaderCard({
    required this.id,
    this.imageUrl,
    required this.linkType,
    this.linkId,
    this.linkUrl,
  });

  @override
  List<Object?> get props => [id, imageUrl, linkType, linkId, linkUrl];
}

enum CardLinkType { category, product, store, url }
