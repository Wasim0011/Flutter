import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/ride_sharing_repository.dart';
import '../../domain/entities/ride_sharing_entities.dart' as ride_entities;
import 'ride_sharing_event.dart';
import 'ride_sharing_state.dart';
import '../../../../core/services/payment_gateway_service.dart';

class RideSharingBloc extends Bloc<RideSharingEvent, RideSharingState> {
  final RideSharingRepository repository;
  final PaymentGatewayService paymentService;

  RideSharingBloc({
    required this.repository,
    required this.paymentService,
  }) : super(RideSharingInitial()) {
    on<GetVehicleTypesEvent>(_onGetVehicleTypes);
    on<GetFareEstimateEvent>(_onGetFareEstimate);
    on<BookRideEvent>(_onBookRide);
    on<BoostRideFareEvent>(_onBoostRideFare);
    on<CheckRideStatusEvent>(_onCheckRideStatus);
    on<TrackRideEvent>(_onTrackRide);
    on<CancelRideEvent>(_onCancelRide);
    on<ResetRideEvent>((event, emit) => emit(RideSharingInitial()));
    on<LoadRidePaymentMethodsEvent>(_onLoadPaymentMethods);
    on<InitializeRidePaymentEvent>(_onInitializePayment);
    on<VerifyRidePaymentEvent>(_onVerifyPayment);
    on<LoadRideHistoryEvent>(_onLoadRideHistory);
    on<RateRideEvent>(_onRateRide);
    on<TriggerSOSEvent>(_onTriggerSOS);
  }

  Future<void> _onGetVehicleTypes(
    GetVehicleTypesEvent event,
    Emitter<RideSharingState> emit,
  ) async {
    emit(RideSharingLoading());
    final result = await repository.getVehicleTypes();
    result.fold(
      (failure) => emit(RideSharingError(message: failure.message)),
      (types) => emit(VehicleTypesLoaded(vehicleTypes: types)),
    );
  }

  Future<void> _onGetFareEstimate(
    GetFareEstimateEvent event,
    Emitter<RideSharingState> emit,
  ) async {
    if (event.vehicleTypeId == null) return;

    final result = await repository.getFareEstimates(
      pickupLat: event.pickupLat,
      pickupLng: event.pickupLng,
      dropoffLat: event.dropoffLat,
      dropoffLng: event.dropoffLng,
      vehicleTypeId: event.vehicleTypeId,
    );
    result.fold(
      (failure) => null,
      (estimates) {
        final currentState = state;
        final existing = currentState is FareEstimateLoaded
            ? List<ride_entities.FareEstimate>.from(currentState.fareEstimates)
            : <ride_entities.FareEstimate>[];
        for (final e in estimates) {
          existing.removeWhere((ex) => ex.vehicleType == e.vehicleType);
          existing.add(e);
        }
        emit(FareEstimateLoaded(fareEstimates: existing));
      },
    );
  }

  Future<void> _onBookRide(
    BookRideEvent event,
    Emitter<RideSharingState> emit,
  ) async {
    emit(RideSharingLoading());

    final result = await repository.bookRide(
      pickupLat: event.pickupLat,
      pickupLng: event.pickupLng,
      pickupAddress: event.pickupAddress,
      dropoffLat: event.dropoffLat,
      dropoffLng: event.dropoffLng,
      dropoffAddress: event.dropoffAddress,
      vehicleTypeId: event.vehicleTypeId,
      paymentMethod: event.paymentMethod,
      promoCode: event.promoCode,
    );

    result.fold(
      (failure) => emit(RideSharingError(message: failure.message)),
      (ride) {
        if (event.paymentMethod != 'cash' && event.paymentMethod != 'wallet') {
          emit(RidePaymentRequired(ride: ride, paymentMethod: event.paymentMethod));
        } else {
          if (ride.driverId != null) {
            emit(DriverAssigned(ride: ride));
          } else {
            emit(RideSearching(ride: ride));
          }
        }
      },
    );
  }

  Future<void> _onBoostRideFare(
    BoostRideFareEvent event,
    Emitter<RideSharingState> emit,
  ) async {
    final result = await repository.boostFare(event.rideId, event.boostAmount);
    result.fold(
      (failure) => emit(RideSharingError(message: failure.message)),
      (ride) => emit(RideSearching(ride: ride)),
    );
  }

  Future<void> _onCheckRideStatus(
    CheckRideStatusEvent event,
    Emitter<RideSharingState> emit,
  ) async {
    // Do NOT emit RideSharingLoading here — this handler is called repeatedly
    // by the polling timer. Emitting Loading causes the UI to flicker and,
    // if the API returns a transient 401, the error handler in the UI kicks
    // the user out of the findingDriver state prematurely.
    final result = await repository.getRideDetails(event.rideId);
    result.fold(
      (failure) {
        emit(RideSharingError(message: failure.message));
      },
      (ride) {
        switch (ride.status) {
          case 'cancelled':
            emit(RideCancelled(ride: ride));
          case 'completed':
            emit(RideCompleted(ride: ride));
          default:
            if (ride.driverId != null) {
              emit(DriverAssigned(ride: ride));
            } else {
              emit(RideSearching(ride: ride));
            }
        }
      },
    );
  }

  Future<void> _onCancelRide(
    CancelRideEvent event,
    Emitter<RideSharingState> emit,
  ) async {
    emit(RideSharingLoading());
    final result = await repository.cancelRide(event.rideId, event.reason);
    result.fold(
      (failure) => emit(RideCancelled()),
      (_) => emit(RideCancelled()),
    );
  }

  Future<void> _onTrackRide(
    TrackRideEvent event,
    Emitter<RideSharingState> emit,
  ) async {
    final result = await repository.trackRide(event.rideId);
    result.fold(
      (failure) => null, // Ignore tracking errors to avoid disrupting UI
      (ride) {
        if (ride.status == 'completed') {
          emit(RideCompleted(ride: ride));
        } else if (ride.status == 'cancelled') {
          emit(RideCancelled());
        } else {
          emit(RideTrackingUpdate(ride: ride));
        }
      },
    );
  }

  Future<void> _onLoadPaymentMethods(
    LoadRidePaymentMethodsEvent event,
    Emitter<RideSharingState> emit,
  ) async {
    final result = await repository.getPaymentMethods();
    result.fold(
      (failure) => emit(RidePaymentError(failure.message)),
      (methods) => emit(RidePaymentMethodsLoaded(methods)),
    );
  }

  Future<void> _onInitializePayment(
    InitializeRidePaymentEvent event,
    Emitter<RideSharingState> emit,
  ) async {
    emit(RidePaymentProcessing());
    final result = await repository.initializeRidePayment(
      rideId: event.rideId,
      paymentMethod: event.paymentMethod,
      amount: event.amount,
    );

    await result.fold(
      (failure) async => emit(RidePaymentError(failure.message)),
      (initData) async {
        try {
          if (event.paymentMethod == 'cash' || event.paymentMethod == 'wallet') {
            add(VerifyRidePaymentEvent(
              rideId: event.rideId,
              paymentMethod: event.paymentMethod,
              paymentId: initData.paymentId ?? '',
              additionalData: {},
            ));
            return;
          }

          PaymentSuccessData? successData;

          if (event.paymentMethod == 'razorpay') {
            final completer = Completer<PaymentSuccessData?>();
            await paymentService.processRazorpayPayment(
              initData: _toGatewayInitData(initData),
              name: '',
              email: '',
              phone: '',
              onSuccess: (data) => completer.complete(data),
              onError: (err) => completer.complete(null),
            );
            successData = await completer.future;
          } else if (event.paymentMethod == 'stripe') {
            successData = await paymentService.processStripePayment(
              initData: _toGatewayInitData(initData),
              email: '',
            );
          } else if (event.paymentMethod == 'paystack') {
            successData = await paymentService.processPaystackPayment(
              initData: _toGatewayInitData(initData),
              context: event.context,
            );
          } else if (event.paymentMethod == 'flutterwave') {
            successData = await paymentService.processFlutterwavePayment(
              initData: _toGatewayInitData(initData),
              context: event.context,
            );
          } else if (event.paymentMethod == 'phonepe') {
            successData = await paymentService.processPhonePePayment(
              initData: _toGatewayInitData(initData),
              context: event.context,
            );
          } else if (event.paymentMethod == 'paytm') {
            successData = await paymentService.processPaytmPayment(
              initData: _toGatewayInitData(initData),
              context: event.context,
            );
          }

          if (successData != null) {
            add(VerifyRidePaymentEvent(
              rideId: event.rideId,
              paymentMethod: event.paymentMethod,
              paymentId: successData.paymentId,
              additionalData: {'signature': successData.signature},
            ));
          } else {
            emit(const RidePaymentError('Payment cancelled or failed'));
          }
        } catch (e) {
          emit(RidePaymentError(e.toString()));
        }
      },
    );
  }

  /// Convert ride PaymentInitData (from plugin entities) to gateway PaymentInitData
  PaymentInitData _toGatewayInitData(ride_entities.PaymentInitData initData) {
    final gatewayData = <String, dynamic>{};
    if (initData.additionalData != null) gatewayData.addAll(initData.additionalData!);
    if (initData.paymentId != null) gatewayData['payment_intent_id'] = initData.paymentId;
    if (initData.orderId != null) gatewayData['order_id'] = initData.orderId;
    if (initData.clientSecret != null) gatewayData['client_secret'] = initData.clientSecret;
    return PaymentInitData(
      orderId: 0,
      amount: 0,
      currency: 'USD',
      gatewayData: gatewayData,
      success: true,
    );
  }

  Future<void> _onVerifyPayment(
    VerifyRidePaymentEvent event,
    Emitter<RideSharingState> emit,
  ) async {
    emit(RidePaymentProcessing());
    final result = await repository.verifyRidePayment(
      rideId: event.rideId,
      paymentMethod: event.paymentMethod,
      paymentId: event.paymentId,
      additionalData: event.additionalData,
    );

    result.fold(
      (failure) => emit(RidePaymentError(failure.message)),
      (success) => emit(RidePaymentSuccess(success)),
    );
  }

  Future<void> _onLoadRideHistory(
    LoadRideHistoryEvent event,
    Emitter<RideSharingState> emit,
  ) async {
    if (event.page == 1) emit(RideSharingLoading());
    final result = await repository.getRideHistory(page: event.page);
    result.fold(
      (failure) => emit(RideSharingError(message: failure.message)),
      (historyResult) => emit(RideHistoryLoaded(
        rides: historyResult.rides,
        hasMore: historyResult.hasMore,
        currentPage: historyResult.currentPage,
      )),
    );
  }

  Future<void> _onRateRide(
    RateRideEvent event,
    Emitter<RideSharingState> emit,
  ) async {
    emit(RideSharingLoading());
    final result = await repository.rateRide(event.rideId, event.rating, event.comment);
    result.fold(
      (failure) => emit(RideSharingError(message: failure.message)),
      (_) => emit(RideRated()),
    );
  }

  Future<void> _onTriggerSOS(
    TriggerSOSEvent event,
    Emitter<RideSharingState> emit,
  ) async {
    final result = await repository.triggerSOS(event.rideId, event.lat, event.lng, event.message);
    result.fold(
      (failure) => emit(SOSError(failure.message)),
      (_) => emit(SOSTriggered()),
    );
  }
}
