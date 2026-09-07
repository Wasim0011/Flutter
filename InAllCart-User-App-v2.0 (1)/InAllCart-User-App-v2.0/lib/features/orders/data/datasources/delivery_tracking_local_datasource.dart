import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/delivery_tracking_model.dart';

/// Local data source for delivery tracking (SAME PATTERN AS PRODUCTS)
/// Uses Hive for data storage and SharedPreferences for ETag versioning
abstract class DeliveryTrackingLocalDataSource {
  /// Cache tracking data for an order
  Future<void> cacheTrackingData(int orderId, DeliveryTrackingModel tracking);

  /// Get cached tracking data for an order
  Future<DeliveryTrackingModel?> getCachedTrackingData(int orderId);

  /// Get cached ETag version for an order
  Future<String?> getCachedVersion(int orderId);

  /// Set cached ETag version for an order
  Future<void> setCachedVersion(int orderId, String etag);

  /// Clear tracking cache for an order
  Future<void> clearTrackingCache(int orderId);

  /// Clear all tracking caches
  Future<void> clearAllTrackingCaches();
}

class DeliveryTrackingLocalDataSourceImpl implements DeliveryTrackingLocalDataSource {
  final SharedPreferences _prefs;
  final Box<Map<dynamic, dynamic>> _trackingBox;

  DeliveryTrackingLocalDataSourceImpl(this._prefs, this._trackingBox);

  static const String _versionPrefix = 'tracking_version_';

  @override
  Future<void> cacheTrackingData(int orderId, DeliveryTrackingModel tracking) async {
    await _trackingBox.put(orderId.toString(), tracking.toJson());
  }

  @override
  Future<DeliveryTrackingModel?> getCachedTrackingData(int orderId) async {
    final data = _trackingBox.get(orderId.toString());
    if (data == null) return null;

    try {
      return DeliveryTrackingModel.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      // Invalid cache data - clear it
      await clearTrackingCache(orderId);
      return null;
    }
  }

  @override
  Future<String?> getCachedVersion(int orderId) async {
    return _prefs.getString('$_versionPrefix$orderId');
  }

  @override
  Future<void> setCachedVersion(int orderId, String etag) async {
    await _prefs.setString('$_versionPrefix$orderId', etag);
  }

  @override
  Future<void> clearTrackingCache(int orderId) async {
    await _trackingBox.delete(orderId.toString());
    await _prefs.remove('$_versionPrefix$orderId');
  }

  @override
  Future<void> clearAllTrackingCaches() async {
    await _trackingBox.clear();
    
    // Clear all version keys
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_versionPrefix)) {
        await _prefs.remove(key);
      }
    }
  }
}
