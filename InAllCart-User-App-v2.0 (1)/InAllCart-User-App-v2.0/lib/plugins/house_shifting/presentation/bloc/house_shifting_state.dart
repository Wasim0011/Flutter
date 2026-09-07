import 'package:equatable/equatable.dart';
import '../../data/models/addon_service_model.dart';
import '../../data/models/item_category_model.dart';
import '../../data/models/service_type_model.dart';

abstract class HouseShiftingState extends Equatable {
  const HouseShiftingState();

  @override
  List<Object?> get props => [];
}

class HouseShiftingInitial extends HouseShiftingState {}

class HouseShiftingLoading extends HouseShiftingState {}

class HouseShiftingLoaded extends HouseShiftingState {
  final List<ServiceTypeModel> serviceTypes;
  final List<ItemCategoryModel> itemCategories;
  final List<AddonServiceModel> addons;

  const HouseShiftingLoaded({
    required this.serviceTypes,
    required this.itemCategories,
    required this.addons,
  });

  @override
  List<Object?> get props => [serviceTypes, itemCategories, addons];
}

class HouseShiftingError extends HouseShiftingState {
  final String message;

  const HouseShiftingError(this.message);

  @override
  List<Object?> get props => [message];
}
