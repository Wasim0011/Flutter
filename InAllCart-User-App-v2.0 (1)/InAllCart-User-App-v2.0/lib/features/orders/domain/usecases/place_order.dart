import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/order.dart' as order_entity;
import '../repositories/order_repository.dart';
import '../../../checkout/domain/entities/checkout_data.dart';

class PlaceOrder {
  final OrderRepository repository;

  PlaceOrder(this.repository);

  Future<Either<Failure, order_entity.Order>> call(PlaceOrderRequest request) {
    return repository.placeOrder(request);
  }
}
