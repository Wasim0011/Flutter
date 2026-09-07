import 'package:equatable/equatable.dart';
import '../../domain/entities/order.dart';

abstract class OrdersState extends Equatable {
  const OrdersState();

  @override
  List<Object?> get props => [];
}

class OrdersInitial extends OrdersState {
  const OrdersInitial();
}

class OrdersLoading extends OrdersState {
  const OrdersLoading();
}

class OrdersLoaded extends OrdersState {
  final List<Order> orders;
  final bool hasMore;
  final int currentPage;
  final bool isStale;

  const OrdersLoaded({
    required this.orders,
    this.hasMore = true,
    this.currentPage = 1,
    this.isStale = false,
  });

  OrdersLoaded copyWith({
    List<Order>? orders,
    bool? hasMore,
    int? currentPage,
    bool? isStale,
  }) {
    return OrdersLoaded(
      orders: orders ?? this.orders,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      isStale: isStale ?? this.isStale,
    );
  }

  @override
  List<Object?> get props => [orders, hasMore, currentPage, isStale];
}

class OrdersError extends OrdersState {
  final String message;

  const OrdersError(this.message);

  @override
  List<Object?> get props => [message];
}

class OrdersLoadingMore extends OrdersState {
  final List<Order> orders;
  final int currentPage;

  const OrdersLoadingMore({
    required this.orders,
    required this.currentPage,
  });

  @override
  List<Object?> get props => [orders, currentPage];
}
