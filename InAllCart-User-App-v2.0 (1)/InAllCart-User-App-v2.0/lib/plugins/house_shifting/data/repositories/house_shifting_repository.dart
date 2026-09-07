import '../../../../core/network/api_client.dart';
import '../models/addon_service_model.dart';
import '../models/item_category_model.dart';
import '../models/service_type_model.dart';

/// Repository for all House Shifting backend API calls.
///
/// Endpoints consumed (from routes/api.php):
///   Public (no auth):
///     GET  /api/v1/shifting/service-types
///     GET  /api/v1/shifting/items
///     GET  /api/v1/shifting/addons
///   Customer (auth:sanctum):
///     POST /api/v1/shifting/estimate
///     POST /api/v1/shifting/orders
///     GET  /api/v1/shifting/orders
///     GET  /api/v1/shifting/orders/{id}
///     POST /api/v1/shifting/orders/{id}/cancel
///     GET  /api/v1/shifting/orders/{id}/track
///     POST /api/v1/shifting/payment/initialize
///     POST /api/v1/shifting/payment/verify
class HouseShiftingRepository {
  final ApiClient _apiClient;

  HouseShiftingRepository(this._apiClient);

  // ── Public endpoints ─────────────────────────────────────────────────────

  Future<List<ServiceTypeModel>> getServiceTypes() async {
    return await _apiClient.get<List<ServiceTypeModel>>(
      '/api/v1/shifting/service-types',
      parser: (data) {
        if (data is Map &&
            data['success'] == true &&
            data['service_types'] is List) {
          return (data['service_types'] as List)
              .map(
                (json) =>
                    ServiceTypeModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();
        }
        return [];
      },
    );
  }

  Future<List<ItemCategoryModel>> getItemCategories() async {
    return await _apiClient.get<List<ItemCategoryModel>>(
      '/api/v1/shifting/items',
      parser: (data) {
        if (data is Map &&
            data['success'] == true &&
            data['categories'] is List) {
          return (data['categories'] as List)
              .map(
                (json) =>
                    ItemCategoryModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();
        }
        return [];
      },
    );
  }

  Future<List<AddonServiceModel>> getAddons() async {
    return await _apiClient.get<List<AddonServiceModel>>(
      '/api/v1/shifting/addons',
      parser: (data) {
        if (data is Map && data['success'] == true && data['addons'] is List) {
          return (data['addons'] as List)
              .map(
                (json) =>
                    AddonServiceModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();
        }
        return [];
      },
    );
  }

  // ── Authenticated endpoints ──────────────────────────────────────────────

  /// POST /api/v1/shifting/estimate
  /// Returns pricing estimates for all (or one) service types.
  Future<Map<String, dynamic>> getEstimate({
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    int pickupFloor = 0,
    bool pickupLiftAvailable = false,
    int dropoffFloor = 0,
    bool dropoffLiftAvailable = false,
    List<Map<String, dynamic>> items = const [],
    List<int> addonIds = const [],
    int helperCount = 0,
    int? serviceTypeId,
  }) async {
    final body = <String, dynamic>{
      'pickup_latitude': pickupLat,
      'pickup_longitude': pickupLng,
      'dropoff_latitude': dropoffLat,
      'dropoff_longitude': dropoffLng,
      'pickup_floor': pickupFloor,
      'pickup_lift_available': pickupLiftAvailable,
      'dropoff_floor': dropoffFloor,
      'dropoff_lift_available': dropoffLiftAvailable,
      'items': items,
      'addon_ids': addonIds,
      'helper_count': helperCount,
    };
    if (serviceTypeId != null) {
      body['service_type_id'] = serviceTypeId;
    }

    return await _apiClient.post<Map<String, dynamic>>(
      '/api/v1/shifting/estimate',
      data: body,
      parser: (data) => data as Map<String, dynamic>,
    );
  }

  /// POST /api/v1/shifting/orders — Create a booking
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
    List<int>? addonIds,
    int helperCount = 0,
    String? promoCode,
    String? specialInstructions,
    String? scheduledAt,
    List<Map<String, dynamic>>? stops,
  }) async {
    final body = <String, dynamic>{
      'service_type_id': serviceTypeId,
      'pickup_address': pickupAddress,
      'pickup_latitude': pickupLat,
      'pickup_longitude': pickupLng,
      'pickup_floor': pickupFloor,
      'pickup_lift_available': pickupLiftAvailable,
      'dropoff_address': dropoffAddress,
      'dropoff_latitude': dropoffLat,
      'dropoff_longitude': dropoffLng,
      'dropoff_floor': dropoffFloor,
      'dropoff_lift_available': dropoffLiftAvailable,
      'items': items,
      'payment_method': paymentMethod,
      'helper_count': helperCount,
    };
    if (addonIds != null) body['addon_ids'] = addonIds;
    if (promoCode != null) body['promo_code'] = promoCode;
    if (specialInstructions != null) {
      body['special_instructions'] = specialInstructions;
    }
    if (scheduledAt != null) body['scheduled_at'] = scheduledAt;
    if (stops != null) body['stops'] = stops;

    return await _apiClient.post<Map<String, dynamic>>(
      '/api/v1/shifting/orders',
      data: body,
      parser: (data) => data as Map<String, dynamic>,
    );
  }

  /// GET /api/v1/shifting/orders — List customer orders
  Future<Map<String, dynamic>> getOrders({int page = 1}) async {
    return await _apiClient.get<Map<String, dynamic>>(
      '/api/v1/shifting/orders',
      queryParameters: {'page': page},
      parser: (data) => data as Map<String, dynamic>,
    );
  }

  /// GET /api/v1/shifting/orders/{id} — Order detail
  Future<Map<String, dynamic>> getOrderDetail(int orderId) async {
    return await _apiClient.get<Map<String, dynamic>>(
      '/api/v1/shifting/orders/$orderId',
      parser: (data) => data as Map<String, dynamic>,
    );
  }

  /// POST /api/v1/shifting/orders/{id}/cancel
  Future<Map<String, dynamic>> cancelOrder(int orderId, String reason) async {
    return await _apiClient.post<Map<String, dynamic>>(
      '/api/v1/shifting/orders/$orderId/cancel',
      data: {'reason': reason},
      parser: (data) => data as Map<String, dynamic>,
    );
  }

  /// GET /api/v1/shifting/orders/{id}/track
  Future<Map<String, dynamic>> trackOrder(int orderId) async {
    return await _apiClient.get<Map<String, dynamic>>(
      '/api/v1/shifting/orders/$orderId/track',
      parser: (data) => data as Map<String, dynamic>,
    );
  }

  // ── Payment endpoints ────────────────────────────────────────────────────

  /// POST /api/v1/shifting/payment/initialize
  /// Initialize Razorpay payment for an order.
  Future<Map<String, dynamic>> initializePayment(int orderId) async {
    return await _apiClient.post<Map<String, dynamic>>(
      '/api/v1/shifting/payment/initialize',
      data: {'order_id': orderId},
      parser: (data) => data as Map<String, dynamic>,
    );
  }

  /// POST /api/v1/shifting/payment/verify
  /// Verify Razorpay payment signature.
  Future<Map<String, dynamic>> verifyPayment({
    required int orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    return await _apiClient.post<Map<String, dynamic>>(
      '/api/v1/shifting/payment/verify',
      data: {
        'order_id': orderId,
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
      },
      parser: (data) => data as Map<String, dynamic>,
    );
  }
}
