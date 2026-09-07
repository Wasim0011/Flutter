import 'package:equatable/equatable.dart';

abstract class DeliveryTrackingEvent extends Equatable {
  const DeliveryTrackingEvent();

  @override
  List<Object?> get props => [];
}

/// Load tracking data for an order
class LoadDeliveryTracking extends DeliveryTrackingEvent {
  final int orderId;
  final bool forceRefresh;

  const LoadDeliveryTracking({
    required this.orderId,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [orderId, forceRefresh];
}

/// Refresh tracking data (called by timer)
class RefreshDeliveryTracking extends DeliveryTrackingEvent {
  final int orderId;

  const RefreshDeliveryTracking(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

/// Start polling for updates
class StartTrackingPolling extends DeliveryTrackingEvent {
  final int orderId;

  const StartTrackingPolling(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

/// Stop polling
class StopTrackingPolling extends DeliveryTrackingEvent {
  const StopTrackingPolling();
}

/// Load tracking history for route replay
class LoadTrackingHistory extends DeliveryTrackingEvent {
  final int orderId;

  const LoadTrackingHistory(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

/// Real-time update received from RealtimeService
class TrackingRealtimeUpdate extends DeliveryTrackingEvent {
  final int orderId;
  final Map<String, dynamic> data;

  const TrackingRealtimeUpdate({
    required this.orderId,
    required this.data,
  });

  @override
  List<Object?> get props => [orderId, data];
}
