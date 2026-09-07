import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/app_constants.dart';
import '../pages/all_product_reviews_page.dart';

class ProductReviewsWidget extends StatefulWidget {
  final int productId;
  final double? productRating;
  final int? reviewCount;

  const ProductReviewsWidget({
    super.key,
    required this.productId,
    this.productRating,
    this.reviewCount,
  });

  @override
  State<ProductReviewsWidget> createState() => _ProductReviewsWidgetState();
}

class _ProductReviewsWidgetState extends State<ProductReviewsWidget> {
  bool _isLoading = true;

  double _avgRating = 5.0;
  int _totalReviews = 0;
  Map<int, int> _distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
  List<dynamic> _reviews = [];

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final uri = Uri.parse(
        '${AppConstants.apiBaseUrl}/api/v1/products/${widget.productId}/reviews',
      );
      final res = await http.get(uri, headers: {'Accept': 'application/json'});

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          final stats = data['stats'] ?? {};
          final rawDist = stats['distribution'] ?? {};

          setState(() {
            _avgRating =
                (stats['average_rating'] as num?)?.toDouble() ??
                widget.productRating ??
                5.0;
            _totalReviews =
                (stats['total_reviews'] as num?)?.toInt() ??
                widget.reviewCount ??
                0;
            _distribution = {
              5:
                  (rawDist['5'] as num?)?.toInt() ??
                  (rawDist[5] as num?)?.toInt() ??
                  0,
              4:
                  (rawDist['4'] as num?)?.toInt() ??
                  (rawDist[4] as num?)?.toInt() ??
                  0,
              3:
                  (rawDist['3'] as num?)?.toInt() ??
                  (rawDist[3] as num?)?.toInt() ??
                  0,
              2:
                  (rawDist['2'] as num?)?.toInt() ??
                  (rawDist[2] as num?)?.toInt() ??
                  0,
              1:
                  (rawDist['1'] as num?)?.toInt() ??
                  (rawDist[1] as num?)?.toInt() ??
                  0,
            };

            _reviews = data['data'] ?? [];
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _avgRating = widget.productRating ?? 5.0;
        _totalReviews = widget.reviewCount ?? 0;
        _isLoading = false;
      });
    }
  }

  void _showImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    padding: const EdgeInsets.all(32),
                    color: Colors.white,
                    child: const Icon(
                      Icons.broken_image_rounded,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],

        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Title & Verified Badge ─────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ratings & Reviews',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Real feedback from verified buyers',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (!_isLoading && (_reviews.length > 2 || _totalReviews > 2))
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => AllProductReviewsPage(
                          productId: widget.productId,
                          productRating: _avgRating,
                          reviewCount: _totalReviews,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          'View All',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: Color(0xFF4F46E5),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 14,
                        color: Color(0xFF059669),
                      ),
                      SizedBox(width: 4),
                      Text(
                        '100% Verified',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Overall Score & Star Breakdown Card ───────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                // Circular Rating Gauge / Badge
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF16A34A,
                            ).withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _avgRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 12,
                                color: Color(0xFFFDE047),
                              ),
                              Text(
                                '/5.0',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_totalReviews ${_totalReviews == 1 ? 'Rating' : 'Ratings'}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),

                // 1-5 Star Progress Bars
                Expanded(
                  child: Column(
                    children: [5, 4, 3, 2, 1].map((star) {
                      final count = _distribution[star] ?? 0;
                      final pct = _totalReviews > 0
                          ? (count / _totalReviews)
                          : 0.0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.5),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 14,
                              child: Text(
                                '$star',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.star_rounded,
                              size: 12,
                              color: Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 6,
                                  backgroundColor: const Color(0xFFE2E8F0),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    star >= 4
                                        ? const Color(0xFF16A34A)
                                        : star == 3
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFFEF4444),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 28,
                              child: Text(
                                '${(pct * 100).round()}%',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          // const SizedBox(height: 20),

          // ── Reviews List Section ──────────────────────────────────────────
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
            )
          else if (_reviews.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Text(
                    'No reviews yet for this product',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _reviews.length > 2 ? 2 : _reviews.length,
              separatorBuilder: (_, __) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: Color(0xFFF1F5F9)),
              ),
              itemBuilder: (context, index) {
                final rev = _reviews[index];
                final name = rev['user_name'] as String? ?? 'Verified Buyer';
                final avatarUrl = rev['user_avatar'] as String?;
                final rating = (rev['rating'] as num?)?.toInt() ?? 5;
                final comment = rev['comment'] as String? ?? '';
                final date = rev['date'] as String? ?? '';
                final images = (rev['images'] as List?)?.cast<String>() ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reviewer Header: Avatar, Name, Rating & Date
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFFEEF2FF),
                          backgroundImage:
                              avatarUrl != null && avatarUrl.isNotEmpty
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: avatarUrl == null || avatarUrl.isEmpty
                              ? Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF4F46E5),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    size: 14,
                                    color: Color(0xFF10B981),
                                  ),
                                ],
                              ),
                              if (date.isNotEmpty)
                                Text(
                                  date,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Rating Pill Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: rating >= 4
                                ? const Color(0xFFECFDF5)
                                : rating == 3
                                ? const Color(0xFFFFFBEB)
                                : const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: rating >= 4
                                  ? const Color(0xFFA7F3D0)
                                  : rating == 3
                                  ? const Color(0xFFFDE68A)
                                  : const Color(0xFFFCA5A5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 13,
                                color: rating >= 4
                                    ? const Color(0xFF059669)
                                    : rating == 3
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFFDC2626),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '$rating.0',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: rating >= 4
                                      ? const Color(0xFF047857)
                                      : rating == 3
                                      ? const Color(0xFFB45309)
                                      : const Color(0xFFB91C1C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Review Comment Text
                    if (comment.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        comment,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF334155),
                          height: 1.45,
                        ),
                      ),
                    ],

                    // Review Images Grid (Tap to Preview)
                    if (images.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: images.map((imgUrl) {
                          return GestureDetector(
                            onTap: () => _showImagePreview(context, imgUrl),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Image.network(
                                  imgUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.image_not_supported_rounded,
                                    size: 20,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                );
              },
            ),

          if (!_isLoading && (_reviews.length > 2 || _totalReviews > 2)) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => AllProductReviewsPage(
                        productId: widget.productId,
                        productRating: _avgRating,
                        reviewCount: _totalReviews,
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4F46E5),
                  side: const BorderSide(color: Color(0xFFC7D2FE), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'View All Reviews (${_totalReviews > 0 ? _totalReviews : _reviews.length})',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
