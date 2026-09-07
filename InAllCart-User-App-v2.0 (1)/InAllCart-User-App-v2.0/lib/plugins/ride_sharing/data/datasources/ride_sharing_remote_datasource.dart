import '../../../../core/network/api_client.dart';
import '../models/ride_sharing_models.dart';
import '../../domain/entities/ride_sharing_entities.dart';

/// API endpoints owned by the ride sharing plugin.
/// Kept inside the plugin — not in the shared ApiEndpoints class.
abstract class _Endpoints {
  static const String _prefix = '/api/v1';
  static const String vehicleTypes = '$_prefix/rides/vehicle-types';
  static const String fareEstimate = '$_prefix/rides/estimate';
  static const String bookRide = '$_prefix/rides/book';
  static String rideDetails(String id) => '$_prefix/rides/$id';
  static String cancelRide(String id) => '$_prefix/rides/$id/cancel';
  static String boostFare(String id) => '$_prefix/rides/$id/boost-fare';
  static String trackRide(String id) => '$_prefix/rides/$id/track';
  static String rateRide(String id) => '$_prefix/rides/$id/rate';
  static String triggerSOS(String id) => '$_prefix/rides/$id/sos';
  static const String rideHistory = '$_prefix/rides/history';
  static const String paymentMethods = '$_prefix/rides/payment/methods';
  static const String paymentInitialize = '$_prefix/rides/payment/initialize';
  static const String paymentVerify = '$_prefix/rides/payment/verify';
}

abstract class RideSharingRemoteDataSource {
  Future<List<VehicleTypeModel>> getVehicleTypes();
  Future<List<FareEstimateModel>> getFareEstimates(Map<String, dynamic> params);
  Future<RideModel> bookRide(Map<String, dynamic> params);
  Future<RideModel> boostFare(int rideId, double boostAmount);
  Future<RideModel> getRideDetails(int rideId);
  Future<void> cancelRide(int rideId, String reason);
  Future<RideModel> trackRide(int rideId);
  Future<List<PaymentMethodInfo>> getPaymentMethods();
  Future<PaymentInitData> initializeRidePayment({
    required int rideId,
    required String paymentMethod,
    double? amount,
  });
  Future<bool> verifyRidePayment({
    required int rideId,
    required String paymentMethod,
    required String paymentId,
    Map<String, dynamic>? additionalData,
  });
  Future<Map<String, dynamic>> getRideHistory({int page = 1});
  Future<Map<String, dynamic>> rateRide(int rideId, int rating, String? comment);
  Future<void> triggerSOS(int rideId, double latitude, double longitude, String? message);
}

class RideSharingRemoteDataSourceImpl implements RideSharingRemoteDataSource {
  final ApiClient apiClient;

  RideSharingRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<VehicleTypeModel>> getVehicleTypes() async {
    final response = await apiClient.get(_Endpoints.vehicleTypes);
    final data = response['data'] as List;
    return data.map((json) => VehicleTypeModel.fromJson(json)).toList();
  }

  @override
  Future<List<FareEstimateModel>> getFareEstimates(Map<String, dynamic> params) async {
    final response = await apiClient.post(_Endpoints.fareEstimate, data: params);
    final responseData = response['data'];
    final polyline = responseData['polyline'] as String?;

    if (responseData['estimates'] is List) {
      final data = responseData['estimates'] as List;
      return data.map((json) => FareEstimateModel.fromJson(json, polyline: polyline)).toList();
    } else if (responseData['estimate'] != null) {
      return [FareEstimateModel.fromJson(responseData['estimate'], polyline: polyline)];
    } else {
      return [];
    }
  }

  @override
  Future<RideModel> bookRide(Map<String, dynamic> params) async {
    final response = await apiClient.post(_Endpoints.bookRide, data: params);
    final rideJson = response['data']['ride'];
    final driverJson = response['data']['driver'];
    if (driverJson != null) {
      rideJson['driver'] = driverJson;
    }
    return RideModel.fromJson(rideJson);
  }

  @override
  Future<RideModel> getRideDetails(int rideId) async {
    final response = await apiClient.get(_Endpoints.rideDetails(rideId.toString()));
    return RideModel.fromJson(response['data']);
  }

  @override
  Future<void> cancelRide(int rideId, String reason) async {
    await apiClient.post(
      _Endpoints.cancelRide(rideId.toString()),
      data: {'cancellation_reason': reason},
    );
  }

  @override
  Future<RideModel> trackRide(int rideId) async {
    final response = await apiClient.get(_Endpoints.trackRide(rideId.toString()));
    final data = response['data'];
    final rideJson = data['ride'];

    if (data['driver_location'] != null && rideJson['driver'] != null) {
      rideJson['driver']['latitude'] = data['driver_location']['latitude'];
      rideJson['driver']['longitude'] = data['driver_location']['longitude'];
    }

    return RideModel.fromJson(rideJson);
  }

  @override
  Future<List<PaymentMethodInfo>> getPaymentMethods() async {
    final response = await apiClient.get(_Endpoints.paymentMethods);
    final data = response['data'] as List;
    return data.map((e) => PaymentMethodInfo.fromJson(e)).toList();
  }

  @override
  Future<PaymentInitData> initializeRidePayment({
    required int rideId,
    required String paymentMethod,
    double? amount,
  }) async {
    final response = await apiClient.post(_Endpoints.paymentInitialize, data: {
      'ride_id': rideId,
      'payment_gateway': paymentMethod,
      if (amount != null) 'amount': amount,
    });
    return PaymentInitData.fromJson(response);
  }

  @override
  Future<bool> verifyRidePayment({
    required int rideId,
    required String paymentMethod,
    required String paymentId,
    Map<String, dynamic>? additionalData,
  }) async {
    final response = await apiClient.post(_Endpoints.paymentVerify, data: {
      'ride_id': rideId,
      'payment_gateway': paymentMethod,
      'transaction_id': paymentId,
      ...?additionalData,
    });
    return response['success'] == true;
  }

  @override
  Future<Map<String, dynamic>> getRideHistory({int page = 1}) async {
    final response = await apiClient.get(
      '${_Endpoints.rideHistory}?page=$page',
    );
    return response;
  }

  @override
  Future<Map<String, dynamic>> rateRide(int rideId, int rating, String? comment) async {
    final response = await apiClient.post(
      _Endpoints.rateRide(rideId.toString()),
      data: {
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
    );
    return response;
  }

  @override
  Future<void> triggerSOS(int rideId, double latitude, double longitude, String? message) async {
    await apiClient.post(
      _Endpoints.triggerSOS(rideId.toString()),
      data: {
        'latitude': latitude,
        'longitude': longitude,
        if (message != null && message.isNotEmpty) 'message': message,
      },
    );
  }

  @override
  Future<RideModel> boostFare(int rideId, double boostAmount) async {
    final response = await apiClient.post(
      _Endpoints.boostFare(rideId.toString()),
      data: {'boost_amount': boostAmount},
    );
    final rideJson = response['data']['ride'];
    return RideModel.fromJson(rideJson);
  }
}
