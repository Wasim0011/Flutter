import '../cached_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_constants.dart';
import '../../theme/app_colors.dart';

/// Circle Category Card - Optimized for Style 1 (Circle icons with labels)
/// Horizontal scrolling layout with circle images and text below
class CircleCategoryCard extends StatelessWidget {
  final int categoryId;
  final String name;
  final String? imageUrl;
  final VoidCallback? onTap;

  const CircleCategoryCard({
    super.key,
    required this.categoryId,
    required this.name,
    this.imageUrl,
    this.onTap,
  });

  String _getFullUrl(String url) {
    if (url.startsWith('http')) return url;
    return AppConstants.getFullMediaUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circle Image
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceLight,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: _buildImage(),
              ),
            ),
            const SizedBox(height: 8),
            // Category Name
            SizedBox(
              height: 30, // Uniform text container for up to 2 lines
              child: Align(
                alignment: Alignment.topCenter,
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return SvgPicture.asset('assets/icons/placeholder.svg', fit: BoxFit.cover);
    }

    return CachedImage(
      imageUrl: _getFullUrl(imageUrl!),
      width: 70,
      height: 70,
      fit: BoxFit.cover,
      errorWidget: SvgPicture.asset('assets/icons/placeholder.svg', fit: BoxFit.cover),
    );
  }
}
