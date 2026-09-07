import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/addon_service_model.dart';
import '../../data/models/item_category_model.dart';
import '../../data/models/service_type_model.dart';
import '../../data/repositories/house_shifting_repository.dart';
import 'house_shifting_state.dart';

class HouseShiftingCubit extends Cubit<HouseShiftingState> {
  final HouseShiftingRepository _repository;

  HouseShiftingCubit(this._repository) : super(HouseShiftingInitial());

  Future<void> loadData() async {
    try {
      emit(HouseShiftingLoading());

      // Fetch all 3 public endpoints in parallel
      final results = await Future.wait([
        _repository.getServiceTypes(),
        _repository.getItemCategories(),
        _repository.getAddons(),
      ]);

      final serviceTypes = results[0] as List<ServiceTypeModel>;
      final itemCategories = results[1] as List<ItemCategoryModel>;
      final addons = results[2] as List<AddonServiceModel>;

      emit(
        HouseShiftingLoaded(
          serviceTypes: serviceTypes,
          itemCategories: itemCategories,
          addons: addons,
        ),
      );
    } catch (e) {
      emit(HouseShiftingError(e.toString()));
    }
  }

  Future<Map<String, dynamic>> getOrders({int page = 1}) async {
    return await _repository.getOrders(page: page);
  }

  Future<Map<String, dynamic>> getOrderDetail(int orderId) async {
    return await _repository.getOrderDetail(orderId);
  }

  Future<Map<String, dynamic>> cancelOrder(int orderId, String reason) async {
    return await _repository.cancelOrder(orderId, reason);
  }

  Future<Map<String, dynamic>> createOrder({
    required int serviceTypeId,
    required String pickupAddress,
    required double pickupLat,
    required double pickupLng,
    required String dropoffAddress,
    required double dropoffLat,
    required double dropoffLng,
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    int pickupFloor = 0,
    bool pickupLiftAvailable = false,
    int dropoffFloor = 0,
    bool dropoffLiftAvailable = false,
    List<int> addonIds = const [],
    int helperCount = 0,
    String? promoCode,
    String? specialInstructions,
  }) async {
    return await _repository.createOrder(
      serviceTypeId: serviceTypeId,
      pickupAddress: pickupAddress,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      dropoffAddress: dropoffAddress,
      dropoffLat: dropoffLat,
      dropoffLng: dropoffLng,
      items: items,
      paymentMethod: paymentMethod,
      pickupFloor: pickupFloor,
      pickupLiftAvailable: pickupLiftAvailable,
      dropoffFloor: dropoffFloor,
      dropoffLiftAvailable: dropoffLiftAvailable,
      addonIds: addonIds,
      helperCount: helperCount,
      promoCode: promoCode,
      specialInstructions: specialInstructions,
    );
  }

  Future<Map<String, dynamic>> getEstimate({
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    required List<int> addonIds,
    required int serviceTypeId,
    int pickupFloor = 0,
    bool pickupLiftAvailable = false,
    int dropoffFloor = 0,
    bool dropoffLiftAvailable = false,
    List<Map<String, dynamic>> items = const [],
    int helperCount = 0,
  }) async {
    return await _repository.getEstimate(
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      dropoffLat: dropoffLat,
      dropoffLng: dropoffLng,
      pickupFloor: pickupFloor,
      pickupLiftAvailable: pickupLiftAvailable,
      dropoffFloor: dropoffFloor,
      dropoffLiftAvailable: dropoffLiftAvailable,
      addonIds: addonIds,
      serviceTypeId: serviceTypeId,
      items: items,
      helperCount: helperCount,
    );
  }
}
