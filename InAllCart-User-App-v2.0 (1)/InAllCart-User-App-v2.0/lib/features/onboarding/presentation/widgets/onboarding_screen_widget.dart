import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../../app_config/domain/entities/app_config.dart';

/// Ultra-Modern Centered Hero Onboarding Screen Widget
class OnboardingScreenWidget extends StatelessWidget {
  final OnboardingScreen screen;

  const OnboardingScreenWidget({
    super.key,
    required this.screen,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final imageHeight = size.height * 0.42;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          // Central Hero Image with Glass Container & Soft Shadow
          Stack(
            alignment: Alignment.center,
            children: [
              // Soft Glow aura behind image
              Container(
                width: size.width * 0.72,
                height: imageHeight * 0.85,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 50,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),

              // Image Frame
              Container(
                height: imageHeight,
                width: size.width * 0.85,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: _buildImage(),
                ),
              ),
            ],
          ),

          const Spacer(flex: 2),

          // Title
          Text(
            screen.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
          ),
          const SizedBox(height: 14),

          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              screen.subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
            ),
          ),

          const Spacer(flex: 3),
        ],
      ),
    );
  }

  Widget _buildImage() {
    final imageUrl = screen.imageUrl;

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
      final fullUrl = 'https://demo2.inallcart.com/storage/${imageUrl.startsWith('/') ? imageUrl.substring(1) : imageUrl}';
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 72,
              color: AppColors.primary,
            ),
            SizedBox(height: 12),
            Text(
              'InAllCart',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
