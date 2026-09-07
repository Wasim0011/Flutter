import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../../app_config/presentation/bloc/app_config_bloc.dart';
import '../../../home_header/domain/usecases/get_home_header_config.dart';
import '../../../app_content/domain/usecases/get_app_content.dart';

/// Enterprise-level 5-Style Dynamic Splash Screen Engine
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  // Main entrance animation controller
  late AnimationController _mainController;

  // Continuous animation controllers for real-time logo effects
  late AnimationController _logoContinuousController;
  late AnimationController _rotationContinuousController;

  // Entrance animations
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotateAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _taglineOpacityAnimation;

  // Background particles controller
  late AnimationController _particlesController;

  // Loading bar controller
  late AnimationController _loadingController;

  // Dynamic Splash Config Fields from Admin API
  int _activeScreenStyle = 1;
  String? _logoUrl;
  String? _fullscreenMediaUrl;
  String _logoAnimation = 'pulse';
  String _logoSizeKey = 'medium';
  int? _logoSizePx;
  String _backgroundStyle = 'gradient_vibrant';
  Color _primaryColor = AppColors.primary;
  Color _secondaryColor = AppColors.primaryDark;
  Color _backgroundColor = const Color(0xFF0F172A);
  String? _titleText = 'InAllCart';
  String? _subtitleText = 'Everything Delivered to Your Doorstep';
  String _taglineText = 'Fast · Reliable · Premium';
  Color _textColor = Colors.white;
  bool _showTagline = true;
  bool _showLoadingBar = true;
  bool _isActive = true;

  double get _logoDimension {
    if (_logoSizePx != null && _logoSizePx! > 0) {
      return _logoSizePx!.toDouble();
    }
    switch (_logoSizeKey) {
      case 'small':
        return 80.0;
      case 'extra_medium':
        return 120.0;
      case 'large':
        return 140.0;
      case 'extra_large':
        return 170.0;
      case 'medium':
      default:
        return 100.0;
    }
  }

  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _initAnimations();
    _loadCachedSplashConfig();
    _fetchSplashConfig();
    _startAnimationSequence();
  }

  void _loadCachedSplashConfig() {
    try {
      final storage = getIt<StorageService>();
      final cached = storage.getSplashConfig();
      if (cached != null) {
        _applyConfig(cached);
      }
    } catch (_) {}
  }

  void _applyConfig(Map<String, dynamic> response) {
    _activeScreenStyle = (response['active_screen_style'] as num?)?.toInt() ?? 1;
    _logoUrl = response['logo_url'] as String?;
    _fullscreenMediaUrl = response['fullscreen_media_url'] as String?;
    _logoAnimation = response['logo_animation'] ?? 'pulse';
    _logoSizeKey = response['logo_size'] ?? 'medium';
    _logoSizePx = (response['logo_size_px'] as num?)?.toInt();
    _backgroundStyle = response['background_style'] ?? 'gradient_vibrant';
    _primaryColor = _parseHexColor(response['primary_color'], AppColors.primary);
    _secondaryColor = _parseHexColor(response['secondary_color'], AppColors.primaryDark);
    _backgroundColor = _parseHexColor(response['background_color'], const Color(0xFF0F172A));
    _titleText = response['title_text'] as String?;
    _subtitleText = response['subtitle_text'] as String?;
    _taglineText = response['tagline_text'] ?? 'Fast · Reliable · Premium';
    _textColor = _parseHexColor(response['text_color'], Colors.white);
    _showTagline = response['show_tagline'] ?? true;
    _showLoadingBar = response['show_loading_bar'] ?? true;
    _isActive = response['is_active'] ?? true;
  }

  Color _parseHexColor(String? hexString, Color defaultColor) {
    if (hexString == null || hexString.isEmpty) return defaultColor;
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return defaultColor;
    }
  }

  Future<void> _fetchSplashConfig() async {
    try {
      final apiClient = getIt<ApiClient>();
      final response = await apiClient.get<Map<String, dynamic>>(
        '/api/v1/splash-screen',
        parser: (data) => data['data'] as Map<String, dynamic>,
      );

      final storage = getIt<StorageService>();
      await storage.setSplashConfig(response);

      if (mounted && !_hasNavigated) {
        if (storage.getSplashConfig() == null) {
          setState(() {
            _applyConfig(response);
          });
        }
        if (!_isActive) {
          _navigateToNextScreen();
        }
      }
    } catch (_) {}
  }

  void _initAnimations() {
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoContinuousController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _rotationContinuousController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _logoScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.1).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
    ]).animate(_mainController);

    _logoRotateAnimation = Tween<double>(begin: -0.05, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _taglineOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
      ),
    );

    _particlesController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  void _startAnimationSequence() async {
    if (!_isActive) {
      _navigateToNextScreen();
      return;
    }

    _mainController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _loadingController.forward();
    unawaited(_prefetchHomeData());

    await Future.delayed(const Duration(milliseconds: 1000));
    _navigateToNextScreen();
  }

  Future<void> _prefetchHomeData() async {
    final storage = getIt<StorageService>();
    if (!storage.isLoggedIn) return;

    final headerResult = await getIt<GetHomeHeaderConfig>()();
    await headerResult.fold((_) async {}, (config) async {
      final tabIds = config.tabs
          .where((t) => t.id != 0)
          .take(2)
          .map((t) => t.id)
          .toList();

      for (final tabId in tabIds) {
        await getIt<GetAppContent>()(tabId: tabId, forceRefresh: false);
      }
    });
  }

  void _navigateToNextScreen() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final configState = context.read<AppConfigBloc>().state;

      if (configState is AppConfigLoaded && configState.config.maintenanceMode) {
        context.go(
          '/maintenance',
          extra: {
            'title': configState.config.maintenanceTitle,
            'message': configState.config.maintenanceMessage,
            'imageUrl': configState.config.maintenanceImageUrl,
          },
        );
        return;
      }

      context.go(Routes.home);
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _logoContinuousController.dispose();
    _rotationContinuousController.dispose();
    _particlesController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background (Colors / Gradient)
          _buildBackground(),

          // Floating particles
          if (_backgroundStyle == 'geometric_particles' || _backgroundStyle == 'floating_rings')
            _buildParticles(),

          // Dynamic Screen Content according to _activeScreenStyle (1 - 5)
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _mainController,
                _logoContinuousController,
                _rotationContinuousController,
              ]),
              builder: (context, child) => _buildDynamicStyleContent(),
            ),
          ),

          // Loading & Tagline Footer
          Positioned(
            left: 0,
            right: 0,
            bottom: 50,
            child: _buildFooterSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    if (_activeScreenStyle == 2 && _fullscreenMediaUrl != null && _fullscreenMediaUrl!.isNotEmpty) {
      return SizedBox.expand(
        child: CachedImage(
          imageUrl: _fullscreenMediaUrl!,
          fit: BoxFit.cover,
        ),
      );
    }
    if (_backgroundStyle == 'dark_glassmorphic') {
      return Container(color: _backgroundColor);
    } else if (_backgroundStyle == 'solid_brand') {
      return Container(color: _primaryColor);
    } else if (_backgroundStyle == 'geometric_particles') {
      return Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.6, -0.6),
            radius: 1.2,
            colors: [_primaryColor, _backgroundColor],
          ),
        ),
      );
    } else if (_backgroundStyle == 'floating_rings') {
      return Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [_primaryColor, _secondaryColor],
          ),
        ),
      );
    } else {
      return AnimatedBuilder(
        animation: _particlesController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _primaryColor,
                  Color.lerp(
                    _primaryColor,
                    _secondaryColor,
                    0.3 + 0.1 * math.sin(_particlesController.value * math.pi * 2),
                  )!,
                  _secondaryColor,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildParticles() {
    if (_activeScreenStyle == 2) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _particlesController,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlesPainter(_particlesController.value),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildDynamicStyleContent() {
    return _buildUnifiedSplashContent();
  }

  /// Single unified premium splash screen design
  Widget _buildUnifiedSplashContent() {
    if (_activeScreenStyle == 2) {
      return const SizedBox.shrink();
    }

    final hasTitle = _titleText != null && _titleText!.trim().isNotEmpty;
    final hasSubtitle = _subtitleText != null && _subtitleText!.trim().isNotEmpty;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo with entrance + continuous animation
        Transform.rotate(
          angle: _logoRotateAnimation.value,
          child: Transform.scale(
            scale: _logoScaleAnimation.value,
            child: Opacity(
              opacity: _logoOpacityAnimation.value,
              child: _buildLogoWidget(),
            ),
          ),
        ),
        if (hasTitle) ...[
          const SizedBox(height: 24),
          Opacity(
            opacity: _logoOpacityAnimation.value,
            child: Text(
              _titleText!,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: _textColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
        if (hasSubtitle) ...[
          const SizedBox(height: 6),
          Opacity(
            opacity: _taglineOpacityAnimation.value,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _subtitleText!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _textColor.withValues(alpha: 0.85),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLogoWidget() {
    final dimension = _logoDimension;

    Widget logoChild = _logoUrl != null && _logoUrl!.isNotEmpty
        ? CachedImage(
            imageUrl: _logoUrl!,
            width: dimension,
            height: dimension,
            fit: BoxFit.contain,
          )
        : Image.asset(
            'assets/images/applogo.png',
            width: dimension,
            height: dimension,
            fit: BoxFit.contain,
          );

    // Apply continuous animation on top of raw logo
    if (_logoAnimation == 'bounce') {
      logoChild = Transform.translate(
        offset: Offset(0, -8.0 * math.sin(_logoContinuousController.value * math.pi)),
        child: logoChild,
      );
    } else if (_logoAnimation == 'rotating_crown') {
      logoChild = Transform.rotate(
        angle: _rotationContinuousController.value * math.pi * 2,
        child: logoChild,
      );
    } else if (_logoAnimation == 'pulse') {
      logoChild = Transform.scale(
        scale: 0.95 + 0.1 * _logoContinuousController.value,
        child: logoChild,
      );
    } else if (_logoAnimation == 'scale_fade') {
      logoChild = Opacity(
        opacity: 0.7 + 0.3 * _logoContinuousController.value,
        child: Transform.scale(
          scale: 0.92 + 0.12 * _logoContinuousController.value,
          child: logoChild,
        ),
      );
    }

    return SizedBox(
      width: dimension,
      height: dimension,
      child: logoChild,
    );
  }

  Widget _buildFooterSection() {
    return AnimatedBuilder(
      animation: _loadingController,
      builder: (context, child) {
        return Opacity(
          opacity: _loadingController.value,
          child: Column(
            children: [
              if (_showLoadingBar) ...[
                _buildPulsingDots(),
                const SizedBox(height: 16),
              ],
              if (_showTagline)
                Text(
                  _taglineText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textColor.withValues(alpha: 0.8),
                    letterSpacing: 1.2,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPulsingDots() {
    return SizedBox(
      height: 10,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _particlesController,
            builder: (context, child) {
              final delay = index * 0.2;
              final value = ((_particlesController.value + delay) % 1.0);
              final scale = 0.5 + 0.5 * math.sin(value * math.pi);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _textColor.withValues(alpha: 0.8 * scale),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

// Custom painter for floating background particles
class _ParticlesPainter extends CustomPainter {
  final double animationValue;

  _ParticlesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final particles = [
      _Particle(0.1, 0.2, 3, 0.0),
      _Particle(0.3, 0.1, 4, 0.2),
      _Particle(0.5, 0.3, 2, 0.4),
      _Particle(0.7, 0.15, 5, 0.1),
      _Particle(0.9, 0.25, 3, 0.3),
      _Particle(0.15, 0.5, 4, 0.5),
      _Particle(0.35, 0.6, 2, 0.7),
      _Particle(0.55, 0.45, 3, 0.6),
      _Particle(0.75, 0.55, 4, 0.8),
      _Particle(0.85, 0.4, 2, 0.9),
    ];

    for (final p in particles) {
      final progress = (animationValue + p.delay) % 1.0;
      final y = size.height * (1 - progress);
      final x = size.width * p.x + 20 * math.sin(progress * math.pi * 2);
      final opacity = math.sin(progress * math.pi) * 0.3;

      paint.color = Colors.white.withValues(alpha: opacity.clamp(0.0, 0.3));
      canvas.drawCircle(Offset(x, y), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

class _Particle {
  final double x;
  final double y;
  final double radius;
  final double delay;

  const _Particle(this.x, this.y, this.radius, this.delay);
}
