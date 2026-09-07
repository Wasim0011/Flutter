import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Global controller for hiding/showing bottom navigation based on scroll
/// Like Premium apps - hides on scroll down, shows on scroll up
class BottomNavScrollController extends ChangeNotifier {
  static final BottomNavScrollController _instance = BottomNavScrollController._internal();
  factory BottomNavScrollController() => _instance;
  BottomNavScrollController._internal();

  bool _isVisible = true;
  bool get isVisible => _isVisible;

  // Notifier for scroll-to-top (incremented each time home tab is re-tapped)
  int _scrollToTopCount = 0;
  int get scrollToTopCount => _scrollToTopCount;

  void triggerScrollToTop() {
    _scrollToTopCount++;
    notifyListeners();
  }

  double _lastScrollPosition = 0;
  final double _scrollThreshold = 10; // Minimum scroll to trigger hide/show

  /// Call this from any scrollable widget's scroll listener
  void onScroll(ScrollController controller) {
    if (!controller.hasClients) return;
    
    final currentPosition = controller.position.pixels;
    final scrollDirection = controller.position.userScrollDirection;
    
    // Ignore small scrolls
    if ((currentPosition - _lastScrollPosition).abs() < _scrollThreshold) {
      return;
    }

    // At top of list - always show
    if (currentPosition <= 0) {
      if (!_isVisible) {
        _isVisible = true;
        notifyListeners();
      }
      _lastScrollPosition = currentPosition;
      return;
    }

    // Scrolling down - hide
    if (scrollDirection == ScrollDirection.reverse && _isVisible) {
      _isVisible = false;
      notifyListeners();
    }
    // Scrolling up - show
    else if (scrollDirection == ScrollDirection.forward && !_isVisible) {
      _isVisible = true;
      notifyListeners();
    }

    _lastScrollPosition = currentPosition;
  }

  /// Attach this to a ScrollController
  void attachToScrollController(ScrollController controller) {
    controller.addListener(() => onScroll(controller));
  }

  /// Force show the navbar (e.g., when changing tabs)
  void show() {
    if (!_isVisible) {
      _isVisible = true;
      notifyListeners();
    }
  }

  /// Force hide the navbar
  void hide() {
    if (_isVisible) {
      _isVisible = false;
      notifyListeners();
    }
  }

  /// Reset state
  void reset() {
    _isVisible = true;
    _lastScrollPosition = 0;
    notifyListeners();
  }
}

/// Wrapper widget that automatically handles scroll-based navbar visibility
class ScrollableWithNavbarHide extends StatefulWidget {
  final Widget Function(ScrollController controller) builder;
  
  const ScrollableWithNavbarHide({
    super.key,
    required this.builder,
  });

  @override
  State<ScrollableWithNavbarHide> createState() => _ScrollableWithNavbarHideState();
}

class _ScrollableWithNavbarHideState extends State<ScrollableWithNavbarHide> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    BottomNavScrollController().attachToScrollController(_scrollController);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(_scrollController);
  }
}
