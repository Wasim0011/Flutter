import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Samvaad's entry screen: a deliberate, accessible brand entrance that
/// bridges the native launch screen and the authenticated app shell.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _glowScale;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _titleFade;
  late final Animation<double> _taglineFade;
  late final Animation<double> _loaderFade;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.78, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.48, curve: Curves.easeOutBack),
      ),
    );
    _glowScale = Tween<double>(begin: 0.85, end: 1.08).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.10, 0.85, curve: Curves.easeInOut),
      ),
    );

    final Animation<double> titleCurve = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.28, 0.62, curve: Curves.easeOutCubic),
    );
    _titleFade = titleCurve;
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.22),
      end: Offset.zero,
    ).animate(titleCurve);

    _taglineFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.50, 0.82, curve: Curves.easeOut),
    );

    _loaderFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.75, 1.0, curve: Curves.easeOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1.0;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color brandTeal = AppColors.primary;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.25),
            radius: 1.25,
            colors: isDark
                ? <Color>[
                    brandTeal.withValues(alpha: 0.32),
                    AppColors.surfaceDark,
                  ]
                : <Color>[
                    brandTeal.withValues(alpha: 0.14),
                    AppColors.surfaceLight,
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      FadeTransition(
                        opacity: _logoFade,
                        child: ScaleTransition(
                          scale: _logoScale,
                          child: Stack(
                            alignment: Alignment.center,
                            children: <Widget>[
                              ScaleTransition(
                                scale: _glowScale,
                                child: Container(
                                  width: 124,
                                  height: 124,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: <Color>[
                                        AppColors.accent.withValues(
                                          alpha: 0.22,
                                        ),
                                        brandTeal.withValues(alpha: 0.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 100,
                                height: 100,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: brandTeal,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.accent.withValues(
                                      alpha: 0.45,
                                    ),
                                    width: 1.5,
                                  ),
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color: brandTeal.withValues(alpha: 0.30),
                                      blurRadius: 28,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/icon/icon_foreground.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.forum_rounded,
                                    size: 52,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SlideTransition(
                        position: _titleSlide,
                        child: FadeTransition(
                          opacity: _titleFade,
                          child: Text(
                            'Samvaad',
                            style: theme.textTheme.displayLarge?.copyWith(
                              color: isDark ? Colors.white : brandTeal,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      FadeTransition(
                        opacity: _taglineFade,
                        child: Text(
                          'Every voice, every sign, one conversation.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 44),
                      FadeTransition(
                        opacity: _loaderFade,
                        child: const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
