import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product_model.dart';

/// Local data source for products using Hive
abstract class ProductLocalDataSource {
  Future<List<ProductModel>> getCachedProducts();
  Future<List<ProductModel>> getCachedFeaturedProducts();
  Future<ProductModel?> getCachedProduct(int id);
  Future<List<ProductModel>> getCachedProductsList({required String key});
  Future<void> cacheProducts(List<ProductModel> products);
  Future<void> cacheProductsList({
    required String key,
    required List<ProductModel> products,
  });
  Future<void> cacheFeaturedProducts(List<ProductModel> products);
  Future<void> cacheProduct(ProductModel product);
  Future<void> removeFromCache(int productId);
  Future<void> clearCache();
  Future<Duration?> getCacheAge();
  Future<String?> getCachedVersion();
  Future<void> setCachedVersion(String version);
  Future<String?> getFeaturedCachedVersion();
  Future<void> setFeaturedCachedVersion(String version);
  Future<bool> isCacheValid({Duration maxAge = const Duration(minutes: 5)});
}

class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  final SharedPreferences _prefs;
  final Box<Map> _box; // Pre-opened box injected via DI
  static const String _cacheTimestampKey = 'products_cache_timestamp';
  static const String _cacheVersionKey = 'products_cache_version';
  static const String _featuredCacheVersionKey =
      'featured_products_cache_version';
  // Sub-task 6: bumped from 'products_list_' after fixing the missing
  // product-image fallback (see ProductModel._findProductImageUrl Stage 5).
  // This cache has no age-based expiry - a cached list entry is served
  // instantly and only refreshed in the background - so any list cached
  // before that fix (with images missing) would otherwise keep being shown
  // first indefinitely. Changing the prefix makes every existing entry a
  // clean cache miss exactly once, so results are always read fresh
  // afterwards; no manual "clear app data" needed.
  static const String _productsListPrefix = 'products_list_v2_';

  ProductLocalDataSourceImpl(this._prefs, this._box);

  @override
  Future<List<ProductModel>> getCachedProducts() async {
    try {
      final products = <ProductModel>[];

      for (var key in _box.keys) {
        if (key.toString().startsWith('product_') &&
            !key.toString().contains('featured')) {
          final data = _box.get(key);
          if (data != null) {
            products.add(ProductModel.fromJson(_deepConvertMap(data)));
          }
        }
      }

      return products;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<ProductModel>> getCachedFeaturedProducts() async {
    try {
      final data = _box.get('featured_products');
      if (data != null) {
        final list = (data['items'] as List?) ?? [];
        return list.map((e) {
          // Deep convert from Map<dynamic, dynamic> to Map<String, dynamic>
          final Map<String, dynamic> converted = _deepConvertMap(e);
          return ProductModel.fromJson(converted);
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Recursively converts a map with dynamic keys into a JSON-safe map with string keys
  Map<String, dynamic> _deepConvertMap(dynamic data) {
    if (data is Map) {
      return data.map((key, value) {
        if (value is Map) {
          return MapEntry(key.toString(), _deepConvertMap(value));
        } else if (value is List) {
          return MapEntry(
            key.toString(),
            value.map((e) => e is Map ? _deepConvertMap(e) : e).toList(),
          );
        }
        return MapEntry(key.toString(), value);
      });
    }
    return {};
  }

  @override
  Future<ProductModel?> getCachedProduct(int id) async {
    try {
      final data = _box.get('product_$id');
      if (data != null) {
        return ProductModel.fromJson(_deepConvertMap(data));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<ProductModel>> getCachedProductsList({
    required String key,
  }) async {
    try {
      final meta = _box.get('$_productsListPrefix$key');
      if (meta == null) return [];
      final ids = (meta['ids'] as List?)?.cast<int>() ?? const <int>[];
      if (ids.isEmpty) return [];

      final products = <ProductModel>[];
      for (final id in ids) {
        final data = _box.get('product_$id');
        if (data == null) continue;
        products.add(ProductModel.fromJson(_deepConvertMap(data)));
      }
      return products;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> cacheProducts(List<ProductModel> products) async {
    try {
      // Cache new products
      for (var product in products) {
        await _box.put('product_${product.id}', product.toJson());
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
  Future<void> cacheProductsList({
    required String key,
    required List<ProductModel> products,
  }) async {
    try {
      final ids = <int>[];
      for (final product in products) {
        ids.add(product.id);
        await _box.put('product_${product.id}', product.toJson());
      }

      await _box.put('$_productsListPrefix$key', {
        'ids': ids,
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      // Silent fail
    }
  }

  @override
  Future<void> cacheFeaturedProducts(List<ProductModel> products) async {
    try {
      await _box.put('featured_products', {
        'items': products.map((p) => p.toJson()).toList(),
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      // Silent fail
    }
  }

  @override
  Future<void> cacheProduct(ProductModel product) async {
    try {
      await _box.put('product_${product.id}', product.toJson());
    } catch (e) {
      // Silent fail
    }
  }

  @override
  Future<void> removeFromCache(int productId) async {
    try {
      await _box.delete('product_$productId');
    } catch (e) {
      // Silent fail
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await _box.clear();
      await _prefs.remove(_cacheTimestampKey);
      await _prefs.remove(_cacheVersionKey);
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

  @override
  Future<bool> isCacheValid({
    Duration maxAge = const Duration(minutes: 5),
  }) async {
    final age = await getCacheAge();
    if (age == null) return false;
    return age < maxAge;
  }
}