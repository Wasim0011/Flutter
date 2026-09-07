import 'package:equatable/equatable.dart';

import '../../domain/entities/delivery_tracking.dart';

abstract class DeliveryTrackingState extends Equatable {
  const DeliveryTrackingState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class DeliveryTrackingInitial extends DeliveryTrackingState {
  const DeliveryTrackingInitial();
}

/// Loading state (first load only)
class DeliveryTrackingLoading extends DeliveryTrackingState {
  const DeliveryTrackingLoading();
}

/// Loaded state with tracking data
class DeliveryTrackingLoaded extends DeliveryTrackingState {
  final DeliveryTracking tracking;
  final bool isStale;
  final bool isRefreshing;
  final List<TrackingHistoryPoint>? history;
  final DateTime lastUpdate;

  const DeliveryTrackingLoaded({
    required this.tracking,
    this.isStale = false,
    this.isRefreshing = false,
    this.history,
    required this.lastUpdate,
  });

  DeliveryTrackingLoaded copyWith({
    DeliveryTracking? tracking,
    bool? isStale,
    bool? isRefreshing,
    List<TrackingHistoryPoint>? history,
    DateTime? lastUpdate,
  }) {
    return DeliveryTrackingLoaded(
      tracking: tracking ?? this.tracking,
      isStale: isStale ?? this.isStale,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      history: history ?? this.history,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }

  @override
  List<Object?> get props => [tracking, isStale, isRefreshing, history, lastUpdate];
}

/// Error state
class DeliveryTrackingError extends DeliveryTrackingState {
  final String message;
  final DeliveryTracking? cachedTracking;

  const DeliveryTrackingError({
    required this.message,
    this.cachedTracking,
  });

  @override
  List<Object?> get props => [message, cachedTracking];
}

/// Tracking not available
class DeliveryTrackingNotAvailable extends DeliveryTrackingState {
  final String reason;

  const DeliveryTrackingNotAvailable(this.reason);

  @override
  List<Object?> get props => [reason];
}
