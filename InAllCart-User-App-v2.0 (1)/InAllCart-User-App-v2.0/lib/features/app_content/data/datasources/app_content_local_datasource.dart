import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_content_model.dart';

abstract class AppContentLocalDataSource {
  Future<List<AppContentModel>?> getCachedContent(int? tabId);
  Future<void> cacheContent(int? tabId, List<AppContentModel> contents);
  Future<String?> getCachedVersion(int? tabId);
  Future<void> setCachedVersion(int? tabId, String version);
  Future<void> clearCache();
}

class AppContentLocalDataSourceImpl implements AppContentLocalDataSource {
  final SharedPreferences _prefs;
  static const String _cacheKeyPrefix = 'app_content_';
  static const String _versionKeyPrefix = 'app_content_version_';

  AppContentLocalDataSourceImpl(this._prefs);

  String _getCacheKey(int? tabId) => '$_cacheKeyPrefix${tabId ?? 'all'}';
  String _getVersionKey(int? tabId) => '$_versionKeyPrefix${tabId ?? 'all'}';

  @override
  Future<List<AppContentModel>?> getCachedContent(int? tabId) async {
    try {
      final jsonString = _prefs.getString(_getCacheKey(tabId));
      if (jsonString == null) return null;
      
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => AppContentModel.fromJson(json)).toList();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheContent(int? tabId, List<AppContentModel> contents) async {
    try {
      final jsonList = contents.map((c) => c.toJson()).toList();
      await _prefs.setString(_getCacheKey(tabId), jsonEncode(jsonList));
    } catch (e) {
      // Silent fail
    }
  }

  @override
  Future<String?> getCachedVersion(int? tabId) async {
    return _prefs.getString(_getVersionKey(tabId));
  }

  @override
  Future<void> setCachedVersion(int? tabId, String version) async {
    await _prefs.setString(_getVersionKey(tabId), version);
  }

  @override
  Future<void> clearCache() async {
    final keys = _prefs.getKeys().where((k) => k.startsWith(_cacheKeyPrefix) || k.startsWith(_versionKeyPrefix));
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }
}
