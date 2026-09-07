import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_constants.dart';

class AllProductReviewsPage extends StatefulWidget {
  final int productId;
  final double? productRating;
  final int? reviewCount;

  const AllProductReviewsPage({
    super.key,
    required this.productId,
    this.productRating,
    this.reviewCount,
  });

  @override
  State<AllProductReviewsPage> createState() => _AllProductReviewsPageState();
}

class _AllProductReviewsPageState extends State<AllProductReviewsPage> {
  bool _isLoading = true;
  double _avgRating = 5.0;
  int _totalReviews = 0;
  Map<int, int> _distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
  List<dynamic> _reviews = [];
  Map<String, dynamic>? _productData;

  @override
  void initState() {
    super.initState();
    _fetchAllReviews();
  }

  Future<void> _fetchAllReviews() async {
    setState(() => _isLoading = true);
    try {
      final uri = Uri.parse('${AppConstants.apiBaseUrl}/api/v1/products/${widget.productId}/reviews?per_page=50');
      final res = await http.get(uri, headers: {'Accept': 'application/json'});

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          final stats = data['stats'] ?? {};
          final rawDist = stats['distribution'] ?? {};

          setState(() {
            _productData = data['product'] as Map<String, dynamic>?;
            _avgRating = (stats['average_rating'] as num?)?.toDouble() ?? widget.productRating ?? 5.0;
            _totalReviews = (stats['total_reviews'] as num?)?.toInt() ?? widget.reviewCount ?? 0;
            _distribution = {
              5: (rawDist['5'] as num?)?.toInt() ?? (rawDist[5] as num?)?.toInt() ?? 0,
              4: (rawDist['4'] as num?)?.toInt() ?? (rawDist[4] as num?)?.toInt() ?? 0,
              3: (rawDist['3'] as num?)?.toInt() ?? (rawDist[3] as num?)?.toInt() ?? 0,
              2: (rawDist['2'] as num?)?.toInt() ?? (rawDist[2] as num?)?.toInt() ?? 0,
              1: (rawDist['1'] as num?)?.toInt() ?? (rawDist[1] as num?)?.toInt() ?? 0,
            };
            _reviews = data['data'] ?? [];
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
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
                child: Image.network(imageUrl, fit: BoxFit.contain),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Customer Reviews', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_productData != null) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          if (_productData!['image'] != null && _productData!['image'].toString().isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                _productData!['image'],
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.image_not_supported_rounded,
                                  size: 28,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_productData!['brand'] != null &&
                                    _productData!['brand'].toString().isNotEmpty)
                                  Text(
                                    _productData!['brand'].toString().toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF4F46E5),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                Text(
                                  _productData!['name'] ?? 'Product Details',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_productData!['price'] != null) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    '${_productData!['price']}${_productData!['unit'] != null && _productData!['unit'].toString().isNotEmpty ? ' • ${_productData!['unit']}' : ''}',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF16A34A),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Rating Summary Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Score Circle
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 76,
                              height: 76,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _avgRating.toStringAsFixed(1),
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                                  ),
                                  const Text('/5.0', style: TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text('$_totalReviews Reviews', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                          ],
                        ),
                        const SizedBox(width: 16),
                        // 1-5 Star Progress Bars
                        Expanded(
                          child: Column(
                            children: [5, 4, 3, 2, 1].map((star) {
                              final count = _distribution[star] ?? 0;
                              final pct = _totalReviews > 0 ? (count / _totalReviews) : 0.0;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.5),
                                child: Row(
                                  children: [
                                    Text('$star ★', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: pct,
                                          minHeight: 6,
                                          backgroundColor: const Color(0xFFE2E8F0),
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            star >= 4 ? const Color(0xFF16A34A) : (star == 3 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text('${(pct * 100).round()}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Reviews List Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: _reviews.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('No reviews found.', style: TextStyle(color: Colors.grey)),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _reviews.length,
                            separatorBuilder: (_, __) => const Divider(height: 24, color: Color(0xFFF1F5F9)),
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
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: const Color(0xFFEEF2FF),
                                        backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                                        child: avatarUrl == null || avatarUrl.isEmpty
                                            ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF4F46E5)))
                                            : null,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                                            if (date.isNotEmpty) Text(date, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: rating >= 4 ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text('$rating.0 ★', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF047857))),
                                      ),
                                    ],
                                  ),
                                  if (comment.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(comment, style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155), height: 1.45)),
                                  ],
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
                                            child: Image.network(imgUrl, width: 64, height: 64, fit: BoxFit.cover),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
