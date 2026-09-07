import 'package:equatable/equatable.dart';
import '../../domain/entities/ride_sharing_entities.dart';

abstract class RideSharingState extends Equatable {
  const RideSharingState();

  @override
  List<Object?> get props => [];
}

class RideSharingInitial extends RideSharingState {}

class RideSharingLoading extends RideSharingState {}

class VehicleTypesLoaded extends RideSharingState {
  final List<VehicleType> vehicleTypes;

  const VehicleTypesLoaded({required this.vehicleTypes});

  @override
  List<Object?> get props => [vehicleTypes];
}

class FareEstimateLoaded extends RideSharingState {
  final List<FareEstimate> fareEstimates;

  const FareEstimateLoaded({required this.fareEstimates});

  @override
  List<Object?> get props => [fareEstimates];
}

class RideSearching extends RideSharingState {
  final Ride ride;

  const RideSearching({required this.ride});

  @override
  List<Object?> get props => [ride];
}

class DriverAssigned extends RideSharingState {
  final Ride ride;

  const DriverAssigned({required this.ride});

  @override
  List<Object?> get props => [ride];
}

class RideCancelled extends RideSharingState {
  /// The cancelled ride, when known (e.g. opened from history). Null when a
  /// cancel action just succeeded and the full ride isn't loaded.
  final Ride? ride;

  const RideCancelled({this.ride});

  @override
  List<Object?> get props => [ride];
}

class RideSharingError extends RideSharingState {
  final String message;

  const RideSharingError({required this.message});

  @override
  List<Object?> get props => [message];
}

class RideTrackingUpdate extends RideSharingState {
  final Ride ride;

  const RideTrackingUpdate({required this.ride});

  @override
  List<Object?> get props => [ride];
}

class RideCompleted extends RideSharingState {
  final Ride ride;
  const RideCompleted({required this.ride});
  @override
  List<Object?> get props => [ride];
}

class RidePaymentMethodsLoaded extends RideSharingState {
  final List<PaymentMethodInfo> methods;
  const RidePaymentMethodsLoaded(this.methods);
  @override
  List<Object> get props => [methods];
}

class RidePaymentRequired extends RideSharingState {
  final Ride ride;
  final String paymentMethod;
  const RidePaymentRequired({required this.ride, required this.paymentMethod});
  @override
  List<Object?> get props => [ride, paymentMethod];
}

class RidePaymentProcessing extends RideSharingState {}

class RidePaymentSuccess extends RideSharingState {
  final bool verified;
  const RidePaymentSuccess(this.verified);
  @override
  List<Object> get props => [verified];
}

class RidePaymentError extends RideSharingState {
  final String message;
  const RidePaymentError(this.message);
  @override
  List<Object> get props => [message];
}

class RideHistoryLoaded extends RideSharingState {
  final List<Ride> rides;
  final bool hasMore;
  final int currentPage;

  const RideHistoryLoaded({
    required this.rides,
    required this.hasMore,
    required this.currentPage,
  });

  @override
  List<Object?> get props => [rides, hasMore, currentPage];
}

class RideRated extends RideSharingState {}

class SOSTriggered extends RideSharingState {}

class SOSError extends RideSharingState {
  final String message;
  const SOSError(this.message);
  @override
  List<Object> get props => [message];
}
