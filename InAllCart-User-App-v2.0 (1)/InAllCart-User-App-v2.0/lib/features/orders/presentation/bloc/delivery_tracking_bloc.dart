import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/data_sync_service.dart';
import '../../domain/usecases/get_delivery_tracking.dart';
import 'delivery_tracking_event.dart';
import 'delivery_tracking_state.dart';

/// Delivery tracking BLoC - Professional Premium-level implementation
/// 
/// Features:
/// - Cache-first loading (instant display)
/// - Automatic polling every 10 seconds
/// - Real-time updates via DataSyncService
/// - Smooth state transitions
/// - Proper cleanup on dispose
class DeliveryTrackingBloc extends Bloc<DeliveryTrackingEvent, DeliveryTrackingState> {
  final GetDeliveryTracking _getDeliveryTracking;
  final GetTrackingHistory _getTrackingHistory;
  final DataSyncService _dataSyncService;

  Timer? _pollingTimer;
  StreamSubscription? _trackingSubscription;
  int? _currentOrderId;

  DeliveryTrackingBloc({
    required GetDeliveryTracking getDeliveryTracking,
    required GetTrackingHistory getTrackingHistory,
    required DataSyncService dataSyncService,
  })  : _getDeliveryTracking = getDeliveryTracking,
        _getTrackingHistory = getTrackingHistory,
        _dataSyncService = dataSyncService,
        super(const DeliveryTrackingInitial()) {
    on<LoadDeliveryTracking>(_onLoadDeliveryTracking);
    on<RefreshDeliveryTracking>(_onRefreshDeliveryTracking);
    on<StartTrackingPolling>(_onStartTrackingPolling);
    on<StopTrackingPolling>(_onStopTrackingPolling);
    on<LoadTrackingHistory>(_onLoadTrackingHistory);
    on<TrackingRealtimeUpdate>(_onTrackingRealtimeUpdate);
  }

  /// Load tracking data (cache-first)
  Future<void> _onLoadDeliveryTracking(
    LoadDeliveryTracking event,
    Emitter<DeliveryTrackingState> emit,
  ) async {
    _currentOrderId = event.orderId;

    // Show loading only on first load
    if (state is! DeliveryTrackingLoaded) {
      emit(const DeliveryTrackingLoading());
    }

    // Subscribe to DataSyncService stream for reactive updates
    await _trackingSubscription?.cancel();
    _trackingSubscription = _dataSyncService
        .deliveryTrackingStream(event.orderId)
        .listen((dataState) {
      if (!emit.isDone) {
        if (dataState.hasData) {
          emit(DeliveryTrackingLoaded(
            tracking: dataState.data!,
            isStale: dataState.isStale,
            isRefreshing: dataState.isLoading,
            history: state is DeliveryTrackingLoaded
                ? (state as DeliveryTrackingLoaded).history
                : null,
            lastUpdate: DateTime.now(),
          ));
        } else if (dataState.hasError) {
          emit(DeliveryTrackingError(
            message: dataState.error?.message ?? 'Failed to load tracking data',
            cachedTracking: state is DeliveryTrackingLoaded
                ? (state as DeliveryTrackingLoaded).tracking
                : null,
          ));
        }
      }
    });

    // Fetch tracking data (will use cache if available)
    final result = await _getDeliveryTracking(
      orderId: event.orderId,
      forceRefresh: event.forceRefresh,
    );

    result.fold(
      (failure) {
        if (state is! DeliveryTrackingLoaded) {
          emit(DeliveryTrackingError(message: failure.message));
        }
      },
      (tracking) {
        // Explicitly emit loaded state to prevent "stuck in loading" if stream is slow
        if (state is! DeliveryTrackingLoaded) {
          emit(DeliveryTrackingLoaded(
            tracking: tracking,
            isStale: false,
            isRefreshing: false,
            lastUpdate: DateTime.now(),
          ));
        }
      },
    );
  }

  /// Refresh tracking data (called by timer)
  Future<void> _onRefreshDeliveryTracking(
    RefreshDeliveryTracking event,
    Emitter<DeliveryTrackingState> emit,
  ) async {
    // Don't show loading spinner during refresh
    if (state is DeliveryTrackingLoaded) {
      emit((state as DeliveryTrackingLoaded).copyWith(isRefreshing: true));
    }

    final result = await _getDeliveryTracking(
      orderId: event.orderId,
      forceRefresh: false, // Use ETag validation
    );

    result.fold(
      (failure) {
        // Keep current state on refresh failure
        if (state is DeliveryTrackingLoaded) {
          emit((state as DeliveryTrackingLoaded).copyWith(isRefreshing: false));
        }
      },
      (tracking) {
        // DataSyncService will emit the update via stream
      },
    );
  }

  /// Start polling every 10 seconds
  void _onStartTrackingPolling(
    StartTrackingPolling event,
    Emitter<DeliveryTrackingState> emit,
  ) {
    _stopPolling();

    // Poll every 10 seconds (High-level frequency)
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 10),
      (timer) {
        if (_currentOrderId != null) {
          add(RefreshDeliveryTracking(_currentOrderId!));
        }
      },
    );
  }

  /// Stop polling
  void _onStopTrackingPolling(
    StopTrackingPolling event,
    Emitter<DeliveryTrackingState> emit,
  ) {
    _stopPolling();
  }

  /// Load tracking history for route replay
  Future<void> _onLoadTrackingHistory(
    LoadTrackingHistory event,
    Emitter<DeliveryTrackingState> emit,
  ) async {
    if (state is! DeliveryTrackingLoaded) return;

    final result = await _getTrackingHistory(orderId: event.orderId);

    result.fold(
      (failure) {
        // Keep current state, just log error
      },
      (history) {
        if (state is DeliveryTrackingLoaded) {
          emit((state as DeliveryTrackingLoaded).copyWith(history: history));
        }
      },
    );
  }

  /// Handle real-time update from RealtimeService
  void _onTrackingRealtimeUpdate(
    TrackingRealtimeUpdate event,
    Emitter<DeliveryTrackingState> emit,
  ) {
    // Force refresh to get latest data
    add(LoadDeliveryTracking(orderId: event.orderId, forceRefresh: true));
  }

  /// Stop polling timer
  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  Future<void> close() {
    _stopPolling();
    _trackingSubscription?.cancel();
    return super.close();
  }
}
