import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/app_content.dart';
import '../bloc/app_content_bloc.dart';
import '../pages/view_all_products_page.dart';
import 'product_widget.dart';
import 'category_widget.dart';
import 'brand_widget.dart';
import '../../../../core/widgets/content_skeletons.dart';
import 'media_widget.dart';
import 'store_widget.dart';
import '../../../products/presentation/pages/brand_products_page.dart';

class AppContentSection extends StatelessWidget {
  final int? tabId;
  final Function(ContentLinkType type, int? id, String? url, {dynamic extra})? onLinkTap;

  const AppContentSection({
    super.key,
    this.tabId,
    this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppContentBloc, AppContentState>(
      builder: (context, state) {
        
        if (state is AppContentLoading) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1: Media Banner (Style 1 - Full Width)
                  const MediaContentSkeleton(style: 1, height: 160),
                  const SizedBox(height: 20),

                  // Section 2: Product Grid (Style 1 - Grid, 2 cols, 2 rows)
                  const ProductContentSkeleton(
                    style: 1,
                    gridColumns: 2,
                    gridRows: 2,
                    showTitle: true,
                    showSubtitle: true,
                    hasBackground: true,
                  ),
                  const SizedBox(height: 24),

                  // Section 3: Category Circles (Style 1 - Circle)
                  const CategoryContentSkeleton(
                    style: 1,
                    showTitle: true,
                  ),
                  const SizedBox(height: 24),

                  // Section 4: Products Horizontal (Style 2 - Horizontal)
                  const ProductContentSkeleton(
                    style: 2,
                    height: 250,
                    showTitle: true,
                  ),
                  const SizedBox(height: 24),

                  // Section 5: Brand Circles (Style 1 - Circle)
                  const BrandContentSkeleton(
                    style: 1,
                    showTitle: true,
                  ),
                  const SizedBox(height: 24),

                  // Section 6: Products Large (Style 3 - Large cards)
                  const ProductContentSkeleton(
                    style: 3,
                    showTitle: true,
                  ),
                ],
              ),
            ),
          );
        }



        if (state is AppContentError) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text(state.message, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          );
        }

        if (state is AppContentLoaded) {
          
          if (state.contents.isEmpty) {
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          }

          return SliverPadding(
            padding: const EdgeInsets.only(top: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final content = state.contents[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: RepaintBoundary(
                      child: _buildWidget(context, content),
                    ),
                  );
                },
                childCount: state.contents.length,
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: false, // We're adding them manually above
              ),
            ),
          );
        }

        // Initial state - show nothing
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      },
    );
  }

  Widget _buildWidget(BuildContext context, AppContent content) {
    Widget widget;

    switch (content.type) {
      case ContentType.product:
        widget = ProductContentWidget(
          content: content,
          onProductTap: (product) => onLinkTap?.call(ContentLinkType.product, product.id, null, extra: product),
          onViewAllTap: content.showViewAll && (content.products?.isNotEmpty ?? false)
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ViewAllProductsPage(
                        title: content.title ?? 'All Products',
                        products: content.products!,
                      ),
                    ),
                  )
              : null,
        );
        break;
      case ContentType.category:
        widget = CategoryContentWidget(
          content: content,
          onCategoryTap: (categoryId) => onLinkTap?.call(ContentLinkType.category, categoryId, null),
          onProductTap: (product) => onLinkTap?.call(ContentLinkType.product, product.id, null, extra: product),
        );
        break;
      case ContentType.brand:
        widget = BrandContentWidget(
          content: content,
          onBrandTap: (brandId) {
            final brandName = content.brands
                    ?.cast<ContentBrand>()
                    .where((b) => b.id == brandId)
                    .firstOrNull
                    ?.name ??
                'Brand';
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BrandProductsPage(
                  brandId: brandId,
                  brandName: brandName,
                ),
              ),
            );
          },
        );
        break;
      case ContentType.media:
        widget = MediaContentWidget(
          content: content,
          onLinkTap: (type, id, url, {extra}) => onLinkTap?.call(type, id, url, extra: extra),
          onTap: () {
            // Legacy single media link support
            if (content.link != null && content.link!.type != ContentLinkType.none) {
              onLinkTap?.call(content.link!.type, content.link!.id, content.link!.url);
            }
          },
        );
        break;
      case ContentType.store:
        widget = StoreContentWidget(
          content: content,
          onStoreTap: (store) => onLinkTap?.call(ContentLinkType.store, store.id, null, extra: store),
        );
        break;
    }

    return widget;
  }
}
