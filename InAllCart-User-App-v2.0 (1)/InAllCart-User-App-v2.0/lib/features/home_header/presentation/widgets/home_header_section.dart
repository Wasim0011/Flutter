import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/home_header_config.dart';
import '../bloc/home_header_bloc.dart';
import 'header_background.dart';
import 'header_tabs.dart';
import 'quick_access_cards.dart';

/// Reusable home header section widget with background, tabs, and quick access cards.
/// 
/// This widget can be used in any screen that needs the Blinkit-style header.
/// It manages its own BLoC instance or can use an existing one from the widget tree.
/// 
/// Example usage:
/// ```dart
/// HomeHeaderSection(
///   showTabs: true,
///   showCards: true,
///   onCardTap: (card) => _handleCardTap(card),
///   headerBuilder: (context, hasBackground) => MyCustomHeader(hasBackground: hasBackground),
/// )
/// ```
class HomeHeaderSection extends StatefulWidget {
  /// Whether to show category tabs (if available from backend)
  final bool showTabs;
  
  /// Whether to show quick access cards (if available from backend)
  final bool showCards;
  
  /// Callback when a quick access card is tapped
  final ValueChanged<HomeHeaderCard>? onCardTap;
  
  /// Callback when a tab is selected
  final ValueChanged<HomeHeaderTab>? onTabSelected;
  
  /// Custom header content builder (location bar, search bar, etc.)
  /// The [hasBackground] parameter indicates if there's an active background media
  final Widget Function(BuildContext context, bool hasBackground)? headerBuilder;
  
  /// Whether to manage its own BLoC instance (true) or use existing from tree (false)
  final bool ownBloc;
  
  /// Callback when header height changes (useful for parent to adjust background)
  final ValueChanged<double>? onHeightChanged;

  const HomeHeaderSection({
    super.key,
    this.showTabs = true,
    this.showCards = true,
    this.onCardTap,
    this.onTabSelected,
    this.headerBuilder,
    this.ownBloc = false,
    this.onHeightChanged,
  });

  @override
  State<HomeHeaderSection> createState() => _HomeHeaderSectionState();
}

class _HomeHeaderSectionState extends State<HomeHeaderSection> {
  HomeHeaderBloc? _ownBloc;
  final GlobalKey _contentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.ownBloc) {
      _ownBloc = getIt<HomeHeaderBloc>()..add(const LoadHomeHeader());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeight());
  }

  @override
  void dispose() {
    _ownBloc?.close();
    super.dispose();
  }

  void _measureHeight() {
    final context = _contentKey.currentContext;
    if (context != null && widget.onHeightChanged != null) {
      final box = context.findRenderObject() as RenderBox?;
      if (box != null) {
        widget.onHeightChanged!(box.size.height);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ownBloc && _ownBloc != null) {
      return BlocProvider.value(
        value: _ownBloc!,
        child: _buildContent(context),
      );
    }
    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context) {
    return BlocConsumer<HomeHeaderBloc, HomeHeaderState>(
      listener: (context, state) {
        // Measure height after state changes
        WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeight());
      },
      builder: (context, state) {
        return Container(
          key: _contentKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Custom header content (location, search, etc.)
              if (widget.headerBuilder != null)
                widget.headerBuilder!(
                  context,
                  _hasBackground(state),
                ),

              // Category tabs
              if (widget.showTabs && state is HomeHeaderLoaded)
                _buildTabs(context, state),

              // Quick access cards
              if (widget.showCards && state is HomeHeaderLoaded)
                _buildCards(context, state),
            ],
          ),
        );
      },
    );
  }

  bool _hasBackground(HomeHeaderState state) {
    if (state is HomeHeaderLoaded) {
      return state.config.backgroundActive &&
          state.selectedTab.background?.hasMedia == true;
    }
    return false;
  }

  Widget _buildTabs(BuildContext context, HomeHeaderLoaded state) {
    // Only show tabs if tabs_active is enabled and there are tabs with categories
    final tabsWithCategory = state.config.tabs.where((t) => t.hasCategory).toList();
    if (!state.config.tabsActive || tabsWithCategory.isEmpty) {
      return const SizedBox.shrink();
    }

    return HeaderTabs(
      tabs: state.config.tabs,
      selectedTabId: state.selectedTab.id,
      moduleIconStyle: state.config.moduleIconStyle,
      onTabSelected: (tabId) {
        context.read<HomeHeaderBloc>().add(SelectTab(tabId));
        
        // Find the selected tab and notify parent
        if (widget.onTabSelected != null) {
          final selectedTab = state.config.tabs.firstWhere(
            (tab) => tab.id == tabId,
            orElse: () => state.selectedTab,
          );
          widget.onTabSelected!(selectedTab);
        }
      },
    );
  }

  Widget _buildCards(BuildContext context, HomeHeaderLoaded state) {
    if (!state.config.cardsActive || !state.selectedTab.hasCards) {
      return const SizedBox.shrink();
    }

    // Use per-tab cardsHorizontal setting
    final isHorizontal = state.selectedTab.cardsHorizontal;
    
    // For horizontal: show all cards, for grid: show 3 or 6
    final cards = isHorizontal 
        ? state.selectedTab.displayCards 
        : state.selectedTab.gridDisplayCards;

    return QuickAccessCards(
      cards: cards,
      isHorizontal: isHorizontal,
      onCardTap: widget.onCardTap ?? (_) {},
    );
  }
}

/// A complete header section with background that can be used as a sliver or regular widget.
/// 
/// This widget includes the background layer and handles all the complexity of
/// positioning the background behind the content.
/// 
/// Example usage in a CustomScrollView:
/// ```dart
/// CustomScrollView(
///   slivers: [
///     SliverToBoxAdapter(
///       child: HomeHeaderWithBackground(
///         onCardTap: (card) => _handleCardTap(card),
///         topBarBuilder: (context, hasBackground) => MyTopBar(hasBackground: hasBackground),
///         searchBarBuilder: (context, hasBackground) => MySearchBar(),
///       ),
///     ),
///     // ... other slivers
///   ],
/// )
/// ```
class HomeHeaderWithBackground extends StatefulWidget {
  /// Callback when a quick access card is tapped
  final ValueChanged<HomeHeaderCard>? onCardTap;
  
  /// Callback when a tab is selected (passes tab ID for content filtering)
  final ValueChanged<int?>? onTabSelected;
  
  /// Builder for the top bar (location, notifications, etc.)
  final Widget Function(BuildContext context, bool hasBackground)? topBarBuilder;
  
  /// Builder for the search bar
  final Widget Function(BuildContext context, bool hasBackground)? searchBarBuilder;
  
  /// Whether to show category tabs
  final bool showTabs;
  
  /// Whether to show quick access cards
  final bool showCards;
  
  /// Whether to manage its own BLoC instance
  final bool ownBloc;

  /// Whether to show the background layer
  final bool showBackground;

  const HomeHeaderWithBackground({
    super.key,
    this.onCardTap,
    this.onTabSelected,
    this.topBarBuilder,
    this.searchBarBuilder,
    this.showTabs = true,
    this.showCards = true,
    this.ownBloc = false,
    this.showBackground = true,
  });

  @override
  State<HomeHeaderWithBackground> createState() => _HomeHeaderWithBackgroundState();
}

class _HomeHeaderWithBackgroundState extends State<HomeHeaderWithBackground> {
  HomeHeaderBloc? _ownBloc;
  double _contentHeight = 300;
  final GlobalKey _contentKey = GlobalKey();
  
  // Minimum height for background when no cards (approx height of 6 cards area)
  static const double _minBackgroundHeight = 180.0;

  @override
  void initState() {
    super.initState();
    if (widget.ownBloc) {
      _ownBloc = getIt<HomeHeaderBloc>()..add(const LoadHomeHeader());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeight());
  }

  @override
  void dispose() {
    _ownBloc?.close();
    super.dispose();
  }

  void _measureHeight() {
    final context = _contentKey.currentContext;
    if (context != null) {
      final box = context.findRenderObject() as RenderBox?;
      if (box != null && mounted) {
        setState(() => _contentHeight = box.size.height);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = widget.ownBloc ? _ownBloc : context.read<HomeHeaderBloc>();
    
    if (bloc == null) {
      return const SizedBox.shrink();
    }

    Widget content = BlocConsumer<HomeHeaderBloc, HomeHeaderState>(
      bloc: bloc,
      listener: (context, state) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeight());
      },
      builder: (context, state) {
        return Stack(
          children: [
            // Background layer
            _buildBackground(context, state),
            
            // Content layer
            _buildContentLayer(context, state),
          ],
        );
      },
    );

    if (widget.ownBloc && _ownBloc != null) {
      return BlocProvider.value(
        value: _ownBloc!,
        child: content,
      );
    }

    return content;
  }

  Widget _buildBackground(BuildContext context, HomeHeaderState state) {
    if (!widget.showBackground) {
      return const SizedBox.shrink();
    }

    final topPadding = MediaQuery.of(context).padding.top;
    
    if (state is HomeHeaderLoaded) {
      final config = state.config;
      final selectedTab = state.selectedTab;
      final hasBackground = config.backgroundActive && selectedTab.background?.hasMedia == true;

      if (hasBackground) {
        // Calculate background height - use content height or minimum height for cards area
        final hasCards = config.cardsActive && selectedTab.hasCards;
        final backgroundHeight = hasCards 
            ? _contentHeight + topPadding
            : _contentHeight + topPadding + _minBackgroundHeight;
        
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: backgroundHeight,
          child: HeaderBackground(
            background: selectedTab.background!,
            extendBelowCards: true,
          ),
        );
      }
    }

    // Default gradient background
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: _contentHeight + topPadding,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withValues(alpha: 0.15),
              AppColors.primary.withValues(alpha: 0.08),
              AppColors.primary.withValues(alpha: 0.02),
              Colors.transparent,
            ],
            stops: const [0.0, 0.4, 0.7, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildContentLayer(BuildContext context, HomeHeaderState state) {
    final loadedState = state is HomeHeaderLoaded ? state : null;
    final hasBackground = loadedState != null &&
        loadedState.config.backgroundActive &&
        loadedState.selectedTab.background?.hasMedia == true;
    
    // Check if we need extra spacing for background extension
    // When hasBackground is true, loadedState is guaranteed non-null
    final loaded = loadedState;
    final needsExtraSpacing = hasBackground && loaded != null &&
        (!loaded.config.cardsActive || !loaded.selectedTab.hasCards);

    return Container(
      key: _contentKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.top),
          
          // Top bar
          if (widget.topBarBuilder != null)
            widget.topBarBuilder!(context, hasBackground),
          
          // Search bar
          if (widget.searchBarBuilder != null)
            widget.searchBarBuilder!(context, hasBackground),
          
          // Tabs
          if (widget.showTabs && state is HomeHeaderLoaded)
            _buildTabs(context, state),
          
          // Cards
          if (widget.showCards && state is HomeHeaderLoaded)
            _buildCards(context, state),
          
          // Extra spacing when background is active but no cards
          // This extends the background area visually
          if (needsExtraSpacing)
            SizedBox(height: _minBackgroundHeight),
          
          // Bottom spacing
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context, HomeHeaderLoaded state) {
    // Only show tabs if tabs_active is enabled and there are tabs with categories
    final tabsWithCategory = state.config.tabs.where((t) => t.hasCategory).toList();
    if (!state.config.tabsActive || tabsWithCategory.isEmpty) {
      return const SizedBox.shrink();
    }

    return HeaderTabs(
      tabs: state.config.tabs,
      selectedTabId: state.selectedTab.id,
      moduleIconStyle: state.config.moduleIconStyle,
      onTabSelected: (tabId) {
        final bloc = widget.ownBloc ? _ownBloc : context.read<HomeHeaderBloc>();
        bloc?.add(SelectTab(tabId));
        
        // Pass the tab ID to parent for content filtering
        widget.onTabSelected?.call(tabId);
      },
    );
  }

  Widget _buildCards(BuildContext context, HomeHeaderLoaded state) {
    if (!state.config.cardsActive || !state.selectedTab.hasCards) {
      return const SizedBox.shrink();
    }

    // Use per-tab cardsHorizontal setting
    final isHorizontal = state.selectedTab.cardsHorizontal;
    
    // For horizontal: show all cards, for grid: show 3 or 6
    final cards = isHorizontal 
        ? state.selectedTab.displayCards 
        : state.selectedTab.gridDisplayCards;

    return QuickAccessCards(
      cards: cards,
      isHorizontal: isHorizontal,
      onCardTap: widget.onCardTap ?? (_) {},
    );
  }
}
