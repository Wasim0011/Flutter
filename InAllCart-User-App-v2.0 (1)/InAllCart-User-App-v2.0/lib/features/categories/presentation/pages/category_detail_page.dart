import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/widgets/cached_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_product_card.dart';
import '../../../../core/widgets/global_app_bar.dart';
import '../../../products/presentation/bloc/product_bloc.dart';
import '../../domain/entities/category.dart';
import '../bloc/category_bloc.dart';
import '../../../../core/widgets/inallcart_loader.dart';
import '../../../../core/utils/category_utils.dart';
import '../../../cart/presentation/widgets/floating_cart_summary.dart';

class CategoryDetailPage extends StatefulWidget {
  final int categoryId;
  final String? categoryName;

  const CategoryDetailPage({
    super.key,
    required this.categoryId,
    this.categoryName,
  });

  @override
  State<CategoryDetailPage> createState() => _CategoryDetailPageState();
}

class _CategoryDetailPageState extends State<CategoryDetailPage> {
  int? _selectedSubcategoryId;
  final ScrollController _scrollController = ScrollController();

  // Holds the BuildContext that has ProductBloc in scope.
  // Set once the BlocBuilder subtree is built; used by the scroll listener.
  BuildContext? _productBlocContext;

  // Premium-style Colors
  final Color _sidebarBg = const Color(0xFFF3F5F7); // Light grey sidebar
  final Color _contentBg = Colors.white; // White content area
  final Color _textPrimary = const Color(0xFF1C1C1C);

  @override
  void initState() {
    super.initState();
    // Attach the listener here so it is registered exactly once.
    // The listener uses _productBlocContext (set inside the BlocBuilder subtree)
    // instead of the State's own context, which is the parent of the
    // MultiBlocProvider and therefore does NOT have ProductBloc in scope.
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Guard: context not yet set (scroll fired before first build) or
    // widget is no longer mounted.
    final ctx = _productBlocContext;
    if (ctx == null || !mounted) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final productState = ctx.read<ProductBloc>().state;
      if (productState is ProductsLoaded && productState.hasMore) {
        ctx.read<ProductBloc>().add(LoadMoreProducts());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<CategoryBloc>()..add(LoadCategories()),
        ),
        BlocProvider(
          create: (_) =>
              getIt<ProductBloc>()
                ..add(LoadProducts(categoryId: widget.categoryId)),
        ),
      ],
      child: BlocBuilder<CategoryBloc, CategoryState>(
        builder: (context, categoryState) {
          // Determine the dynamic title
          String headerTitle = widget.categoryName ?? 'Category';
          Category? sidebarRoot;
          Category? category;

          if (categoryState is CategoriesLoaded) {
            final result = CategoryUtils.findCategoryWithParent(
              categoryState.categories,
              widget.categoryId,
            );
            category = result?.category;
            Category? parent = result?.parent;

            if (category == null && categoryState.categories.isNotEmpty) {
              category = categoryState.categories.first;
            }

            if (category != null) {
              sidebarRoot = category;
              if (!category.hasChildren && parent != null) {
                sidebarRoot = parent;
              }

              // Dynamic title based on selected subcategory
              headerTitle = _selectedSubcategoryId == null
                  ? category.name
                  : (sidebarRoot.children
                            .where((e) => e.id == _selectedSubcategoryId)
                            .firstOrNull
                            ?.name ??
                        category.name);
            }
          }

          return Scaffold(
            backgroundColor: Colors.white,
            appBar: GlobalAppBarWithDivider(title: headerTitle),
            body: Stack(
              children: [
                _buildBody(context, categoryState, category, sidebarRoot),
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 16,
                  child: FloatingCartSummary(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    CategoryState categoryState,
    Category? category,
    Category? sidebarRoot,
  ) {
    if (categoryState is CategoryLoading) {
      return _buildSkeletonLoader();
    }

    if (categoryState is CategoryError) {
      return _buildError(categoryState.message, () {
        context.read<CategoryBloc>().add(LoadCategories());
      });
    }

    if (categoryState is CategoriesLoaded) {
      if (category == null) {
        return _buildError('Category not found', () {
          context.read<CategoryBloc>().add(LoadCategories());
        });
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT SIDEBAR (Fixed width like Elite)
          Container(
            width: 86,
            height: double.infinity,
            color: _sidebarBg,
            child: _buildSubcategorySidebar(context, sidebarRoot ?? category),
          ),

          // RIGHT CONTENT (Expanded Grid)
          Expanded(
            child: Container(color: _contentBg, child: _buildProductsGrid()),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSubcategorySidebar(BuildContext context, Category category) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // "All" Item
        _buildSidebarItem(
          context: context,
          id: null,
          name: 'All',
          imageUrl: category.imageUrl,
          isSelected: _selectedSubcategoryId == null,
        ),

        // Subcategory Items
        ...category.children.map(
          (subcategory) => _buildSidebarItem(
            context: context,
            id: subcategory.id,
            name: subcategory.name,
            imageUrl: subcategory.imageUrl,
            isSelected: _selectedSubcategoryId == subcategory.id,
          ),
        ),

        // Extra bottom padding
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildSidebarItem({
    required BuildContext context,
    required int? id,
    required String name,
    String? imageUrl,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedSubcategoryId = id);
        context.read<ProductBloc>().add(
          LoadProducts(categoryId: id ?? widget.categoryId),
        );
      },
      child: Container(
        // The background color logic for selection (White active, Grey inactive)
        color: isSelected ? Colors.white : Colors.transparent,
        child: Stack(
          children: [
            // Selection Indicator (Colored vertical bar)
            if (isSelected)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: AppColors.primary, // Your brand green/color
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      bottomLeft: Radius.circular(4),
                    ),
                  ),
                ),
              ),

            // Item Content
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Image Circle
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey[300]!,
                        width: isSelected ? 1.5 : 1,
                      ),
                      // Slight shadow for unselected to make them pop off grey bg
                      boxShadow: isSelected
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    padding: const EdgeInsets.all(3),
                    child: ClipOval(
                      child: imageUrl != null
                          ? CachedImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              errorWidget: _buildImagePlaceholder(),
                            )
                          : _buildImagePlaceholder(),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Text Label
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected ? _textPrimary : Colors.grey[600],
                      height: 1.2,
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

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Icon(Icons.image, size: 20, color: Colors.grey[300]),
      ),
    );
  }

  Widget _buildProductsGrid() {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        // Capture the context that has ProductBloc in scope so the scroll
        // listener (_onScroll) can safely call context.read<ProductBloc>().
        _productBlocContext = context;

        if (state is ProductLoading && state is! ProductsLoaded) {
          return const Center(child: InAllCartLoader());
        }

        if (state is ProductError) {
          return _buildError(state.message, () {
            context.read<ProductBloc>().add(
              LoadProducts(
                categoryId: _selectedSubcategoryId ?? widget.categoryId,
              ),
            );
          });
        }

        if (state is ProductsLoaded) {
          if (state.products.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<ProductBloc>().add(
                LoadProducts(
                  categoryId: _selectedSubcategoryId ?? widget.categoryId,
                ),
              );
            },
            child: GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                // Adjusted Aspect Ratio for the new Compact Card
                childAspectRatio:
                    0.57, // Tweak this if card overflows vertically
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: state.products.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.products.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: InAllCartLoader(size: 24),
                      ),
                    ),
                  );
                }

                final product = state.products[index];
                return GlobalProductCard(
                  product: product,
                  onTap: () => context.push(
                    Routes.product(product.id.toString()),
                    extra: product,
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

  Widget _buildError(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'No products here yet',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// Skeleton loader matching the page layout
  Widget _buildSkeletonLoader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT SIDEBAR SKELETON
        Container(
          width: 86,
          height: double.infinity,
          color: _sidebarBg,
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: 8,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Circle shimmer
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Text shimmer
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: 50,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // RIGHT CONTENT SKELETON
        Expanded(
          child: Container(
            color: _contentBg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header shimmer
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: 100,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                // Grid shimmer
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.6,
                        ),
                    itemCount: 9,
                    itemBuilder: (context, index) =>
                        _buildProductCardSkeleton(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductCardSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Title placeholder
          Container(
            width: double.infinity,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          // Subtitle placeholder
          Container(
            width: 60,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          // Price placeholder
          Container(
            width: 40,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
