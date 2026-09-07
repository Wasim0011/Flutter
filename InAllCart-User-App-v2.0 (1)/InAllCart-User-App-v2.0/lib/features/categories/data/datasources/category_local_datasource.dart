import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/category_model.dart';

/// Local data source for categories using Hive
abstract class CategoryLocalDataSource {
  Future<List<CategoryModel>> getCachedCategories();
  Future<List<CategoryModel>> getCachedFeaturedCategories();
  Future<CategoryModel?> getCachedCategory(int id);
  Future<void> cacheCategories(List<CategoryModel> categories);
  Future<void> cacheFeaturedCategories(List<CategoryModel> categories);
  Future<void> cacheCategory(CategoryModel category);
  Future<void> clearCache();
  Future<Duration?> getCacheAge();
  Future<bool> isCacheValid({Duration maxAge = const Duration(hours: 1)});
  Future<String?> getCachedVersion();
  Future<void> setCachedVersion(String version);
  Future<String?> getFeaturedCachedVersion();
  Future<void> setFeaturedCachedVersion(String version);
}

class CategoryLocalDataSourceImpl implements CategoryLocalDataSource {
  final SharedPreferences _prefs;
  final Box<Map> _box; // Pre-opened box injected via DI
  static const String _cacheTimestampKey = 'categories_cache_timestamp';
  static const String _cacheVersionKey = 'categories_cache_version';
  static const String _featuredCacheVersionKey = 'featured_categories_cache_version';

  CategoryLocalDataSourceImpl(this._prefs, this._box);

  @override
  Future<List<CategoryModel>> getCachedCategories() async {
    try {
      final categories = <CategoryModel>[];
      
      for (var key in _box.keys) {
        if (key.toString().startsWith('category_') && !key.toString().contains('featured')) {
          final data = _box.get(key);
          if (data != null) {
            categories.add(CategoryModel.fromJson(_deepConvertMap(data)));
          }
        }
      }
      
      // Sort by sort_order
      categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return categories;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<CategoryModel>> getCachedFeaturedCategories() async {
    try {
      final data = _box.get('featured_categories');
      if (data != null) {
        final list = (data['items'] as List?) ?? [];
        return list.map((e) {
          // Deep convert from Map<dynamic, dynamic> to Map<String, dynamic>
          final Map<String, dynamic> converted = _deepConvertMap(e);
          return CategoryModel.fromJson(converted);
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
  
  /// Recursively converts `Map<dynamic, dynamic>` to `Map<String, dynamic>`
  Map<String, dynamic> _deepConvertMap(dynamic data) {
    if (data is Map) {
      return data.map((key, value) {
        if (value is Map) {
          return MapEntry(key.toString(), _deepConvertMap(value));
        } else if (value is List) {
          return MapEntry(key.toString(), value.map((e) => e is Map ? _deepConvertMap(e) : e).toList());
        }
        return MapEntry(key.toString(), value);
      });
    }
    return {};
  }

  @override
  Future<CategoryModel?> getCachedCategory(int id) async {
    try {
      final data = _box.get('category_$id');
      if (data != null) {
        return CategoryModel.fromJson(_deepConvertMap(data));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheCategories(List<CategoryModel> categories) async {
    try {
      // Clear old categories
      final keysToDelete = _box.keys
          .where((key) => key.toString().startsWith('category_') && !key.toString().contains('featured'))
          .toList();
      for (var key in keysToDelete) {
        await _box.delete(key);
      }
      
      // Cache new categories
      for (var category in categories) {
        await _box.put('category_${category.id}', category.toJson());
      }
      
      // Update timestamp
      await _prefs.setInt(
        _cacheTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      // Silent fail
    }
  }

  @override
  Future<void> cacheFeaturedCategories(List<CategoryModel> categories) async {
    try {
      await _box.put('featured_categories', {
        'items': categories.map((c) => c.toJson()).toList(),
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      // Silent fail
    }
  }

  @override
  Future<void> cacheCategory(CategoryModel category) async {
    try {
      await _box.put('category_${category.id}', category.toJson());
    } catch (e) {
      // Silent fail
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await _box.clear();
      await _prefs.remove(_cacheTimestampKey);
    } catch (e) {
      // Silent fail
    }
  }

  @override
  Future<Duration?> getCacheAge() async {
    final timestamp = _prefs.getInt(_cacheTimestampKey);
    if (timestamp == null) return null;
    
    final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(cachedAt);
  }

  @override
  Future<bool> isCacheValid({Duration maxAge = const Duration(hours: 1)}) async {
    final age = await getCacheAge();
    if (age == null) return false;
    return age < maxAge;
  }

  @override
  Future<String?> getCachedVersion() async {
    return _prefs.getString(_cacheVersionKey);
  }

  @override
  Future<void> setCachedVersion(String version) async {
    await _prefs.setString(_cacheVersionKey, version);
  }

  @override
  Future<String?> getFeaturedCachedVersion() async {
    return _prefs.getString(_featuredCacheVersionKey);
  }

  @override
  Future<void> setFeaturedCachedVersion(String version) async {
    await _prefs.setString(_featuredCacheVersionKey, version);
  }
}
