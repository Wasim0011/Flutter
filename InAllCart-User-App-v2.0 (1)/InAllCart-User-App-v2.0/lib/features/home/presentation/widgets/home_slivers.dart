import 'package:flutter/material.dart';

/// A custom SliverPersistentHeaderDelegate that creates a Premium-style
/// sticky header with:
/// - Location bar that scrolls away and fades out
/// - Search bar that sticks to the top
/// - Category tabs that stick below the search bar (transitions to compact mode)
/// - Quick cards that scroll away
/// - Background that spans the full height and transitions to primary color
class PremiumHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget locationWidget;
  final Widget searchBarWidget;
  final Widget Function(bool isCompact) tabsBuilder;
  final Widget cardsWidget;
  final Widget? topHeaderBackgroundWidget;
  final Widget? backgroundWidget;
  final Color? stickyHeaderColor;
  final bool tabsAboveSearch;
  final double tabsHeight;
  final double locationHeight;

  /// Semantic identity of top header background for shouldRebuild
  final String? topBgType;
  final String? topBgColor1;
  final String? topBgColor2;
  final String? topBgStyle;
  final String? topBgImageUrl;

  /// Semantic identity of the background — used in shouldRebuild to avoid
  /// rebuilding when only a new widget instance (same content) was passed.
  final String? backgroundUrl;
  final String? backgroundType;

  /// The currently selected tab ID — tracked so shouldRebuild invalidates
  /// the tab widget cache when selection changes.
  final int? selectedTabId;

  /// Whether the cards widget is horizontal scroll (true) or grid (false).
  /// Used to add extra background height for horizontal cards which sit higher.
  final bool isCardsHorizontal;

  /// Notifier updated each build() call to signal whether the header is fully
  /// collapsed (pinned sticky state). HeaderBackground observes this to pause
  /// its HW video decoder when invisible, freeing it for in-content videos.
  final ValueNotifier<bool>? headerCollapseNotifier;

  // Layout constants
  static const double searchHeight = 64.0;
  static const double stickyTabsHeight = 40.0; // Height of text-only tabs

  // Cached tab widgets — keyed by isCompact so we only rebuild when that flips.
  // Reusing the same widget instance prevents CachedNetworkImage from
  // re-running its fade-in animation on every scroll frame.
  Widget? _cachedTabsCompact;
  Widget? _cachedTabsExpanded;

  PremiumHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.locationWidget,
    required this.searchBarWidget,
    required this.tabsBuilder,
    required this.cardsWidget,
    this.topHeaderBackgroundWidget,
    this.backgroundWidget,
    this.stickyHeaderColor,
    this.tabsAboveSearch = false,
    this.tabsHeight = 0.0,
    this.locationHeight = 60.0,
    this.topBgType,
    this.topBgColor1,
    this.topBgColor2,
    this.topBgStyle,
    this.topBgImageUrl,
    this.backgroundUrl,
    this.backgroundType,
    this.headerCollapseNotifier,
    this.selectedTabId,
    this.isCardsHorizontal = false,
  });

  Widget _getTabs(bool isCompact) {
    if (isCompact) {
      _cachedTabsCompact ??= tabsBuilder(true);
      return _cachedTabsCompact!;
    } else {
      _cachedTabsExpanded ??= tabsBuilder(false);
      return _cachedTabsExpanded!;
    }
  }

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double safeTop = MediaQuery.of(context).padding.top;
    final double currentLocationHeight = locationHeight;
    final double standardSearchHeight = 64.0;

    // Signal collapse state to HeaderBackground so it can pause/resume its
    // HW decoder. Collapsed = shrinkOffset is within 4px of the max extent
    // (i.e. header is fully pinned and the video is hidden behind the bar).
    final bool isCollapsed = shrinkOffset >= (maxHeight - minHeight - 4.0);
    // Only notify when state actually changes to avoid redundant calls
    if (headerCollapseNotifier != null && headerCollapseNotifier!.value != isCollapsed) {
      // Schedule post-frame to avoid setState-during-build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        headerCollapseNotifier!.value = isCollapsed;
      });
    }

    // 1. Calculate Opacities
    // Location fade: Fades out quickly (first 40px of scroll)
    final double locationOpacity = (1.0 - (shrinkOffset / 40.0)).clamp(0.0, 1.0);
    
    // Sticky Background fade: Fades in as we approach pinned state
    // Starts appearing when location is half gone
    final double stickyTrigger = currentLocationHeight * 0.8;
    final double stickyOpacity = ((shrinkOffset - stickyTrigger) / (currentLocationHeight - stickyTrigger)).clamp(0.0, 1.0);

    // 2. Position Calculations
    double searchTop;
    double tabsTop;
    // When compact, use actual configured tabsHeight for sticky tabs
    final double stickyTabsHeight = tabsHeight;

    if (tabsAboveSearch) {
      tabsTop = (safeTop + currentLocationHeight - shrinkOffset).clamp(safeTop, double.infinity);
      searchTop = (safeTop + currentLocationHeight + tabsHeight - 8.0 - shrinkOffset).clamp(safeTop + stickyTabsHeight - 8.0, double.infinity);
    } else {
      searchTop = (safeTop + currentLocationHeight - shrinkOffset).clamp(safeTop, double.infinity);
      tabsTop = searchTop + standardSearchHeight;
    }

    final double topHeaderSectionHeight = safeTop + currentLocationHeight + standardSearchHeight + tabsHeight;

    return Container(
      color: Colors.transparent, // Background widget handles color
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1A. Top Header Bar Background (Location, Module Tabs, Searchbar & AI Section)
          if (topHeaderBackgroundWidget != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: topHeaderSectionHeight + 12.0,
              child: Opacity(
                opacity: (1.0 - (shrinkOffset / (currentLocationHeight + 20.0))).clamp(0.0, 1.0),
                child: topHeaderBackgroundWidget!,
              ),
            ),

          // 1B. Quick Access Cards Background Media (Starts cleanly below header section, extends 14px below cards)
          if (backgroundWidget != null)
            Positioned(
              top: topHeaderSectionHeight - shrinkOffset,
              bottom: isCardsHorizontal ? -48.0 : -30.0,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: (1.0 - (shrinkOffset / (maxHeight - minHeight))).clamp(0.0, 1.0),
                child: backgroundWidget!,
              ),
            ),
            

          // 2. Quick Cards (Anchored 14px above background bottom to leave breathing space)
          Positioned(
            bottom: isCardsHorizontal ? -34.0 : -16.0,
            left: 0,
            right: 0,
            child: cardsWidget,
          ),

          // 3. Sticky "Shield" Background (Primary Color)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: safeTop + standardSearchHeight + stickyTabsHeight,
            child: Opacity(
              opacity: stickyOpacity,
              child: Container(
                color: stickyHeaderColor ?? const Color(0xFFE5E7EB),
              ),
            ),
          ),

          // 4. Tabs (Becomes sticky)
          Positioned(
            top: tabsTop,
            left: 0,
            right: 0,
            child: _getTabs(shrinkOffset > 40),
          ),

          // 5. Location Bar (Scrolls away & Fades)
          Positioned(
            top: safeTop - shrinkOffset,
            left: 0,
            right: 0,
            height: currentLocationHeight,
            child: Opacity(
              opacity: locationOpacity,
              child: locationWidget,
            ),
          ),

          // 6. Search Bar (Sticks to top)
          Positioned(
            top: searchTop,
            left: 0,
            right: 0,
            height: standardSearchHeight,
            child: searchBarWidget,
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(PremiumHeaderDelegate oldDelegate) {
    final tabsChanged = selectedTabId != oldDelegate.selectedTabId;
    if (tabsChanged) {
      _cachedTabsCompact = null;
      _cachedTabsExpanded = null;
    }
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        locationHeight != oldDelegate.locationHeight ||
        tabsHeight != oldDelegate.tabsHeight ||
        tabsAboveSearch != oldDelegate.tabsAboveSearch ||
        stickyHeaderColor != oldDelegate.stickyHeaderColor ||
        tabsChanged ||
        backgroundUrl != oldDelegate.backgroundUrl ||
        backgroundType != oldDelegate.backgroundType ||
        topBgType != oldDelegate.topBgType ||
        topBgColor1 != oldDelegate.topBgColor1 ||
        topBgColor2 != oldDelegate.topBgColor2 ||
        topBgStyle != oldDelegate.topBgStyle ||
        topBgImageUrl != oldDelegate.topBgImageUrl ||
        isCardsHorizontal != oldDelegate.isCardsHorizontal;
  }
}
