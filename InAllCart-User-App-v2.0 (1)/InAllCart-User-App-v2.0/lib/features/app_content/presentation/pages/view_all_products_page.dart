import 'package:flutter/material.dart';
import '../../../../core/widgets/global_app_bar.dart';
import '../../../../core/widgets/product_cards/grid_product_card.dart';
import '../../../../core/router/routes.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/app_content.dart';

class ViewAllProductsPage extends StatelessWidget {
  final String title;
  final List<ContentProduct> products;

  const ViewAllProductsPage({
    super.key,
    required this.title,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GlobalAppBar(title: title),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.68,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return GridProductCard(
            productId: product.id,
            name: product.name,
            price: product.price,
            comparePrice: product.comparePrice,
            imageUrl: product.image,
            unit: product.unit,
            rating: product.rating,
            reviewCount: product.reviewCount,
            inStock: true,
            isLargeCard: true,
            heroTag: 'view_all_${title}_${product.id}_$index',
            onTap: () => context.push(Routes.product(product.id.toString()), extra: product),
          );
        },
      ),
    );
  }
}
