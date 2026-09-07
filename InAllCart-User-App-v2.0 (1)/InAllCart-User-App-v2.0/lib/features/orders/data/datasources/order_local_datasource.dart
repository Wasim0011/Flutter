import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order_model.dart';

abstract class OrderLocalDataSource {
  Future<List<OrderModel>?> getCachedOrders();
  Future<void> cacheOrders(List<OrderModel> orders);
  Future<String?> getCachedVersion();
  Future<void> setCachedVersion(String version);
  Future<void> clearCache();
}

class OrderLocalDataSourceImpl implements OrderLocalDataSource {
  final SharedPreferences _prefs;
  static const _cacheKey = 'orders_cache';
  static const _versionKey = 'orders_version';

  OrderLocalDataSourceImpl(this._prefs);

  @override
  Future<List<OrderModel>?> getCachedOrders() async {
    final json = _prefs.getString(_cacheKey);
    if (json == null) return null;
    
    try {
      final list = jsonDecode(json) as List;
      return list.map((e) => OrderModel.fromJson(e)).toList();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheOrders(List<OrderModel> orders) async {
    final json = jsonEncode(orders.map((e) => e.toJson()).toList());
    await _prefs.setString(_cacheKey, json);
  }

  @override
  Future<String?> getCachedVersion() async => _prefs.getString(_versionKey);

  @override
  Future<void> setCachedVersion(String version) async {
    await _prefs.setString(_versionKey, version);
  }

  @override
  Future<void> clearCache() async {
    await _prefs.remove(_cacheKey);
    await _prefs.remove(_versionKey);
  }
}
