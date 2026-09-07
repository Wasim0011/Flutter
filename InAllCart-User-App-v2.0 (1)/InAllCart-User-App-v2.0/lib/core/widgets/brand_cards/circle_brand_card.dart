import '../cached_image.dart';
import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';

/// Circle Brand Card - Optimized for Style 1 (Circle logos)
/// Horizontal scrolling layout with circle brand logos
class CircleBrandCard extends StatelessWidget {
  final int brandId;
  final String name;
  final String? logoUrl;
  final VoidCallback? onTap;

  const CircleBrandCard({
    super.key,
    required this.brandId,
    required this.name,
    this.logoUrl,
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
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
              child: SizedBox(
                width: 70,
                height: 70,
                child: _buildLogo(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
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
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    if (logoUrl == null || logoUrl!.isEmpty) {
      return Center(
        child: Icon(
          Icons.business,
          color: Colors.grey[400],
          size: 28,
        ),
      );
    }

    return CachedImage(
      imageUrl: _getFullUrl(logoUrl!),
      fit: BoxFit.contain,
      errorWidget: Icon(
        Icons.business,
        color: Colors.grey[400],
        size: 28,
      ),
    );
  }
}
