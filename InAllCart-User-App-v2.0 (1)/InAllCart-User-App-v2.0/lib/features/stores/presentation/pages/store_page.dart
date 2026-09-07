import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../../products/presentation/bloc/product_bloc.dart';
import '../../../products/presentation/widgets/product_card.dart';
import '../../../../core/widgets/product_cards/product_card_skeletons.dart';
import '../../../app_content/domain/entities/app_content.dart';
import '../../../cart/presentation/widgets/floating_cart_summary.dart';

class StorePage extends StatefulWidget {
  final int storeId;
  final ContentStore? store;

  const StorePage({
    super.key,
    required this.storeId,
    this.store,
  });

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  final TextEditingController _searchController = TextEditingController();
  late ProductBloc _productBloc;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _productBloc = getIt<ProductBloc>()
      ..add(LoadProducts(storeId: widget.storeId));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _productBloc.add(LoadProducts(storeId: widget.storeId, search: value));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocProvider.value(
        value: _productBloc,
        child: BlocBuilder<ProductBloc, ProductState>(
          builder: (context, state) {
            ContentStore? effectiveStore = widget.store;
            
            // Re-hydrate store info from products if needed
            if (effectiveStore == null && state is ProductsLoaded && state.products.isNotEmpty) {
              final firstProduct = state.products.first;
              if (firstProduct.store != null && firstProduct.store!.id == widget.storeId) {
                effectiveStore = ContentStore(
                  id: firstProduct.store!.id,
                  name: firstProduct.store!.name,
                  logo: firstProduct.store!.logo,
                  rating: firstProduct.rating, // Fallback to product rating if needed
                  deliveryTime: firstProduct.deliveryTime,
                );
              }
            }

            return Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    // 1. Header with Cover Image and Logo
                    _buildSliverAppBar(context, effectiveStore),

                    // 2. Search Bar
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                        child: _buildSearchBar(),
                      ),
                    ),
                    
                    // 3. Product Grid Header
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'Products',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),

                    // 4. Product Grid
                    _buildProductGrid(),
                    
                    // Padding at the bottom for better scrolling
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),

                // Floating cart button
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 16,
                  child: FloatingCartSummary(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, ContentStore? store) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.primary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.canPop() ? context.pop() : context.go(Routes.home),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Cover Image
            CachedImage(
              imageUrl: AppConstants.getFullMediaUrl(store?.coverImage ?? store?.logo ?? ''),
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
            ),
            // Decorative SVG Pattern
            Positioned.fill(
              child: SvgPicture.asset(
                'assets/icons/store_decoration.svg',
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.white.withValues(alpha: 0.2),
                  BlendMode.srcIn,
                ),
              ),
            ),
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.4),
                  ],
                ),
              ),
            ),
            // Store Info on Top of Cover
            Positioned(
              left: 16,
              bottom: 16,
              right: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Logo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedImage(
                      imageUrl: AppConstants.getFullMediaUrl(store?.logo ?? ''),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Name and Rating
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          store?.name ?? 'Store ${widget.storeId}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 4,
                                color: Colors.black45,
                                offset: Offset(0, 2),
                              )
                            ],
                          ),
                        ),
                        if (store?.rating != null)
                          Row(
                            children: [
                              const Icon(Icons.star, color: AppColors.accent, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${store!.rating}${store.deliveryTime != null ? " • ${store.deliveryTime}" : ""}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search in this store...',
          hintStyle: const TextStyle(color: AppColors.textTertiary),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state is ProductLoading) {
          return SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.68,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => const GridProductCardSkeleton(isLargeCard: false),
                childCount: 6,
              ),
            ),
          );
        }

        if (state is ProductsLoaded) {
          if (state.products.isEmpty) {
            return const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded, size: 64, color: AppColors.textTertiary),
                      SizedBox(height: 16),
                      Text('No products found in this store'),
                    ],
                  ),
                ),
              ),
            );
          }

          return SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.68,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final product = state.products[index];
                  return ProductCard(
                    product: product,
                    onTap: () => context.push('/product/${product.id}'),
                  );
                },
                childCount: state.products.length,
              ),
            ),
          );
        }

        if (state is ProductError) {
          return SliverToBoxAdapter(
            child: Center(child: Text('Error: ${state.message}')),
          );
        }

        return const SliverToBoxAdapter(child: SizedBox.shrink());
      },
    );
  }
}
