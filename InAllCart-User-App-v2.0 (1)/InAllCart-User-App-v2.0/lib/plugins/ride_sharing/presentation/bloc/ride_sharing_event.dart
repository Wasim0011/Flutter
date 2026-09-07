import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class RideSharingEvent extends Equatable {
  const RideSharingEvent();

  @override
  List<Object?> get props => [];
}

class GetVehicleTypesEvent extends RideSharingEvent {}

class GetFareEstimateEvent extends RideSharingEvent {
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;
  final int? vehicleTypeId;

  const GetFareEstimateEvent({
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
    this.vehicleTypeId,
  });

  @override
  List<Object?> get props => [pickupLat, pickupLng, dropoffLat, dropoffLng, vehicleTypeId];
}

class BookRideEvent extends RideSharingEvent {
  final double pickupLat;
  final double pickupLng;
  final String pickupAddress;
  final double dropoffLat;
  final double dropoffLng;
  final String dropoffAddress;
  final int vehicleTypeId;
  final String paymentMethod;
  final String? promoCode;

  const BookRideEvent({
    required this.pickupLat,
    required this.pickupLng,
    required this.pickupAddress,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.dropoffAddress,
    required this.vehicleTypeId,
    required this.paymentMethod,
    this.promoCode,
  });

  @override
  List<Object?> get props => [
        pickupLat,
        pickupLng,
        pickupAddress,
        dropoffLat,
        dropoffLng,
        dropoffAddress,
        vehicleTypeId,
        paymentMethod,
        promoCode,
      ];
}

class BoostRideFareEvent extends RideSharingEvent {
  final int rideId;
  final double boostAmount;

  const BoostRideFareEvent({
    required this.rideId,
    required this.boostAmount,
  });

  @override
  List<Object?> get props => [rideId, boostAmount];
}

class CheckRideStatusEvent extends RideSharingEvent {
  final int rideId;
  const CheckRideStatusEvent({required this.rideId});

  @override
  List<Object?> get props => [rideId];
}

class CancelRideEvent extends RideSharingEvent {
  final int rideId;
  final String reason;

  const CancelRideEvent({required this.rideId, required this.reason});

  @override
  List<Object?> get props => [rideId, reason];
}

class TrackRideEvent extends RideSharingEvent {
  final int rideId;
  const TrackRideEvent({required this.rideId});

  @override
  List<Object?> get props => [rideId];
}

class ResetRideEvent extends RideSharingEvent {}

class LoadRidePaymentMethodsEvent extends RideSharingEvent {}

class InitializeRidePaymentEvent extends RideSharingEvent {
  final int rideId;
  final String paymentMethod;
  final double amount;
  final BuildContext context;

  const InitializeRidePaymentEvent({
    required this.rideId,
    required this.paymentMethod,
    required this.amount,
    required this.context,
  });

  @override
  List<Object?> get props => [rideId, paymentMethod, amount, context];
}

class VerifyRidePaymentEvent extends RideSharingEvent {
  final int rideId;
  final String paymentMethod;
  final String paymentId;
  final Map<String, dynamic>? additionalData;

  const VerifyRidePaymentEvent({
    required this.rideId,
    required this.paymentMethod,
    required this.paymentId,
    this.additionalData,
  });

  @override
  List<Object?> get props => [rideId, paymentMethod, paymentId, additionalData];
}

class LoadRideHistoryEvent extends RideSharingEvent {
  final int page;
  const LoadRideHistoryEvent({this.page = 1});

  @override
  List<Object?> get props => [page];
}

class RateRideEvent extends RideSharingEvent {
  final int rideId;
  final int rating;
  final String? comment;

  const RateRideEvent({
    required this.rideId,
    required this.rating,
    this.comment,
  });

  @override
  List<Object?> get props => [rideId, rating, comment];
}

class TriggerSOSEvent extends RideSharingEvent {
  final int rideId;
  final double lat;
  final double lng;
  final String? message;

  const TriggerSOSEvent({
    required this.rideId,
    required this.lat,
    required this.lng,
    this.message,
  });

  @override
  List<Object?> get props => [rideId, lat, lng, message];
}
