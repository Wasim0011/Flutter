import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../../../core/widgets/inallcart_loader.dart';
import '../../../app_config/presentation/bloc/app_config_bloc.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/presentation/bloc/product_bloc.dart';
import '../bloc/wishlist_bloc.dart';

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final wishlistIds = context.read<WishlistBloc>().state.productIds;
        return getIt<ProductBloc>()..add(LoadProductsByIds(wishlistIds));
      },
      child: const _WishlistView(),
    );
  }
}

class _WishlistView extends StatelessWidget {
  const _WishlistView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocListener<WishlistBloc, WishlistState>(
        listener: (context, state) {
          context.read<ProductBloc>().add(LoadProductsByIds(state.productIds));
        },
        child: BlocBuilder<ProductBloc, ProductState>(
          builder: (context, state) {
            if (state is ProductLoading) {
              return const Center(child: InAllCartLoader());
            }

            if (state is ProductError) {
              return _buildErrorState(context, state.message);
            }

            if (state is ProductsLoaded) {
              if (state.products.isEmpty) {
                return _buildEmptyState(context);
              }
              return _buildWishlistContent(context, state.products);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildWishlistContent(BuildContext context, List<Product> products) {
    return CustomScrollView(
      slivers: [
        // Custom App Bar
        SliverAppBar(
          pinned: true,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
            onPressed: () => context.canPop() ? context.pop() : context.go(Routes.home),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Wishlist',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                '${products.length} item${products.length != 1 ? 's' : ''} saved',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          actions: [
            if (products.isNotEmpty)
              TextButton(
                onPressed: () => _showClearAllSheet(context),
                child: const Text(
                  'Clear All',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(width: 4),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: AppColors.border.withValues(alpha: 0.5)),
          ),
        ),

        // Product List
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = products[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _WishlistItemCard(
                    product: product,
                    showSwipeHint: index == 0,
                  ),
                );
              },
              childCount: products.length,
            ),
          ),
        ),

        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  void _showClearAllSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline_rounded, size: 32, color: AppColors.error),
            ),
            const SizedBox(height: 16),
            const Text(
              'Clear Wishlist?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'All saved items will be removed from your wishlist.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.read<WishlistBloc>().add(ClearWishlist());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Clear All', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      children: [
        // App bar
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  onPressed: () => context.canPop() ? context.pop() : context.go(Routes.home),
                ),
                const Text(
                  'My Wishlist',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      size: 56,
                      color: Color(0xFFFF6B8A),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'No saved items yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the heart icon on products you love\nto save them here for later',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => context.go(Routes.home),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text(
                        'Explore Products',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              final ids = context.read<WishlistBloc>().state.productIds;
              context.read<ProductBloc>().add(LoadProductsByIds(ids));
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _WishlistItemCard extends StatefulWidget {
  final Product product;
  final bool showSwipeHint;

  const _WishlistItemCard({required this.product, this.showSwipeHint = false});

  @override
  State<_WishlistItemCard> createState() => _WishlistItemCardState();
}

class _WishlistItemCardState extends State<_WishlistItemCard> with SingleTickerProviderStateMixin {
  late final AnimationController _hintController;
  late final Animation<Offset> _hintAnimation;

  @override
  void initState() {
    super.initState();
    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _hintAnimation = TweenSequence<Offset>([
      TweenSequenceItem(tween: Tween(begin: Offset.zero, end: const Offset(-0.15, 0)).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: const Offset(-0.15, 0), end: Offset.zero).chain(CurveTween(curve: Curves.elasticIn)), weight: 60),
    ]).animate(_hintController);

    if (widget.showSwipeHint) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          HapticFeedback.lightImpact();
          _hintController.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _hintController.dispose();
    super.dispose();
  }

  Product get product => widget.product;

  @override
  Widget build(BuildContext context) {
    final imageUrl = AppConstants.getFullMediaUrl(product.imageUrl);
    final hasDiscount = product.hasDiscount;
    final discountPercent = hasDiscount
        ? ((product.price.comparePrice! - product.price.amount) / product.price.comparePrice! * 100).round()
        : 0;

    return AnimatedBuilder(
      animation: _hintAnimation,
      builder: (context, child) {
        final offset = _hintAnimation.value;
        final showBg = offset.dx < 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Red background revealed during hint
            if (showBg)
              Positioned.fill(
                child: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chevron_left_rounded, color: Colors.white.withValues(alpha: 0.8), size: 18),
                      const SizedBox(width: 2),
                      Text('Swipe', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            SlideTransition(
              position: _hintAnimation,
              child: child!,
            ),
          ],
        );
      },
      child: Dismissible(
      key: ValueKey(product.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        context.read<WishlistBloc>().add(ToggleWishlistProduct(product.id));
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 28),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
      ),
      child: GestureDetector(
        onTap: () => context.push('/product/${product.id}'),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedImage(
                      imageUrl: imageUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SvgPicture.asset('assets/icons/placeholder.svg', fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  if (hasDiscount)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$discountPercent% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  if (!product.inventory.inStock)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'OUT OF STOCK',
                            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              // Product Details
              Expanded(
                child: SizedBox(
                  height: 100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.3,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Unit / Category
                      if (product.unit != null || product.category != null)
                        Text(
                          product.unit ?? product.category?.name ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const Spacer(),
                      // Price + Add Button Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Price
                          Expanded(
                            child: BlocBuilder<AppConfigBloc, AppConfigState>(
                              builder: (context, state) {
                                final config = state is AppConfigLoaded ? state.config : null;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (hasDiscount)
                                      Text(
                                        CurrencyFormatter.formatAmount(product.price.comparePrice!, config?.currencyConfig),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textTertiary,
                                          decoration: TextDecoration.lineThrough,
                                          decorationColor: AppColors.textTertiary,
                                        ),
                                      ),
                                    Text(
                                      CurrencyFormatter.formatAmount(product.price.amount, config?.currencyConfig),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          // Add to Cart / Remove
                          if (product.inventory.inStock)
                            _buildAddToCartButton(context)
                          else
                            _buildRemoveButton(context),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildAddToCartButton(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, cartState) {
        final inCart = cartState.cart.items.any((item) => item.productId == product.id);
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            if (inCart) {
              context.push('/cart');
            } else {
              context.read<CartBloc>().add(
                AddToCartEvent(
                  productId: product.id,
                  quantity: 1,
                  productName: product.name,
                  productImage: product.imageUrl,
                  price: product.price.amount,
                ),
              );
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: inCart ? AppColors.success : AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              inCart ? 'View Cart' : 'Add',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRemoveButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.read<WishlistBloc>().add(ToggleWishlistProduct(product.id));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Remove',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
