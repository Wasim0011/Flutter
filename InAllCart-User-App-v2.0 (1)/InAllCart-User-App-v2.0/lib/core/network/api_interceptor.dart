import 'package:dio/dio.dart';

import '../services/storage_service.dart';

class ApiInterceptor extends Interceptor {
  final StorageService _storageService;

  ApiInterceptor(this._storageService);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storageService.getTokenAsync();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    final deviceId = _storageService.getDeviceId();
    if (deviceId != null) {
      options.headers['X-Device-ID'] = deviceId;
    }

    final location = _storageService.getLocation();
    if (location != null) {
      options.headers['X-User-Lat'] = location['lat'];
      options.headers['X-User-Lng'] = location['lng'];
    }

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      _storageService.clearAuth();
    }
    super.onError(err, handler);
  }
}
