import '../../../../core/widgets/cached_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/product_cards/grid_product_card.dart';
import '../../../app_config/presentation/bloc/app_config_bloc.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/widgets/floating_cart_summary.dart';
import '../../../wishlist/presentation/bloc/wishlist_bloc.dart';
import '../../domain/entities/product.dart';
import '../bloc/product_bloc.dart';
import '../widgets/product_reviews_widget.dart';
import '../../../../core/widgets/inallcart_loader.dart';
import '../../../../core/widgets/replace_cart_bottom_sheet.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';

class ProductDetailsPage extends StatelessWidget {
  final String productId;
  final Product? initialProduct;

  const ProductDetailsPage({
    super.key,
    required this.productId,
    this.initialProduct,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<ProductBloc>()..add(LoadProductDetails(int.parse(productId))),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: BlocBuilder<ProductBloc, ProductState>(
          builder: (context, state) {
            if (state is ProductLoading) {
              if (initialProduct != null) {
                return Stack(
                  children: [
                    _ProductDetailsContent(
                      product: initialProduct!,
                      showSkeleton: true,
                    ),
                    const Align(
                      alignment: Alignment.topCenter,
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  ],
                );
              }
              return const Center(child: InAllCartLoader());
            }
            if (state is ProductError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<ProductBloc>().add(
                        LoadProductDetails(int.parse(productId)),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            if (state is ProductDetailsLoaded) {
              return _ProductDetailsContent(
                key: ValueKey('${state.product.id}_${state.product.variants.length}'),
                product: state.product,
              );
            }
            if (initialProduct != null) {
              return _ProductDetailsContent(
                product: initialProduct!,
                showSkeleton: true,
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _ProductDetailsContent extends StatefulWidget {
  final Product product;
  final bool showSkeleton;
  const _ProductDetailsContent({
    super.key,
    required this.product,
    this.showSkeleton = false,
  });

  @override
  State<_ProductDetailsContent> createState() => _ProductDetailsContentState();
}

class _ProductDetailsContentState extends State<_ProductDetailsContent> {
  final PageController _pageController = PageController();
  ProductVariant? _selectedVariant;
  final Map<String, String> _selectedAttributes = {};
  bool _isAddingToCart = false;

  @override
  void initState() {
    super.initState();
    _initSelectedVariant();
    if (widget.product.category != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<ProductBloc>().add(
            LoadSimilarProducts(
              categoryId: widget.product.category!.id,
              excludeProductId: widget.product.id,
            ),
          );
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant _ProductDetailsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product != widget.product ||
        _selectedVariant == null ||
        oldWidget.product.variants.length != widget.product.variants.length) {
      _initSelectedVariant();
    }
  }

  void _initSelectedVariant() {
    if (widget.product.variants.isNotEmpty) {
      final target = widget.product.variants.where((v) => v.isDefault).firstOrNull ??
          widget.product.variants.first;
      _selectedVariant = target;
      _syncSelectedAttributesFromVariant(target);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  void _syncSelectedAttributesFromVariant(ProductVariant v) {
    _selectedAttributes.clear();
    final name = v.displayName;
    if (name.contains(':')) {
      final parts = name.split(':');
      _selectedAttributes[parts[0].trim()] = parts[1].trim();
    } else if (v.sku != null && v.sku!.contains('-')) {
      final parts = v.sku!.split('-');
      if (parts.length > 2) {
        for (final attr in parts.sublist(2)) {
          final upper = attr.toUpperCase();
          if (upper.endsWith('GB') || upper.endsWith('TB')) {
            _selectedAttributes['RAM / Storage'] = attr;
          } else if (['RED', 'BLUE', 'BLACK', 'WHITE', 'YELLOW', 'GREEN', 'GOLD', 'SILVER', 'PURPLE'].contains(upper)) {
            _selectedAttributes['Color'] = attr;
          } else if (['S', 'M', 'L', 'XL', 'XXL', 'SMALL', 'MEDIUM', 'LARGE'].contains(upper)) {
            _selectedAttributes['Size'] = attr;
          } else {
            _selectedAttributes['Option'] = attr;
          }
        }
      }
    }
  }

  String _getVariantSectionTitle() {
    if (widget.product.variants.isNotEmpty) {
      final v = widget.product.variants.first;
      if (v.unitName != null && v.unitName!.isNotEmpty) {
        return 'Select ${v.unitName!}';
      }
    }
    return 'Select Option';
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.product.images.isNotEmpty
        ? widget.product.images
        : (widget.product.primaryImage != null
              ? [widget.product.primaryImage!]
              : <ProductImage>[]);

    return BlocListener<CartBloc, CartState>(
      listenWhen: (p, c) =>
          p is CartUpdating &&
          (c is CartLoaded || c is CartError || c is CartNoInternet),
      listener: (context, state) {
        if (!_isAddingToCart) return;
        _isAddingToCart = false;
        if (state is CartError) {
          if (state.message.contains('different stores') ||
              state.message.contains('clear your cart')) {
            _showReplaceCartDialog(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Image Gallery (1:1 Perfect Square Hero Ratio) ─────────────────
                SliverAppBar(
                  expandedHeight: MediaQuery.of(context).size.width,
                  elevation: 0,
                  pinned: true,
                  stretch: true,
                  automaticallyImplyLeading: false,
                  backgroundColor: Colors.white,
                  flexibleSpace: FlexibleSpaceBar(
                    stretchModes: const [StretchMode.zoomBackground],
                    background: Stack(
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          itemCount: images.length,
                          itemBuilder: (context, index) => GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => FullscreenImageGallery(
                                  images: images,
                                  initialIndex: index,
                                ),
                              ),
                            ),
                            child: Container(
                              color: Colors.white,
                              padding: EdgeInsets.fromLTRB(
                                0,
                                MediaQuery.of(context).padding.top + 36,
                                0,
                                8,
                              ),
                              child: Center(
                                child: CachedImage(
                                  imageUrl: AppConstants.getFullMediaUrl(images[index].url),
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorWidget: Container(
                                    color: Colors.white,
                                    child: const Icon(
                                      Icons.broken_image,
                                      size: 80,
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (images.length > 1)
                          Positioned(
                            bottom: 4,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: SmoothPageIndicator(
                                controller: _pageController,
                                count: images.length,
                                effect: const ExpandingDotsEffect(
                                  dotWidth: 6,
                                  dotHeight: 6,
                                  expansionFactor: 3,
                                  activeDotColor: AppColors.primary,
                                  dotColor: Color(0xFFE0E0E0),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // ── Product Info ───────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badges: Delivery, Rating & Review (Blinkit / Zepto Style with Admin Settings)
                        BlocBuilder<AppConfigBloc, AppConfigState>(
                          builder: (context, configState) {
                            final bool showRating = configState is AppConfigLoaded
                                ? (configState.config.showStarRating == true)
                                : true;
                            final bool showReview = configState is AppConfigLoaded
                                ? (configState.config.showReviewCount == true)
                                : true;
                            final double rating = widget.product.rating ?? 4.5;
                            final int reviewCount = widget.product.reviewCount ?? 0;

                            return Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                if (widget.product.deliveryTime != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0FDF4),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFDCFCE7)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.bolt, size: 14, color: Color(0xFF16A34A)),
                                        const SizedBox(width: 3),
                                        Text(
                                          '${widget.product.deliveryTime} delivery',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF16A34A),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                // Blinkit/Zepto Rating & Review Pill Badge
                                if (showRating)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFE5E7EB)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.star_rounded, color: Color(0xFF16A34A), size: 14),
                                        const SizedBox(width: 3),
                                        Text(
                                          rating.toStringAsFixed(1),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF111827),
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        if (showReview && reviewCount > 0) ...[
                                          const SizedBox(width: 3),
                                          Text(
                                            '($reviewCount)',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF6B7280),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                // Veg / Non-Veg Badge Indicator
                                if (widget.product.healthInfo?.isVeg != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: widget.product.healthInfo!.isVeg!
                                          ? const Color(0xFFF0FDF4)
                                          : const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: widget.product.healthInfo!.isVeg!
                                            ? const Color(0xFF86EFAC)
                                            : const Color(0xFFFCA5A5),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 13,
                                          height: 13,
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: widget.product.healthInfo!.isVeg!
                                                  ? const Color(0xFF16A34A)
                                                  : const Color(0xFFDC2626),
                                              width: 1.4,
                                            ),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: widget.product.healthInfo!.isVeg!
                                                  ? const Color(0xFF16A34A)
                                                  : const Color(0xFFDC2626),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          widget.product.healthInfo!.isVeg! ? 'Veg' : 'Non-Veg',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: widget.product.healthInfo!.isVeg!
                                                ? const Color(0xFF15803D)
                                                : const Color(0xFFB91C1C),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                // Health & Specialty Badges
                                if (widget.product.healthInfo?.isHalal == true)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFA7F3D0)),
                                    ),
                                    child: const Text(
                                      'Halal Certified',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF047857),
                                      ),
                                    ),
                                  ),

                                if (widget.product.healthInfo?.isPrescriptionRequired == true)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFFCA5A5)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.medical_services_outlined, size: 12, color: Color(0xFFDC2626)),
                                        SizedBox(width: 3),
                                        Text(
                                          'Rx Required',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFFDC2626),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 10),

                        // Product name — compact
                        Text(
                          widget.product.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                        ),
                        if (widget.product.healthInfo?.genericName != null &&
                            widget.product.healthInfo!.genericName!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              widget.product.healthInfo!.genericName!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        const SizedBox(height: 4),

                        // Unit / variant display
                        Text(
                          _getDisplayUnit(),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Price row
                        _buildPriceRow(),
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: Color(0xFFF0F0F0)),
                      ],
                    ),
                  ),
                ),

                // ── Variant Selector ───────────────────────────────────
                if (widget.product.hasVariants)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildVariantSelector(),
                          const SizedBox(height: 8),
                          const Divider(height: 1, color: Color(0xFFF0F0F0)),
                        ],
                      ),
                    ),
                  ),

                // ── Product Video Preview Card ───────────────────────────
                if (widget.product.video?.url != null && widget.product.video!.url!.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF2563EB),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Product Video Presentation',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                                ),
                                Text(
                                  'Watch live video demo of this item',
                                  style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              final uri = Uri.parse(widget.product.video!.url!);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Watch',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── Store Banner Card ───────────────────────────────────
                SliverToBoxAdapter(child: _buildStoreCard(context)),

                // ── About Product ──────────────────────────────────────
                SliverToBoxAdapter(child: _buildDescription()),

                // ── Similar Products ───────────────────────────────────
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                        child: Text(
                          'Similar Products',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      _buildSimilarProducts(),
                    ],
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),

            // Top nav overlay
            _buildTopNav(context),

            // Sticky bottom bar
            Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomBar()),

            // Floating cart pill — sits above the sticky bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 80,
              child: const FloatingCartSummary(),
            ),

            // Floating cart pill
            Positioned(
              left: 0,
              right: 0,
              bottom: 80,
              child: const FloatingCartSummary(),
            ),
          ],
        ),
      ),
    );
  }

  bool get _hasPolicyHighlights {
    final p = widget.product.policy;
    if (p == null) return false;
    final hasReturn = p.returnPeriodDays > 0;
    final hasReplacement = p.replacementPeriodDays > 0;
    final hasWarranty = p.warrantySummary != null && p.warrantySummary!.trim().isNotEmpty;
    final hasGuarantee = p.guaranteeSummary != null && p.guaranteeSummary!.trim().isNotEmpty;
    return hasReturn || hasReplacement || hasWarranty || hasGuarantee;
  }

  String _getDisplayUnit() {
    if (widget.product.hasVariants && _selectedVariant != null) {
      return _selectedVariant!.displayName;
    }
    return widget.product.unit ?? '';
  }

  Widget _buildTopNav(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          bottom: 8,
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            _navBtn(Icons.keyboard_arrow_down_rounded, () => context.pop()),
            const Spacer(),
            _navBtn(Icons.share_outlined, () {
              final url =
                  '${AppConstants.websiteUrl}/product/${widget.product.id}';
              final appName =
                  getIt<AppConfigBloc>().currentConfig?.appName ??
                  AppConstants.appName;
              SharePlus.instance.share(
                ShareParams(text: 'Check out ${widget.product.name} on $appName\n$url'),
              );
            }),
            const SizedBox(width: 8),
            BlocBuilder<WishlistBloc, WishlistState>(
              builder: (context, state) {
                final inWishlist = state.productIds.contains(widget.product.id);
                return _navBtn(
                  inWishlist ? Icons.favorite : Icons.favorite_border,
                  () {
                    HapticFeedback.lightImpact();
                    context.read<WishlistBloc>().add(
                      ToggleWishlistProduct(widget.product.id),
                    );
                  },
                  color: inWishlist ? Colors.red : AppColors.textPrimary,
                );
              },
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Widget _navBtn(
    IconData icon,
    VoidCallback onTap, {
    Color color = AppColors.textPrimary,
  }) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Icon(icon, size: 17, color: color),
        ),
      ),
    );
  }

  Widget _buildPriceRow() {
    return BlocBuilder<AppConfigBloc, AppConfigState>(
      builder: (context, state) {
        final config = state is AppConfigLoaded ? state.config : null;
        final variant = _selectedVariant;
        final price = widget.product.hasVariants && variant != null
            ? variant.sellingPrice
            : widget.product.price.amount;
        final mrp = widget.product.hasVariants && variant != null
            ? variant.mrp
            : widget.product.price.comparePrice;
        final discount = widget.product.hasVariants && variant != null
            ? variant.discountPercent
            : widget.product.price.discountPercent;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              CurrencyFormatter.formatAmount(price, config?.currencyConfig),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            if (mrp != null && mrp > price) ...[
              const SizedBox(width: 8),
              Text(
                'MRP ${CurrencyFormatter.formatAmount(mrp, config?.currencyConfig)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF999999),
                  decoration: TextDecoration.lineThrough,
                  decorationColor: Color(0xFF999999),
                ),
              ),
            ],
            if (discount != null && discount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${discount.toInt()}% off',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Color _parseColorFromName(String name) {
    final lower = name.trim().toLowerCase();
    switch (lower) {
      case 'red':
        return const Color(0xFFE53935);
      case 'blue':
        return const Color(0xFF1E88E5);
      case 'black':
        return const Color(0xFF212121);
      case 'white':
        return const Color(0xFFFFFFFF);
      case 'yellow':
        return const Color(0xFFFFD600);
      case 'green':
        return const Color(0xFF43A047);
      case 'gold':
        return const Color(0xFFFFD700);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'purple':
        return const Color(0xFF8E24AA);
      case 'pink':
        return const Color(0xFFEC407A);
      case 'orange':
        return const Color(0xFFFB8C00);
      case 'grey':
      case 'gray':
        return const Color(0xFF757575);
      case 'brown':
        return const Color(0xFF6D4C41);
      default:
        return AppColors.primary;
    }
  }

  Widget _buildVariantSelector() {
    final variants = widget.product.variants;
    if (variants.isEmpty) return const SizedBox.shrink();

    // Check if variants have multi-attribute SKU patterns or colon titles
    final Map<String, Set<String>> attributeGroups = {};

    for (final v in variants) {
      final name = v.displayName;
      if (name.contains(':')) {
        final parts = name.split(':');
        final key = parts[0].trim();
        final val = parts[1].trim();
        attributeGroups.putIfAbsent(key, () => {}).add(val);
      } else if (v.sku != null && v.sku!.contains('-')) {
        final parts = v.sku!.split('-');
        if (parts.length > 2) {
          final attrParts = parts.sublist(2);
          for (final attr in attrParts) {
            final upper = attr.toUpperCase();
            if (upper.endsWith('GB') || upper.endsWith('TB')) {
              attributeGroups.putIfAbsent('RAM / Storage', () => {}).add(attr);
            } else if (['RED', 'BLUE', 'BLACK', 'WHITE', 'YELLOW', 'GREEN', 'GOLD', 'SILVER', 'PURPLE'].contains(upper)) {
              attributeGroups.putIfAbsent('Color', () => {}).add(attr);
            } else if (['S', 'M', 'L', 'XL', 'XXL', 'SMALL', 'MEDIUM', 'LARGE'].contains(upper)) {
              attributeGroups.putIfAbsent('Size', () => {}).add(attr);
            } else {
              attributeGroups.putIfAbsent('Option', () => {}).add(attr);
            }
          }
        }
      }
    }

    if (attributeGroups.isEmpty || attributeGroups.values.every((v) => v.length <= 1)) {
      // Single group fallback
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getVariantSectionTitle(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 54,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: variants.length,
              itemBuilder: (context, index) {
                final variant = variants[index];
                final isSelected = _selectedVariant?.id == variant.id;
                final config = (context.read<AppConfigBloc>().state as AppConfigLoaded?)?.config;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedVariant = variant);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : const Color(0xFFDDE1E7),
                        width: isSelected ? 1.8 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          variant.displayName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatAmount(variant.sellingPrice, config?.currencyConfig),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white70 : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    // Multi-group grouped layout (RAM, Size, Color, Option)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: attributeGroups.entries.map((entry) {
        final groupTitle = entry.key;
        final options = entry.value.toList();
        final isColorGroup = groupTitle.toLowerCase().contains('color');

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                groupTitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: options.map((optValue) {
                    final currentSelected = _selectedAttributes[groupTitle];
                    final isSelected = currentSelected != null
                        ? currentSelected.toUpperCase() == optValue.toUpperCase()
                        : (_selectedVariant?.name ?? _selectedVariant?.sku ?? '').toUpperCase().contains(optValue.toUpperCase());

                    if (isColorGroup) {
                      final colorVal = _parseColorFromName(optValue);
                      final isWhite = optValue.toLowerCase() == 'white';
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedAttributes[groupTitle] = optValue;

                            final match = variants.where((v) {
                              final vText = '${v.displayName} ${v.name ?? ''} ${v.sku ?? ''}'.toUpperCase();
                              return _selectedAttributes.values.every((val) => vText.contains(val.toUpperCase()));
                            }).firstOrNull ??
                            variants.where((v) {
                              final vText = '${v.displayName} ${v.name ?? ''} ${v.sku ?? ''}'.toUpperCase();
                              return vText.contains(optValue.toUpperCase());
                            }).firstOrNull ??
                            variants.first;

                            _selectedVariant = match;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(right: 14),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: colorVal,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isWhite ? const Color(0xFFCCCCCC) : Colors.transparent),
                              width: isSelected ? 3.0 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.35)
                                    : Colors.black.withValues(alpha: 0.1),
                                blurRadius: isSelected ? 6 : 3,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  size: 18,
                                  color: isWhite || colorVal == const Color(0xFFFFD600)
                                      ? Colors.black
                                      : Colors.white,
                                )
                              : null,
                        ),
                      );
                    }

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedAttributes[groupTitle] = optValue;

                          final match = variants.where((v) {
                            final vText = '${v.displayName} ${v.name ?? ''} ${v.sku ?? ''}'.toUpperCase();
                            return _selectedAttributes.values.every((val) => vText.contains(val.toUpperCase()));
                          }).firstOrNull ??
                          variants.where((v) {
                            final vText = '${v.displayName} ${v.name ?? ''} ${v.sku ?? ''}'.toUpperCase();
                            return vText.contains(optValue.toUpperCase());
                          }).firstOrNull ??
                          variants.first;

                          _selectedVariant = match;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : const Color(0xFFDDE1E7),
                            width: isSelected ? 1.8 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : [],
                        ),
                        child: Text(
                          optValue,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStoreCard(BuildContext context) {
    final store = widget.product.store;
    if (store == null || store.name.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            context.push(Routes.store(store.id.toString()));
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Store logo container
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: store.logo != null && store.logo!.isNotEmpty
                        ? CachedImage(imageUrl: store.logo!, fit: BoxFit.cover)
                        : const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 24),
                  ),
                ),
                const SizedBox(width: 12),

                // Store name & subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        store.name,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Explore all products',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),

                // Right chevron arrow icon
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF64748B),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDescription() {
    final hasShort = widget.product.description.short?.isNotEmpty == true;
    final hasFull = widget.product.description.full?.isNotEmpty == true;
    if (!hasShort && !hasFull) {
      if (!widget.showSkeleton) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Shimmer.fromColors(
          baseColor: const Color(0xFFEDEDED),
          highlightColor: const Color(0xFFF7F7F7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 14,
                width: 160,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 12,
                width: 260,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About this product',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (hasShort)
            Text(
              widget.product.description.short!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          if (hasFull) ...[
            const SizedBox(height: 8),
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text(
                  'View description details',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                childrenPadding: const EdgeInsets.only(bottom: 12),
                expandedAlignment: Alignment.topLeft,
                children: [
                  Text(
                    widget.product.description.full!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Services & Policy Highlights (rendered BEFORE Product Specifications if not empty)
          if (_hasPolicyHighlights) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 16, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        'Services & Policy Highlights',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (widget.product.policy!.returnPeriodDays > 0)
                        _policyChip('${widget.product.policy!.returnPeriodDays} Days Returnable', Icons.assignment_return_outlined),
                      if (widget.product.policy!.replacementPeriodDays > 0)
                        _policyChip('${widget.product.policy!.replacementPeriodDays} Days Replacement', Icons.published_with_changes_rounded),
                      if (widget.product.policy!.warrantySummary != null && widget.product.policy!.warrantySummary!.trim().isNotEmpty)
                        _policyChip(widget.product.policy!.warrantySummary!, Icons.verified_user_outlined),
                      if (widget.product.policy!.guaranteeSummary != null && widget.product.policy!.guaranteeSummary!.trim().isNotEmpty)
                        _policyChip(widget.product.policy!.guaranteeSummary!, Icons.thumb_up_alt_outlined),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),
          const Text(
            'Product Specifications',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                if (widget.product.brand != null && widget.product.brand!.isNotEmpty)
                  _specRow('Brand', widget.product.brand!),
                if (widget.product.category?.name != null)
                  _specRow('Category', widget.product.category!.name),
                if (widget.product.unit != null && widget.product.unit!.isNotEmpty)
                  _specRow('Unit / Quantity', widget.product.unit!),
                if (widget.product.weight != null && widget.product.weight! > 0)
                  _specRow('Weight', '${widget.product.weight} ${widget.product.weightUnit ?? "g"}'),
                if (widget.product.hsnCode != null && widget.product.hsnCode!.isNotEmpty)
                  _specRow('HSN Code', widget.product.hsnCode!),
                if (widget.product.taxRate != null && widget.product.taxRate! > 0)
                  _specRow('Tax Rate', '${widget.product.taxRate}% ${widget.product.taxClass ?? ""}'),
                if (widget.product.dates?.manufactureDate != null)
                  _specRow('Mfg Date', widget.product.dates!.manufactureDate!.toIso8601String().split('T').first),
                if (widget.product.dates?.expiryDate != null)
                  _specRow('Expiry Date', widget.product.dates!.expiryDate!.toIso8601String().split('T').first),
                if (widget.product.dates?.shelfLifeDays != null)
                  _specRow('Shelf Life', '${widget.product.dates!.shelfLifeDays} Days'),
                if (widget.product.store?.name != null)
                  _specRow('Sold By', widget.product.store!.name),
              ],
            ),
          ),

          // Nutritional Info Box
          if (widget.product.healthInfo?.nutritionInfo != null &&
              widget.product.healthInfo!.nutritionInfo!.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Nutritional / Health Information',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Text(
                widget.product.healthInfo!.nutritionInfo!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF92400E),
                  height: 1.4,
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),

          // ── Premium Customer Reviews Widget ─────────────────────────────
          ProductReviewsWidget(
            productId: widget.product.id,
            productRating: widget.product.rating,
            reviewCount: widget.product.reviewCount,
          ),
        ],
      ),
    );
  }

  Widget _policyChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _specRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final variant = _selectedVariant;
    final price = widget.product.hasVariants && variant != null
        ? variant.sellingPrice
        : widget.product.price.amount;
    final mrp = widget.product.hasVariants && variant != null
        ? variant.mrp
        : widget.product.price.comparePrice;

    return BlocBuilder<AppConfigBloc, AppConfigState>(
      builder: (context, configState) {
        final config = configState is AppConfigLoaded
            ? configState.config
            : null;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  // Price section — takes remaining space
                  Expanded(
                    child: BlocBuilder<CartBloc, CartState>(
                      builder: (context, cartState) {
                        final hasTax = cartState.cart.summary.tax > 0;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (mrp != null && mrp > price)
                              Text(
                                CurrencyFormatter.formatAmount(
                                  mrp,
                                  config?.currencyConfig,
                                ),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF999999),
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: Color(0xFF999999),
                                ),
                              ),
                            Text(
                              CurrencyFormatter.formatAmount(
                                price,
                                config?.currencyConfig,
                              ),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (hasTax)
                              const Text(
                                'Inclusive of all taxes',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Cart button — fixed width matching Blinkit proportions
                  BlocBuilder<CartBloc, CartState>(
                    builder: (context, cartState) {
                      final cartItem = cartState.cart.getItem(
                        widget.product.id,
                        variantId: variant?.id,
                      );
                      final isOut = !widget.product.inventory.inStock || (variant != null ? variant.quantity <= 0 : widget.product.inventory.quantity <= 0);
                      if (isOut) {
                        return SizedBox(
                          width: 160,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              HapticFeedback.lightImpact();
                              try {
                                final api = getIt<ApiClient>();
                                await api.post('/products/${widget.product.id}/notify-stock');
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('🔔 We will notify you when this item is back in stock!'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('🔔 Stock notification request received!'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.notifications_active_outlined, size: 18),
                            label: const Text('Notify Me', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF9800),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        );
                      }

                      if (cartItem != null) {
                        return _buildQtySelector(
                          context,
                          cartItem.quantity,
                          variant?.id,
                        );
                      }
                      return SizedBox(
                        width: 160,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            setState(() => _isAddingToCart = true);
                            context.read<CartBloc>().add(
                              AddToCartEvent(
                                productId: widget.product.id,
                                quantity: 1,
                                variantId: variant?.id,
                                productName: widget.product.name,
                                productImage: widget.product.imageUrl,
                                price: price,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text(
                            'Add to cart',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showReplaceCartDialog(BuildContext context) {
    showReplaceCartBottomSheet(
      context,
      onConfirm: () {
        context.read<CartBloc>().add(ClearCartEvent());
        final variant = _selectedVariant;
        final price = widget.product.hasVariants && variant != null
            ? variant.sellingPrice
            : widget.product.price.amount;

        Future.delayed(const Duration(milliseconds: 200), () {
          if (context.mounted) {
            setState(() => _isAddingToCart = true);
            context.read<CartBloc>().add(
              AddToCartEvent(
                productId: widget.product.id,
                quantity: 1,
                variantId: variant?.id,
                productName: widget.product.name,
                productImage: widget.product.imageUrl,
                price: price,
              ),
            );
          }
        });
      },
    );
  }

  Widget _buildQtySelector(BuildContext context, int quantity, int? variantId) {
    return Container(
      width: 130,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              final item = context.read<CartBloc>().state.cart.items.firstWhere(
                (i) =>
                    i.productId == widget.product.id &&
                    i.variantId == variantId,
              );
              if (quantity > 1) {
                context.read<CartBloc>().add(
                  UpdateCartItemEvent(itemId: item.id, quantity: quantity - 1),
                );
              } else {
                context.read<CartBloc>().add(RemoveFromCartEvent(item.id));
              }
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Icon(Icons.remove, color: Colors.white, size: 18),
            ),
          ),
          Text(
            '$quantity',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              final item = context.read<CartBloc>().state.cart.items.firstWhere(
                (i) =>
                    i.productId == widget.product.id &&
                    i.variantId == variantId,
              );
              context.read<CartBloc>().add(
                UpdateCartItemEvent(itemId: item.id, quantity: quantity + 1),
              );
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Icon(Icons.add, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarProducts() {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state is ProductLoading && widget.showSkeleton) {
          return _buildSimilarProductsSkeleton();
        }
        if (state is ProductDetailsLoaded && state.similarProducts == null) {
          return _buildSimilarProductsSkeleton();
        }
        if (state is ProductDetailsLoaded &&
            state.similarProducts?.isNotEmpty == true) {
          return SizedBox(
            height: 260,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: state.similarProducts!.length,
              itemBuilder: (context, index) {
                final product = state.similarProducts![index];
                return SizedBox(
                  width: 160,
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index < state.similarProducts!.length - 1 ? 12 : 0,
                    ),
                    child: GridProductCard(
                      productId: product.id,
                      name: product.name,
                      price: product.price.amount,
                      comparePrice: product.price.comparePrice,
                      imageUrl: product.imageUrl,
                      unit: product.unit,
                      rating: product.rating,
                      reviewCount: product.reviewCount,
                      inStock: product.inventory.inStock,
                      isLargeCard: true,
                      heroTag: 'similar_${product.id}_$index',
                      onTap: () => context.pushNamed(
                        RouteNames.productDetails,
                        pathParameters: {'id': product.id.toString()},
                        extra: product,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSimilarProductsSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 260,
        child: Shimmer.fromColors(
          baseColor: const Color(0xFFEDEDED),
          highlightColor: const Color(0xFFF7F7F7),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return Container(
                width: 160,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 12,
                            width: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: 12,
                            width: 70,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: 10,
                            width: 90,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class FullscreenImageGallery extends StatelessWidget {
  final List<ProductImage> images;
  final int initialIndex;

  const FullscreenImageGallery({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: PageView.builder(
        itemCount: images.length,
        controller: PageController(initialPage: initialIndex),
        itemBuilder: (context, index) => InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Center(
            child: CachedImage(
              imageUrl: images[index].url,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
      ),
    );
  }
}
