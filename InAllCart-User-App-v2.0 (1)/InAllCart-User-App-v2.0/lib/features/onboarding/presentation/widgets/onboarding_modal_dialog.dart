import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../../app_config/domain/entities/app_config.dart';
import '../bloc/onboarding_bloc.dart';

/// Modern Home Page Onboarding Popup Overlay Dialog matching reference design
class OnboardingModalDialog extends StatefulWidget {
  const OnboardingModalDialog({super.key});

  static Future<void> show(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      builder: (context) => const OnboardingModalDialog(),
    );
  }

  @override
  State<OnboardingModalDialog> createState() => _OnboardingModalDialogState();
}

class _OnboardingModalDialogState extends State<OnboardingModalDialog> {
  late final PageController _pageController;
  Timer? _autoSlideTimer;
  int _totalScreens = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _stopAutoSlideTimer();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlideTimer(int count) {
    _stopAutoSlideTimer();
    if (count <= 1) return;
    _totalScreens = count;
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || !_pageController.hasClients) {
        timer.cancel();
        return;
      }
      final currentPage = _pageController.page?.round() ?? 0;
      final nextPage = (currentPage + 1) % _totalScreens;

      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _stopAutoSlideTimer() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = null;
  }

  void _dismissDialog() {
    _stopAutoSlideTimer();
    getIt<StorageService>().setOnboardingCompleted(true);
    if (mounted) {
      final navigator = Navigator.of(context, rootNavigator: true);
      if (navigator.canPop()) {
        navigator.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocProvider(
      create: (_) => getIt<OnboardingBloc>()..add(LoadOnboardingScreens()),
      child: BlocConsumer<OnboardingBloc, OnboardingState>(
        listener: (context, state) {
          if (state is OnboardingCompleted) {
            _dismissDialog();
          }
          if (state is OnboardingLoaded) {
            if (_autoSlideTimer == null && state.screens.length > 1) {
              _startAutoSlideTimer(state.screens.length);
            }
            if (_pageController.hasClients &&
                (_pageController.page?.round() ?? 0) != state.currentPage) {
              _pageController.animateToPage(
                state.currentPage,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
              );
            }
          }
        },
        builder: (context, state) {
          if (state is OnboardingInitial || state is OnboardingLoading) {
            return const Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
          }

          if (state is OnboardingError || state is! OnboardingLoaded) {
            // Dismiss silently if error or empty
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                final nav = Navigator.of(context, rootNavigator: true);
                if (nav.canPop()) nav.pop();
              }
            });
            return const SizedBox.shrink();
          }

          final screens = state.screens;
          if (screens.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                final nav = Navigator.of(context, rootNavigator: true);
                if (nav.canPop()) nav.pop();
              }
            });
            return const SizedBox.shrink();
          }

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            elevation: 0,
            child: SizedBox(
              width: size.width * 0.88,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),

                  // Swipeable Content Area
                  SizedBox(
                    height: (size.height * 0.52).clamp(320.0, 520.0),
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: screens.length,
                      onPageChanged: (index) {
                        context.read<OnboardingBloc>().add(GoToPage(index));
                        // Restart 5s timer on manual user swipe
                        _startAutoSlideTimer(screens.length);
                      },
                      itemBuilder: (context, index) {
                        return _buildScreenContent(context, screens[index], size);
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Smooth Page Indicator Dots
                  if (screens.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: SmoothPageIndicator(
                        controller: _pageController,
                        count: screens.length,
                        effect: ExpandingDotsEffect(
                          activeDotColor: Colors.white,
                          dotColor: Colors.white.withValues(alpha: 0.3),
                          dotHeight: 7,
                          dotWidth: 7,
                          expansionFactor: 3.5,
                          spacing: 8,
                        ),
                      ),
                    ),

                  // Bottom Action Text Button ("Let's go!" / "Next ➔")
                  GestureDetector(
                    onTap: () {
                      if (state.isLastPage) {
                        context.read<OnboardingBloc>().add(CompleteOnboardingEvent());
                      } else {
                        context.read<OnboardingBloc>().add(NextPage());
                        _startAutoSlideTimer(screens.length);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      color: Colors.transparent,
                      child: Text(
                        state.isLastPage ? "Let's go!" : 'Next ➔',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white,
                          decorationThickness: 1.5,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScreenContent(BuildContext context, OnboardingScreen screen, Size size) {
    final cardHeight = (size.height * 0.32).clamp(180.0, 320.0);

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Clean Image Widget without background card or border
          SizedBox(
            width: size.width * 0.82,
            height: cardHeight,
            child: _buildImageWidget(screen.imageUrl),
          ),

          const SizedBox(height: 20),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              screen.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.3,
                height: 1.2,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              screen.subtitle,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.75),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(String imageUrl) {
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return CachedImage(
        imageUrl: imageUrl,
        fit: BoxFit.contain,
        errorWidget: _buildPlaceholder(),
      );
    } else if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    } else if (imageUrl.isNotEmpty) {
      final fullUrl =
          'https://demo2.inallcart.com/storage/${imageUrl.startsWith('/') ? imageUrl.substring(1) : imageUrl}';
      return CachedImage(
        imageUrl: fullUrl,
        fit: BoxFit.contain,
        errorWidget: _buildPlaceholder(),
      );
    } else {
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return const Center(
      child: Icon(
        Icons.shopping_bag_outlined,
        size: 64,
        color: Colors.white38,
      ),
    );
  }
}
