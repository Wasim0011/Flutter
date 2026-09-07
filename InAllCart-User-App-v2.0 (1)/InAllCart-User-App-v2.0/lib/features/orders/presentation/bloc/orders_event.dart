import 'package:equatable/equatable.dart';

abstract class OrdersEvent extends Equatable {
  const OrdersEvent();

  @override
  List<Object?> get props => [];
}

class LoadOrders extends OrdersEvent {
  final int page;
  final bool refresh;

  const LoadOrders({this.page = 1, this.refresh = false});

  @override
  List<Object?> get props => [page, refresh];
}

class RefreshOrders extends OrdersEvent {
  const RefreshOrders();
}
