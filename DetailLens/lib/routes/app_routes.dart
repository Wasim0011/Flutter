import 'package:flutter/material.dart';
import '../presentation/product_image_upload_screen/product_image_upload_screen.dart';
import '../presentation/product_detail_screen/product_detail_screen.dart';

class AppRoutes {
  static const String productImageUploadScreen = '/product_image_upload_screen';
  static const String productDetailScreen = '/product_detail_screen';

  static const String initialRoute = '/';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case initialRoute:
      case productImageUploadScreen:
        return MaterialPageRoute(
          builder: (_) => const ProductImageUploadScreen(),
        );

      case productDetailScreen:
        final productData = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ProductDetailScreen(
            productData: productData,
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
