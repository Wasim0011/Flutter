import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/address.dart';
import '../../domain/repositories/address_repository.dart';

// Events
abstract class AddressEvent extends Equatable {
  const AddressEvent();

  @override
  List<Object?> get props => [];
}

class LoadAddresses extends AddressEvent {}

class SelectAddress extends AddressEvent {
  final Address address;
  const SelectAddress(this.address);

  @override
  List<Object?> get props => [address];
}

class AddAddressEvent extends AddressEvent {
  final Map<String, dynamic> data;
  const AddAddressEvent(this.data);

  @override
  List<Object?> get props => [data];
}

class UpdateAddressEvent extends AddressEvent {
  final int id;
  final Map<String, dynamic> data;
  const UpdateAddressEvent(this.id, this.data);

  @override
  List<Object?> get props => [id, data];
}

class DeleteAddressEvent extends AddressEvent {
  final int id;
  const DeleteAddressEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class SetDefaultAddressEvent extends AddressEvent {
  final int id;
  const SetDefaultAddressEvent(this.id);

  @override
  List<Object?> get props => [id];
}

// States
abstract class AddressState extends Equatable {
  final List<Address> addresses;
  final Address? selectedAddress;

  const AddressState({
    this.addresses = const [],
    this.selectedAddress,
  });

  @override
  List<Object?> get props => [addresses, selectedAddress];
}

class AddressInitial extends AddressState {}

class AddressLoading extends AddressState {
  const AddressLoading({super.addresses, super.selectedAddress});
}

class AddressLoaded extends AddressState {
  const AddressLoaded({
    required super.addresses,
    super.selectedAddress,
  });
}

class AddressError extends AddressState {
  final String message;

  const AddressError({
    required this.message,
    super.addresses,
    super.selectedAddress,
  });

  @override
  List<Object?> get props => [message, addresses, selectedAddress];
}

class AddressOperationSuccess extends AddressState {
  final String message;

  const AddressOperationSuccess({
    required this.message,
    required super.addresses,
    super.selectedAddress,
  });

  @override
  List<Object?> get props => [message, addresses, selectedAddress];
}

// BLoC
class AddressBloc extends Bloc<AddressEvent, AddressState> {
  final AddressRepository _repository;

  AddressBloc(
    this._repository,
  ) : super(AddressInitial()) {
    on<LoadAddresses>(_onLoadAddresses);
    on<SelectAddress>(_onSelectAddress);
    on<AddAddressEvent>(_onAddAddress);
    on<UpdateAddressEvent>(_onUpdateAddress);
    on<DeleteAddressEvent>(_onDeleteAddress);
    on<SetDefaultAddressEvent>(_onSetDefaultAddress);
  }

  Future<void> _onLoadAddresses(
    LoadAddresses event,
    Emitter<AddressState> emit,
  ) async {
    emit(AddressLoading(
      addresses: state.addresses,
      selectedAddress: state.selectedAddress,
    ));

    final result = await _repository.getAddresses();
    
    result.fold(
      (failure) {
        emit(AddressError(
          message: failure.message,
          addresses: state.addresses,
          selectedAddress: state.selectedAddress,
        ));
      },
      (addresses) {
        // Preserve currently selected address if valid, otherwise pick default or latest address
        Address? selectedAddress = state.selectedAddress;
        if (selectedAddress != null && !addresses.any((a) => a.id == selectedAddress!.id)) {
          selectedAddress = null;
        }

        if (selectedAddress == null && addresses.isNotEmpty) {
          try {
            selectedAddress = addresses.firstWhere((addr) => addr.isDefault);
          } catch (e) {
            selectedAddress = addresses.last;
          }
        }
        
        emit(AddressLoaded(
          addresses: addresses,
          selectedAddress: selectedAddress,
        ));
      },
    );
  }

  void _onSelectAddress(SelectAddress event, Emitter<AddressState> emit) {
    emit(AddressLoaded(
      addresses: state.addresses,
      selectedAddress: event.address,
    ));
  }

  Future<void> _onAddAddress(
    AddAddressEvent event,
    Emitter<AddressState> emit,
  ) async {
    emit(AddressLoading(
      addresses: state.addresses,
      selectedAddress: state.selectedAddress,
    ));

    final result = await _repository.createAddress(event.data);
    
    result.fold(
      (failure) {
        emit(AddressError(
          message: failure.message,
          addresses: state.addresses,
          selectedAddress: state.selectedAddress,
        ));
      },
      (newAddress) {
        final updatedAddresses = [...state.addresses, newAddress];
        emit(AddressOperationSuccess(
          message: 'Address added successfully',
          addresses: updatedAddresses,
          selectedAddress: newAddress,
        ));
        
        // Reload addresses
        add(LoadAddresses());
      },
    );
  }

  Future<void> _onUpdateAddress(
    UpdateAddressEvent event,
    Emitter<AddressState> emit,
  ) async {
    emit(AddressLoading(
      addresses: state.addresses,
      selectedAddress: state.selectedAddress,
    ));

    final result = await _repository.updateAddress(event.id, event.data);
    
    result.fold(
      (failure) {
        emit(AddressError(
          message: failure.message,
          addresses: state.addresses,
          selectedAddress: state.selectedAddress,
        ));
      },
      (_) {
        emit(AddressOperationSuccess(
          message: 'Address updated successfully',
          addresses: state.addresses,
          selectedAddress: state.selectedAddress,
        ));
        
        // Reload addresses
        add(LoadAddresses());
      },
    );
  }

  Future<void> _onDeleteAddress(
    DeleteAddressEvent event,
    Emitter<AddressState> emit,
  ) async {
    emit(AddressLoading(
      addresses: state.addresses,
      selectedAddress: state.selectedAddress,
    ));

    final result = await _repository.deleteAddress(event.id);
    
    result.fold(
      (failure) {
        emit(AddressError(
          message: failure.message,
          addresses: state.addresses,
          selectedAddress: state.selectedAddress,
        ));
      },
      (_) {
        emit(AddressOperationSuccess(
          message: 'Address deleted successfully',
          addresses: state.addresses,
          selectedAddress: state.selectedAddress,
        ));
        
        // Reload addresses
        add(LoadAddresses());
      },
    );
  }

  Future<void> _onSetDefaultAddress(
    SetDefaultAddressEvent event,
    Emitter<AddressState> emit,
  ) async {
    emit(AddressLoading(
      addresses: state.addresses,
      selectedAddress: state.selectedAddress,
    ));

    final result = await _repository.setDefaultAddress(event.id);
    
    result.fold(
      (failure) {
        emit(AddressError(
          message: failure.message,
          addresses: state.addresses,
          selectedAddress: state.selectedAddress,
        ));
      },
      (_) {
        emit(AddressOperationSuccess(
          message: 'Default address updated',
          addresses: state.addresses,
          selectedAddress: state.selectedAddress,
        ));
        
        // Reload addresses
        add(LoadAddresses());
      },
    );
  }
}
