import '../cached_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_constants.dart';
import '../../theme/app_colors.dart';

/// Banner Category Card - Optimized for Style 3 (Banner with tabs)
/// Full-width banner style for category tabs with products
class BannerCategoryCard extends StatelessWidget {
  final int categoryId;
  final String name;
  final String? imageUrl;
  final bool isSelected;
  final VoidCallback? onTap;

  const BannerCategoryCard({
    super.key,
    required this.categoryId,
    required this.name,
    this.imageUrl,
    this.isSelected = false,
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Category Icon/Image
            if (imageUrl != null && imageUrl!.isNotEmpty)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildImage(),
                ),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: SvgPicture.asset('assets/icons/placeholder.svg', fit: BoxFit.cover),
                ),
              ),
            const SizedBox(width: 12),
            // Category Name
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Arrow Icon
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return CachedImage(
      imageUrl: _getFullUrl(imageUrl!),
      width: 40,
      height: 40,
      fit: BoxFit.cover,
      errorWidget: SvgPicture.asset('assets/icons/placeholder.svg', fit: BoxFit.cover),
    );
  }
}
