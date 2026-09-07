import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/ride_models.dart';
import '../../data/repositories/ride_sharing_repository.dart';

abstract class RideSharingState extends Equatable {
  const RideSharingState();
  @override
  List<Object?> get props => [];
}

class RideSharingInitial extends RideSharingState {}

class RideSharingLoading extends RideSharingState {}

class RideTypesLoaded extends RideSharingState {
  final List<VehicleTypeModel> vehicleTypes;
  final VehicleTypeModel? selectedType;
  final List<RideEstimateModel> estimates;

  const RideTypesLoaded({
    required this.vehicleTypes,
    this.selectedType,
    this.estimates = const [],
  });

  RideTypesLoaded copyWith({
    List<VehicleTypeModel>? vehicleTypes,
    VehicleTypeModel? selectedType,
    List<RideEstimateModel>? estimates,
  }) {
    return RideTypesLoaded(
      vehicleTypes: vehicleTypes ?? this.vehicleTypes,
      selectedType: selectedType ?? this.selectedType,
      estimates: estimates ?? this.estimates,
    );
  }

  @override
  List<Object?> get props => [vehicleTypes, selectedType, estimates];
}

class RideBookedSuccess extends RideSharingState {
  final RideBookingModel booking;

  const RideBookedSuccess(this.booking);

  @override
  List<Object?> get props => [booking];
}

class RideSharingError extends RideSharingState {
  final String message;

  const RideSharingError(this.message);

  @override
  List<Object?> get props => [message];
}

class RideSharingCubit extends Cubit<RideSharingState> {
  final RideSharingRepository _repository;

  RideSharingCubit(this._repository) : super(RideSharingInitial());

  Future<void> loadVehicleTypes() async {
    emit(RideSharingLoading());
    try {
      final types = await _repository.getVehicleTypes();
      emit(RideTypesLoaded(
        vehicleTypes: types,
        selectedType: types.isNotEmpty ? types.first : null,
      ));
    } catch (e) {
      emit(RideSharingError('Failed to load ride options: ${e.toString()}'));
    }
  }

  void selectVehicleType(VehicleTypeModel type) {
    if (state is RideTypesLoaded) {
      final currentState = state as RideTypesLoaded;
      emit(currentState.copyWith(selectedType: type));
    }
  }

  Future<void> fetchEstimates({
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    required double dropoffLat,
    required double dropoffLng,
    required String dropoffAddress,
  }) async {
    if (state is RideTypesLoaded) {
      final currentState = state as RideTypesLoaded;
      try {
        final estimates = await _repository.getFareEstimate(
          pickupLat: pickupLat,
          pickupLng: pickupLng,
          pickupAddress: pickupAddress,
          dropoffLat: dropoffLat,
          dropoffLng: dropoffLng,
          dropoffAddress: dropoffAddress,
        );
        emit(currentState.copyWith(estimates: estimates));
      } catch (e) {
        // Non-blocking: keep current state
      }
    }
  }

  Future<void> bookRide({
    required int vehicleTypeId,
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    required double dropoffLat,
    required double dropoffLng,
    required String dropoffAddress,
    required String paymentMethod,
    double? totalFare,
  }) async {
    emit(RideSharingLoading());
    try {
      final booking = await _repository.bookRide(
        vehicleTypeId: vehicleTypeId,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        pickupAddress: pickupAddress,
        dropoffLat: dropoffLat,
        dropoffLng: dropoffLng,
        dropoffAddress: dropoffAddress,
        paymentMethod: paymentMethod,
        totalFare: totalFare,
      );
      emit(RideBookedSuccess(booking));
    } catch (e) {
      emit(RideSharingError('Failed to book ride: ${e.toString()}'));
    }
  }
}
