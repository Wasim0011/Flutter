import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../app_config/presentation/bloc/app_config_bloc.dart';

class MaintenancePage extends StatefulWidget {
  final String title;
  final String message;
  final String? imageUrl;

  const MaintenancePage({
    super.key,
    required this.title,
    required this.message,
    this.imageUrl,
  });

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _floatController;
  late AnimationController _bgController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatAnimation;

  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // Pulse animation for the icon rings
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Float animation for the illustration
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Background animation
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _retryConnection() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      context.read<AppConfigBloc>().add(RefreshAppConfig());
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryDark,
                  Color.lerp(
                    AppColors.primaryDark,
                    const Color(0xFF1E1B4B),
                    0.4 + 0.2 * math.sin(_bgController.value * math.pi * 2),
                  )!,
                  const Color(0xFF0F172A),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative background circles
              _buildBackgroundDecor(),

              // Main content
              Column(
                children: [
                  const Spacer(flex: 1),

                  // Illustration / Icon area
                  _buildIllustration(),

                  const SizedBox(height: 48),

                  // Title & message
                  _buildTextContent(),

                  const SizedBox(height: 40),

                  // Progress indicator
                  _buildProgressBar(),

                  const Spacer(flex: 2),

                  // Retry button
                  _buildRetryButton(),

                  const SizedBox(height: 48),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundDecor() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _bgController,
        builder: (context, child) {
          return CustomPaint(
            painter: _BackgroundPainter(_bgController.value),
          );
        },
      ),
    );
  }

  Widget _buildIllustration() {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: child,
        );
      },
      child: widget.imageUrl != null
          ? _buildNetworkImage()
          : _buildDefaultIcon(),
    );
  }

  Widget _buildNetworkImage() {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 40,
            spreadRadius: 10,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: CachedNetworkImage(
          imageUrl: widget.imageUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildDefaultIcon(),
          errorWidget: (context, url, error) => _buildDefaultIcon(),
        ),
      ),
    );
  }

  Widget _buildDefaultIcon() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer ring
            Transform.scale(
              scale: _pulseAnimation.value * 1.3,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            // Middle ring
            Transform.scale(
              scale: _pulseAnimation.value * 1.15,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            // Inner circle with icon
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.15),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.construction_rounded,
                size: 64,
                color: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          // Title
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 16),

          // Divider line
          Container(
            width: 50,
            height: 3,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryLight, AppColors.secondary],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 20),

          // Message
          Text(
            widget.message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.6,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          // Animated shimmer bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (context, child) {
                return Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.1),
                        AppColors.primaryLight.withValues(alpha: 0.8),
                        AppColors.secondary.withValues(alpha: 0.8),
                        Colors.white.withValues(alpha: 0.1),
                      ],
                      stops: [
                        0.0,
                        (_bgController.value * 2).clamp(0.0, 0.8),
                        (_bgController.value * 2 + 0.2).clamp(0.0, 1.0),
                        1.0,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Maintenance in progress...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.45),
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetryButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _isRefreshing
            ? Container(
                height: 56,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withValues(alpha: 0.08),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              )
            : GestureDetector(
                onTap: _retryConnection,
                child: Container(
                  height: 56,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [
                        Colors.white,
                        Color(0xFFF0F0FF),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Check Again',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

// Custom painter for animated background particles/circles
class _BackgroundPainter extends CustomPainter {
  final double progress;

  _BackgroundPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final circles = [
      _Circle(0.85, -0.05, 180, 0.0),
      _Circle(-0.1, 0.15, 140, 0.3),
      _Circle(1.0, 0.6, 100, 0.6),
      _Circle(0.2, 1.05, 160, 0.15),
      _Circle(0.5, 0.05, 80, 0.45),
    ];

    for (final c in circles) {
      final animVal = (progress + c.delay) % 1.0;
      final opacity = 0.03 + 0.02 * math.sin(animVal * math.pi * 2);
      final scale = 1.0 + 0.1 * math.sin(animVal * math.pi * 2);

      paint.color = Colors.white.withValues(alpha: opacity.clamp(0.0, 0.08));
      canvas.drawCircle(
        Offset(size.width * c.x, size.height * c.y),
        c.radius * scale,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _Circle {
  final double x;
  final double y;
  final double radius;
  final double delay;

  const _Circle(this.x, this.y, this.radius, this.delay);
}
