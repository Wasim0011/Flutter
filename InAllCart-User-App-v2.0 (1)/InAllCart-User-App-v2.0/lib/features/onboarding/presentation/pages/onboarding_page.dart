import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/onboarding_bloc.dart';
import '../widgets/onboarding_screen_widget.dart';

/// State-of-the-Art Modern Onboarding Page Engine
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocProvider(
        create: (_) => getIt<OnboardingBloc>()..add(LoadOnboardingScreens()),
        child: BlocConsumer<OnboardingBloc, OnboardingState>(
          listener: (context, state) {
            if (state is OnboardingCompleted) {
              context.go(Routes.home);
            }
            if (state is OnboardingLoaded) {
              if (_pageController.hasClients) {
                _pageController.animateToPage(
                  state.currentPage,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOutCubic,
                );
              }
            }
          },
          builder: (context, state) {
            if (state is OnboardingLoading) {
              return const Scaffold(
                backgroundColor: Colors.white,
                body: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }

            if (state is OnboardingError) {
              return Scaffold(
                backgroundColor: Colors.white,
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            context.read<OnboardingBloc>().add(LoadOnboardingScreens());
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            if (state is OnboardingLoaded) {
              final isLastScreen = state.isLastPage;

              return Scaffold(
                backgroundColor: Colors.white,
                body: SafeArea(
                  child: Stack(
                    children: [
                      // Top Bar with Skip Button
                      Positioned(
                        top: 12,
                        right: 20,
                        child: InkWell(
                          onTap: () {
                            context.read<OnboardingBloc>().add(SkipOnboarding());
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.15),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Skip',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Main Onboarding PageView
                      Positioned.fill(
                        child: Column(
                          children: [
                            const SizedBox(height: 50),

                            // Dynamic Screens PageView
                            Expanded(
                              child: PageView.builder(
                                controller: _pageController,
                                itemCount: state.screens.length,
                                onPageChanged: (index) {
                                  context.read<OnboardingBloc>().add(GoToPage(index));
                                },
                                itemBuilder: (context, index) {
                                  final screen = state.screens[index];
                                  return OnboardingScreenWidget(screen: screen);
                                },
                              ),
                            ),

                            // Page Indicator Dots
                            if (state.screens.length > 1)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: SmoothPageIndicator(
                                  controller: _pageController,
                                  count: state.screens.length,
                                  effect: ExpandingDotsEffect(
                                    activeDotColor: AppColors.primary,
                                    dotColor: AppColors.primary.withValues(alpha: 0.2),
                                    dotHeight: 8,
                                    dotWidth: 8,
                                    expansionFactor: 4,
                                    spacing: 8,
                                  ),
                                ),
                              ),

                            // Bottom Primary Action Button ("Let's Go!")
                            Padding(
                              padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
                              child: Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      Color(0xFFEA580C),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      if (isLastScreen) {
                                        context.read<OnboardingBloc>().add(CompleteOnboardingEvent());
                                      } else {
                                        context.read<OnboardingBloc>().add(NextPage());
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(28),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            isLastScreen ? "Let's Go!" : 'Next',
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.arrow_forward_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
