import 'dart:io';
import 'package:dio/dio.dart';
import '../models/order_model.dart';
import '../../../checkout/domain/entities/checkout_data.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';

abstract class OrderRemoteDataSource {
  Future<OrdersResponse> getOrders({int page = 1, int perPage = 15, String? currentETag});
  Future<OrderModel> getOrderById(int orderId);
  Future<OrderModel> getOrderByNumber(String orderNumber);
  Future<PlaceOrderResponse> placeOrder(PlaceOrderRequest request);
  Future<OrderModel> cancelOrder(int orderId, String? reason);
  Future<Map<String, dynamic>> trackOrder(String orderNumber);
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final ApiClient apiClient;

  OrderRemoteDataSourceImpl(this.apiClient);

  @override
  Future<OrdersResponse> getOrders({
    int page = 1,
    int perPage = 15,
    String? currentETag,
  }) async {
    final response = await apiClient.getWithETag<Map<String, dynamic>>(
      ApiEndpoints.orders,
      queryParameters: {'page': page, 'per_page': perPage},
      etag: currentETag,
    );

    if (response.notModified) {
      return OrdersResponse(notModified: true, etag: currentETag);
    }

    final data = response.data?['data'] as List? ?? [];
    final orders = data.map((e) => OrderModel.fromJson(e)).toList();

    return OrdersResponse(
      orders: orders,
      notModified: false,
      etag: response.etag,
    );
  }

  @override
  Future<OrderModel> getOrderById(int orderId) async {
    final response = await apiClient.get(ApiEndpoints.orderDetails(orderId.toString()));
    return OrderModel.fromJson(response['data']);
  }

  @override
  Future<OrderModel> getOrderByNumber(String orderNumber) async {
    final response = await apiClient.get(ApiEndpoints.trackOrder(orderNumber));
    return OrderModel.fromJson(response['data']);
  }

  @override
  Future<PlaceOrderResponse> placeOrder(PlaceOrderRequest request) async {
    dynamic postData = request.toJson();
    if (request.prescriptionImagePath != null && request.prescriptionImagePath!.isNotEmpty) {
      final file = File(request.prescriptionImagePath!);
      if (file.existsSync()) {
        final Map<String, dynamic> map = request.toJson();
        map.remove('prescription_image');
        postData = FormData.fromMap({
          ...map,
          'prescription': await MultipartFile.fromFile(file.path),
        });
      }
    }

    final response = await apiClient.post(ApiEndpoints.orders, data: postData);
    final data = response['data'];
    
    // Check if this is a multi-order response
    final isMultiOrder = data['is_multi_order'] == true;
    
    if (isMultiOrder) {
      // Multiple orders created
      final ordersData = data['orders'] as List;
      final orders = ordersData.map((e) => OrderModel.fromJson(e)).toList();
      final primaryOrder = OrderModel.fromJson(data['primary_order']);
      
      return PlaceOrderResponse(
        isMultiOrder: true,
        orders: orders,
        primaryOrder: primaryOrder,
        orderCount: data['order_count'] as int,
      );
    } else {
      // Single order created
      final order = OrderModel.fromJson(data['order']);
      
      return PlaceOrderResponse(
        isMultiOrder: false,
        orders: [order],
        primaryOrder: order,
        orderCount: 1,
      );
    }
  }

  @override
  Future<OrderModel> cancelOrder(int orderId, String? reason) async {
    final response = await apiClient.post(ApiEndpoints.cancelOrder(orderId.toString()), data: {
      if (reason != null) 'reason': reason,
    });
    return OrderModel.fromJson(response['data']);
  }

  @override
  Future<Map<String, dynamic>> trackOrder(String orderNumber) async {
    final response = await apiClient.get(ApiEndpoints.trackOrder(orderNumber));
    return response['data'] as Map<String, dynamic>;
  }
}

/// Response wrapper with ETag support
class OrdersResponse {
  final List<OrderModel>? orders;
  final bool notModified;
  final String? etag;

  OrdersResponse({this.orders, required this.notModified, this.etag});
}

/// Response wrapper for place order (handles single and multiple orders)
class PlaceOrderResponse {
  final bool isMultiOrder;
  final List<OrderModel> orders;
  final OrderModel primaryOrder;
  final int orderCount;

  PlaceOrderResponse({
    required this.isMultiOrder,
    required this.orders,
    required this.primaryOrder,
    required this.orderCount,
  });
}
