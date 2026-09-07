import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/delivery_tracking_model.dart';

/// Response wrapper for delivery tracking with ETag support (SAME AS PRODUCTS)
class DeliveryTrackingResponse {
  final DeliveryTrackingModel? tracking;
  final bool notModified;
  final String? etag;

  DeliveryTrackingResponse({
    this.tracking,
    this.notModified = false,
    this.etag,
  });
}

/// Response wrapper for tracking history
class TrackingHistoryResponse {
  final int orderId;
  final List<TrackingHistoryPointModel> history;

  TrackingHistoryResponse({
    required this.orderId,
    required this.history,
  });
}

abstract class DeliveryTrackingRemoteDataSource {
  /// Get tracking data with ETag support (SAME PATTERN AS PRODUCTS)
  /// This is called every 10 seconds with ETag header
  /// Server returns 304 if no location change (90% of requests)
  Future<DeliveryTrackingResponse> getTrackingDataWithETag({
    required int orderId,
    String? currentETag,
  });

  /// Get tracking history for route replay
  Future<TrackingHistoryResponse> getTrackingHistory({
    required int orderId,
  });
}

class DeliveryTrackingRemoteDataSourceImpl implements DeliveryTrackingRemoteDataSource {
  final ApiClient _apiClient;

  DeliveryTrackingRemoteDataSourceImpl(this._apiClient);

  @override
  Future<DeliveryTrackingResponse> getTrackingDataWithETag({
    required int orderId,
    String? currentETag,
  }) async {
    // Use ETag-based request (SAME AS PRODUCTS)
    final response = await _apiClient.getWithETag<Map<String, dynamic>>(
      ApiEndpoints.deliveryTracking(orderId.toString()),
      etag: currentETag,
    );

    // If not modified, return empty with flag (SAME AS PRODUCTS)
    if (response.notModified) {
      return DeliveryTrackingResponse(
        tracking: null,
        notModified: true,
        etag: currentETag,
      );
    }

    // Parse new data
    return DeliveryTrackingResponse(
      tracking: DeliveryTrackingModel.fromJson(response.data!),
      notModified: false,
      etag: response.etag,
    );
  }

  @override
  Future<TrackingHistoryResponse> getTrackingHistory({
    required int orderId,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.deliveryTrackingHistory(orderId.toString()),
    );

    final historyData = response['history'] as List? ?? [];
    final history = historyData
        .map((e) => TrackingHistoryPointModel.fromJson(e))
        .toList();

    return TrackingHistoryResponse(
      orderId: response['order_id'] as int,
      history: history,
    );
  }
}
