import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../domain/entities/order.dart';
import '../../data/models/order_model.dart';

// ── Emoji data per star ──────────────────────────────────────────────────────
const _emojiData = [
  _EmojiData(face: '😞', label: 'Poor',      color: Color(0xFFEF5350)),
  _EmojiData(face: '😕', label: 'Fair',      color: Color(0xFFFF7043)),
  _EmojiData(face: '🙂', label: 'Good',      color: Color(0xFFFFA726)),
  _EmojiData(face: '😊', label: 'Very Good', color: Color(0xFF66BB6A)),
  _EmojiData(face: '🤩', label: 'Excellent', color: Color(0xFF42A5F5)),
];

class _EmojiData {
  final String face;
  final String label;
  final Color color;
  const _EmojiData({required this.face, required this.label, required this.color});
}

const _quickTags = {
  1: ['Wrong item', 'Damaged', 'Stale'],
  2: ['Late delivery', 'Poor packing', 'Missing item'],
  3: ['Average quality', 'Okay packing', 'Acceptable'],
  4: ['Fresh', 'Good taste', 'Well packed'],
  5: ['Fresh', 'Good taste', 'Well packed', 'Excellent quality'],
};

// ── Page ─────────────────────────────────────────────────────────────────────

// ── Page ─────────────────────────────────────────────────────────────────────

class OrderReviewPage extends StatefulWidget {
  final Order? order;
  final int? orderId;
  const OrderReviewPage({super.key, this.order, this.orderId});

  @override
  State<OrderReviewPage> createState() => _OrderReviewPageState();
}

class _OrderReviewPageState extends State<OrderReviewPage> {
  Order? _currentOrder;
  int _deliveryRating = 0;

  Map<int, int> _ratings = {};
  Map<int, TextEditingController> _comments = {};
  Map<int, Set<String>> _selectedTags = {};
  Map<int, List<XFile>> _images = {}; // productId → picked files
  Set<int> _alreadyReviewed = {};

  bool _loading = true;
  bool _submitting = false;
  bool _submitted = false;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.order != null) {
      _currentOrder = widget.order;
      _initOrderState();
      _loadReviewed();
    } else if (widget.orderId != null) {
      _fetchOrderAndInit(widget.orderId!);
    } else {
      _loading = false;
    }
  }

  void _initOrderState() {
    final order = _currentOrder;
    if (order == null) return;
    _ratings      = {for (final i in order.items) i.productId: 0};
    _comments     = {for (final i in order.items) i.productId: TextEditingController()};
    _selectedTags = {for (final i in order.items) i.productId: {}};
    _images       = {for (final i in order.items) i.productId: []};
  }

  Future<void> _fetchOrderAndInit(int orderId) async {
    setState(() => _loading = true);
    try {
      final token = await getIt<StorageService>().getTokenAsync();
      final res = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/api/v1/orders/$orderId'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );
      if (res.statusCode == 200) {
        final data = _jsonDecode(res.body);
        if (data['data'] != null) {
          _currentOrder = OrderModel.fromJson(data['data']);
          _initOrderState();
        }
      }
    } catch (_) {}
    await _loadReviewed();
  }

  @override
  void dispose() {
    for (final c in _comments.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadReviewed() async {
    final order = _currentOrder;
    if (order == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    setState(() => _loading = true);
    try {
      final token = await getIt<StorageService>().getTokenAsync();
      final res = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/api/v1/orders/${order.id}/reviews'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );
      if (res.statusCode == 200) {
        final data = _jsonDecode(res.body);
        final ids = ((data['reviewed_product_ids'] ?? []) as List).map((e) => e as int).toSet();
        if (mounted) setState(() => _alreadyReviewed = ids);
      }
    } catch (e) {
      // Non-critical
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickImages(int productId) async {
    final picked = await _picker.pickMultiImage(imageQuality: 80, limit: 5);
    if (picked.isNotEmpty && mounted) {
      setState(() {
        final existing = _images[productId] ?? [];
        final combined = [...existing, ...picked];
        _images[productId] = combined.take(5).toList();
      });
    }
  }

  void _removeImage(int productId, int index) {
    setState(() => _images[productId]?.removeAt(index));
  }

  Future<void> _submit() async {
    final order = _currentOrder;
    if (order == null) return;

    final toSubmit = order.items
        .where((i) => !_alreadyReviewed.contains(i.productId) && (_ratings[i.productId] ?? 0) > 0)
        .toList();

    if (toSubmit.isEmpty && _deliveryRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating to submit your review.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final token = await getIt<StorageService>().getTokenAsync();
      final uri = Uri.parse('${AppConstants.apiBaseUrl}/api/v1/orders/${order.id}/reviews');
      final req = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..headers['Accept'] = 'application/json';

      if (_deliveryRating > 0) {
        req.fields['delivery_rating'] = _deliveryRating.toString();
      }

      for (var idx = 0; idx < toSubmit.length; idx++) {
        final item = toSubmit[idx];
        final pid = item.productId;
        final tags = _selectedTags[pid] ?? {};
        final comment = _comments[pid]?.text.trim() ?? '';
        final combined = [...tags, if (comment.isNotEmpty) comment].join('. ');

        req.fields['reviews[$idx][product_id]'] = pid.toString();
        req.fields['reviews[$idx][rating]']     = (_ratings[pid] ?? 0).toString();
        if (combined.isNotEmpty) req.fields['reviews[$idx][comment]'] = combined;

        // Attach images for this product
        final files = _images[pid] ?? [];
        for (var fi = 0; fi < files.length; fi++) {
          req.files.add(await http.MultipartFile.fromPath(
            'images[$pid][$fi]',
            files[fi].path,
          ));
        }
      }

      final streamed = await req.send();
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (mounted) setState(() => _submitted = true);
      } else {
        final data = _jsonDecode(res.body);
        final msg = data['message'] ?? 'Failed to submit review. Please try again.';
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit review: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Map<String, dynamic> _jsonDecode(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'How was your order?',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _submitted
              ? _buildSuccessState()
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final items = _currentOrder?.items ?? [];
    final reviewable = items.where((i) => !_alreadyReviewed.contains(i.productId)).toList();
    final done       = items.where((i) =>  _alreadyReviewed.contains(i.productId)).toList();

    if (_currentOrder == null) {
      return const Center(child: Text('Order details unavailable'));
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            children: [
              _buildDeliveryCard(),
              const SizedBox(height: 20),
              if (reviewable.isNotEmpty) ...[
                const Text(
                  'Tell us more about the products',
                  style: TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                ...reviewable.map((item) => _ProductReviewCard(
                  item: item,
                  rating: _ratings[item.productId] ?? 0,
                  comment: _comments[item.productId] ?? TextEditingController(),
                  selectedTags: _selectedTags[item.productId] ?? {},
                  images: _images[item.productId] ?? [],
                  onRatingChanged: (r) => setState(() => _ratings[item.productId] = r),
                  onTagToggled: (tag) => setState(() {
                    final s = _selectedTags[item.productId] ??= {};
                    s.contains(tag) ? s.remove(tag) : s.add(tag);
                  }),
                  onPickImages: () => _pickImages(item.productId),
                  onRemoveImage: (i) => _removeImage(item.productId, i),
                )),
              ],
              if (done.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Already reviewed', style: TextStyle(fontSize: 12, color: Colors.black38, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...done.map((item) => _ProductReviewCard(
                  item: item,
                  rating: 0,
                  comment: TextEditingController(),
                  selectedTags: const {},
                  images: const [],
                  onRatingChanged: (_) {},
                  onTagToggled: (_) {},
                  onPickImages: () {},
                  onRemoveImage: (_) {},
                  reviewed: true,
                )),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
        _buildSubmitBar(),
      ],
    );
  }

  Widget _buildDeliveryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: const BoxDecoration(color: Color(0xFFFFF3E0), shape: BoxShape.circle),
            child: const Center(child: Text('🛵', style: TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rate delivery experience',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
                const SizedBox(height: 8),
                _StarRow(
                  rating: _deliveryRating,
                  size: 28,
                  onChanged: (r) {
                    HapticFeedback.lightImpact();
                    setState(() => _deliveryRating = r);
                  },
                ),
              ],
            ),
          ),
          if (_deliveryRating > 0) ...[
            const SizedBox(width: 8),
            _RatingEmoji(rating: _deliveryRating, compact: true),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _submitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Submit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 20),
            const Text('Thank you!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.black87)),
            const SizedBox(height: 8),
            const Text(
              'Your review helps others make better choices.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Done', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Star row ─────────────────────────────────────────────────────────────────

class _StarRow extends StatelessWidget {
  final int rating;
  final double size;
  final ValueChanged<int> onChanged;
  const _StarRow({required this.rating, required this.size, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final star = i + 1;
        final filled = star <= rating;
        return GestureDetector(
          onTap: () => onChanged(star),
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: Icon(
                filled ? Icons.star_rounded : Icons.star_outline_rounded,
                key: ValueKey('$star-$filled'),
                size: size,
                color: filled ? const Color(0xFFFFC107) : const Color(0xFFDDDDDD),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── Animated emoji ────────────────────────────────────────────────────────────

class _RatingEmoji extends StatelessWidget {
  final int rating;
  final bool compact;
  const _RatingEmoji({required this.rating, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (rating == 0) return const SizedBox.shrink();
    final data = _emojiData[rating - 1];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: compact
          ? Text(data.face, key: ValueKey(rating), style: const TextStyle(fontSize: 28))
          : Column(
              key: ValueKey(rating),
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(data.face, style: const TextStyle(fontSize: 36)),
                const SizedBox(height: 4),
                Text(data.label,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: data.color)),
              ],
            ),
    );
  }
}

// ── Product review card ───────────────────────────────────────────────────────

class _ProductReviewCard extends StatelessWidget {
  final OrderItem item;
  final int rating;
  final TextEditingController comment;
  final Set<String> selectedTags;
  final List<XFile> images;
  final ValueChanged<int> onRatingChanged;
  final ValueChanged<String> onTagToggled;
  final VoidCallback onPickImages;
  final ValueChanged<int> onRemoveImage;
  final bool reviewed;

  const _ProductReviewCard({
    required this.item,
    required this.rating,
    required this.comment,
    required this.selectedTags,
    required this.images,
    required this.onRatingChanged,
    required this.onTagToggled,
    required this.onPickImages,
    required this.onRemoveImage,
    this.reviewed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 48, height: 48,
                    child: item.productImage != null
                        ? CachedImage(imageUrl: AppConstants.getFullMediaUrl(item.productImage!), fit: BoxFit.cover)
                        : Container(color: const Color(0xFFF2F3F5), child: const Icon(Icons.image_outlined, color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(item.productName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                if (reviewed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Reviewed', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  )
                else
                  _StarRow(rating: rating, size: 26, onChanged: (r) {
                    HapticFeedback.lightImpact();
                    onRatingChanged(r);
                  }),
              ],
            ),
          ),

          // Expanded section
          if (!reviewed && rating > 0)
            _ExpandedSection(
              rating: rating,
              comment: comment,
              selectedTags: selectedTags,
              images: images,
              onTagToggled: onTagToggled,
              onPickImages: onPickImages,
              onRemoveImage: onRemoveImage,
            ),
        ],
      ),
    );
  }
}

// ── Expanded section ──────────────────────────────────────────────────────────

class _ExpandedSection extends StatelessWidget {
  final int rating;
  final TextEditingController comment;
  final Set<String> selectedTags;
  final List<XFile> images;
  final ValueChanged<String> onTagToggled;
  final VoidCallback onPickImages;
  final ValueChanged<int> onRemoveImage;

  const _ExpandedSection({
    required this.rating,
    required this.comment,
    required this.selectedTags,
    required this.images,
    required this.onTagToggled,
    required this.onPickImages,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    final tags = _quickTags[rating] ?? [];

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(height: 1, color: Colors.grey.shade100),

          // Emoji
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(child: _RatingEmoji(rating: rating)),
          ),

          // Text field
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: TextField(
              controller: comment,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Write your reviews here...',
                hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
                filled: true,
                fillColor: const Color(0xFFF7F8FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                ),
                contentPadding: const EdgeInsets.all(12),
                counterStyle: const TextStyle(fontSize: 11, color: Colors.black38),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),

          // Quick tags
          if (tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Wrap(
                spacing: 8, runSpacing: 8,
                children: tags.map((tag) {
                  final selected = selectedTags.contains(tag);
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onTagToggled(tag);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? AppColors.primary : Colors.grey.shade300,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(tag,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            color: selected ? AppColors.primary : Colors.black87,
                          )),
                    ),
                  );
                }).toList(),
              ),
            ),

          // Image thumbnails
          if (images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(images[i].path),
                          width: 72, height: 72,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 2, right: 2,
                        child: GestureDetector(
                          onTap: () => onRemoveImage(i),
                          child: Container(
                            width: 20, height: 20,
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.close, size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Add Photos button
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
            child: GestureDetector(
              onTap: images.length >= 5 ? null : onPickImages,
              child: AnimatedOpacity(
                opacity: images.length >= 5 ? 0.4 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 20, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        images.isEmpty ? 'Add Photos' : 'Add More (${images.length}/5)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
