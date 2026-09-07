import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/order.dart' as order_entity;
import '../../../checkout/domain/entities/checkout_data.dart';

abstract class OrderRepository {
  Future<Either<Failure, List<order_entity.Order>>> getOrders({int page = 1, int perPage = 15});
  Future<Either<Failure, List<order_entity.Order>>> forceRefreshOrders();
  Future<Either<Failure, order_entity.Order>> getOrderById(int orderId);
  Future<Either<Failure, order_entity.Order>> getOrderByNumber(String orderNumber);
  Future<Either<Failure, order_entity.Order>> placeOrder(PlaceOrderRequest request);
  Future<Either<Failure, order_entity.Order>> cancelOrder(int orderId, String? reason);
  Future<Either<Failure, Map<String, dynamic>>> trackOrder(String orderNumber);
}
