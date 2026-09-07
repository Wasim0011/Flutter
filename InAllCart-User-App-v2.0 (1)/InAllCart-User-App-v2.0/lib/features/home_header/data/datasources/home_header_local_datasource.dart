import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/home_header_config_model.dart';

abstract class HomeHeaderLocalDataSource {
  Future<HomeHeaderConfigModel?> getCachedConfig();
  Future<void> cacheConfig(HomeHeaderConfigModel config);
  Future<String?> getCachedVersion();
  Future<void> setCachedVersion(String version);
  Future<void> clearCache();
}

class HomeHeaderLocalDataSourceImpl implements HomeHeaderLocalDataSource {
  final SharedPreferences _prefs;
  static const String _cacheKey = 'home_header_config_v3';
  static const String _versionKey = 'home_header_version_v3';

  HomeHeaderLocalDataSourceImpl(this._prefs);

  @override
  Future<HomeHeaderConfigModel?> getCachedConfig() async {
    try {
      final jsonString = _prefs.getString(_cacheKey);
      if (jsonString == null) return null;
      
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return HomeHeaderConfigModel.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheConfig(HomeHeaderConfigModel config) async {
    try {
      final jsonString = jsonEncode(config.toJson());
      await _prefs.setString(_cacheKey, jsonString);
    } catch (e) {
      // Silent fail
    }
  }

  @override
  Future<String?> getCachedVersion() async {
    return _prefs.getString(_versionKey);
  }

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
