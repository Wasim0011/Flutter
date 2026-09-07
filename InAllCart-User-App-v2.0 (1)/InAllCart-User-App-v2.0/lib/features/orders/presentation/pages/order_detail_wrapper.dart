import 'package:flutter/material.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/global_app_bar.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/entities/order.dart';
import 'order_detail_page.dart';

/// Order Detail Wrapper
/// Fetches order data if not provided (for deep links)
class OrderDetailWrapper extends StatelessWidget {
  final String orderId;
  final Order? order;

  const OrderDetailWrapper({
    super.key,
    required this.orderId,
    this.order,
  });

  @override
  Widget build(BuildContext context) {
    // If order is already provided, show it directly
    if (order != null) {
      return OrderDetailPage(order: order!);
    }

    // Otherwise, fetch the order
    return FutureBuilder<Order?>(
      future: _fetchOrder(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: const GlobalAppBar(
              title: 'Order Details',
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Order not found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error?.toString() ?? 'Unable to load order',
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        return OrderDetailPage(order: snapshot.data!);
      },
    );
  }

  Future<Order?> _fetchOrder() async {
    try {
      final repository = getIt<OrderRepository>();
      final result = await repository.getOrderById(int.parse(orderId));
      
      return result.fold(
        (failure) => null,
        (order) => order,
      );
    } catch (e) {
      return null;
    }
  }
}
