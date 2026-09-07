import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_app_bar.dart';
import '../bloc/product_bloc.dart';
import '../widgets/product_card.dart';
import '../../../../core/widgets/product_cards/product_card_skeletons.dart';

class ProductsPage extends StatelessWidget {
  final int? categoryId;
  final String? categoryName;
  final String? searchQuery;

  const ProductsPage({
    super.key,
    this.categoryId,
    this.categoryName,
    this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProductBloc>()
        ..add(LoadProducts(categoryId: categoryId, search: searchQuery)),
      child: Scaffold(
        appBar: GlobalAppBar(
          title: searchQuery != null ? 'Search: "$searchQuery"' : (categoryName ?? 'Products'),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => context.push(Routes.search),
            ),
          ],
        ),
        body: BlocBuilder<ProductBloc, ProductState>(
          builder: (context, state) {
            if (state is ProductLoading) {
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.68,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: 8,
                itemBuilder: (context, index) {
                  return const GridProductCardSkeleton(isLargeCard: false);
                },
              );
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
                      onPressed: () => context
                          .read<ProductBloc>()
                          .add(LoadProducts(categoryId: categoryId, search: searchQuery)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is ProductsLoaded) {
              if (state.products.isEmpty) {
                return const Center(
                  child: Text('No products found'),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<ProductBloc>().add(RefreshProducts());
                },
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.68,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: state.products.length + (state.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= state.products.length) {
                      // Load more trigger
                      context.read<ProductBloc>().add(LoadMoreProducts());
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final product = state.products[index];
                    return ProductCard(
                      product: product,
                      onTap: () => context.push(Routes.product('${product.id}'), extra: product),
                    );
                  },
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
