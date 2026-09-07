import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/data_sync_service.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/entities/order.dart';
import 'orders_event.dart';
import 'orders_state.dart';

// Private event for stream updates
class _StreamDataUpdated extends OrdersEvent {
  final List<Order> orders;
  final bool isStale;

  const _StreamDataUpdated(this.orders, {this.isStale = false});

  @override
  List<Object?> get props => [orders, isStale];
}

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final OrderRepository repository;
  final DataSyncService _dataSyncService;
  final PushNotificationService? _pushNotificationService;
  StreamSubscription? _streamSubscription;
  StreamSubscription? _pushSubscription;
  Timer? _pollingTimer;
  String? _lastDataHash;

  OrdersBloc(this.repository, {PushNotificationService? pushNotificationService})
      : _dataSyncService = DataSyncService(),
        _pushNotificationService = pushNotificationService,
        super(const OrdersInitial()) {
    on<LoadOrders>(_onLoadOrders);
    on<RefreshOrders>(_onRefreshOrders);
    on<_StreamDataUpdated>(_onStreamDataUpdated);
    
    _subscribeToStream();
    _subscribeToPushNotifications();
    _startPolling();
  }

  String _generateDataHash(List data) {
    final buffer = StringBuffer();
    for (final item in data) {
      buffer.write('${item.id}_${item.orderNumber}_${item.status.value}_');
    }
    return buffer.toString().hashCode.toString();
  }

  void _subscribeToStream() {
    _streamSubscription?.cancel();
    
    _streamSubscription = _dataSyncService.ordersStream
        .distinct((prev, curr) {
          if (!prev.hasData || !curr.hasData) return false;
          return _generateDataHash(prev.data!) == _generateDataHash(curr.data!) &&
                 prev.isStale == curr.isStale;
        })
        .listen((dataState) {
          if (dataState.hasData && !isClosed) {
            final newHash = _generateDataHash(dataState.data!);
            
            if (_lastDataHash != newHash || 
                (state is OrdersLoaded && 
                 (state as OrdersLoaded).isStale != dataState.isStale)) {
              _lastDataHash = newHash;
              add(_StreamDataUpdated(dataState.data!, isStale: dataState.isStale));
            }
          }
        });
  }

  void _subscribeToPushNotifications() {
    final pushService = _pushNotificationService;
    if (pushService == null) return;
    
    _pushSubscription?.cancel();
    
    // Listen to push notifications for order updates
    _pushSubscription = pushService.onMessage.listen((message) {
      final data = message['data'] as Map<String, dynamic>?;
      if (data == null) return;
      
      final type = data['type'] as String?;
      
      // Handle order status updates
      if (type == 'order_status' || type == 'order_update' || type == 'new_order') {
        // Force immediate refresh bypassing cache
        _forceRefreshOrders();
      }
    });
  }

  Future<void> _forceRefreshOrders() async {
    if (isClosed) return;
    
    final result = await repository.forceRefreshOrders();
    
    result.fold(
      (failure) {
        // Keep current state on error
      },
      (orders) {
        if (!isClosed) {
          add(_StreamDataUpdated(orders, isStale: false));
        }
      },
    );
  }

  void _startPolling() {
    // Poll every 30 seconds for order updates
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!isClosed && state is OrdersLoaded) {
        add(const LoadOrders(page: 1, refresh: false));
      }
    });
  }

  Future<void> _onLoadOrders(
    LoadOrders event,
    Emitter<OrdersState> emit,
  ) async {
    
    if (event.refresh) {
      emit(const OrdersLoading());
    } else if (state is OrdersLoaded) {
      final currentState = state as OrdersLoaded;
      emit(OrdersLoadingMore(
        orders: currentState.orders,
        currentPage: currentState.currentPage,
      ));
    } else {
      emit(const OrdersLoading());
    }

    final result = await repository.getOrders(
      page: event.page,
      perPage: 15,
    );

    result.fold(
      (failure) {
        emit(OrdersError(failure.message));
      },
      (orders) {
        _lastDataHash = _generateDataHash(orders);
        
        if (state is OrdersLoadingMore) {
          final currentState = state as OrdersLoadingMore;
          final allOrders = [...currentState.orders, ...orders];
          emit(OrdersLoaded(
            orders: allOrders,
            hasMore: orders.length >= 15,
            currentPage: event.page,
          ));
        } else {
          emit(OrdersLoaded(
            orders: orders,
            hasMore: orders.length >= 15,
            currentPage: event.page,
          ));
        }
      },
    );
  }

  Future<void> _onRefreshOrders(
    RefreshOrders event,
    Emitter<OrdersState> emit,
  ) async {
    add(const LoadOrders(page: 1, refresh: true));
  }

  void _onStreamDataUpdated(
    _StreamDataUpdated event,
    Emitter<OrdersState> emit,
  ) {
    emit(OrdersLoaded(
      orders: event.orders,
      hasMore: event.orders.length >= 15,
      currentPage: 1,
      isStale: event.isStale,
    ));
  }

  @override
  Future<void> close() {
    _streamSubscription?.cancel();
    _pushSubscription?.cancel();
    _pollingTimer?.cancel();
    return super.close();
  }
}
