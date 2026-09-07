import 'package:dio/dio.dart';

import '../error/exceptions.dart';

/// Response wrapper that includes ETag information
class ApiResponse<T> {
  final T? data;
  final bool notModified;
  final String? etag;
  
  ApiResponse({this.data, this.notModified = false, this.etag});
}

class ApiClient {
  final Dio _dio;

  ApiClient(this._dio);

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? parser,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return _handleResponse(response, parser);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// GET request with ETag support for cache validation
  /// Returns ApiResponse with notModified=true if server returns 304
  Future<ApiResponse<T>> getWithETag<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    String? etag,
    T Function(dynamic)? parser,
  }) async {
    try {
      final options = Options(
        headers: etag != null ? {'If-None-Match': etag} : null,
        validateStatus: (status) => status != null && (status < 300 || status == 304),
      );
      
      final response = await _dio.get(
        path, 
        queryParameters: queryParameters,
        options: options,
      );
      
      // Handle 304 Not Modified
      if (response.statusCode == 304) {
        return ApiResponse<T>(
          data: null,
          notModified: true,
          etag: etag, // Keep the same ETag
        );
      }
      
      // Extract ETag from response headers first, then fallback to meta.version in body
      String? responseETag = response.headers.value('etag');
      
      // Fallback: try to get version from response body meta
      if (responseETag == null && response.data is Map) {
        final meta = response.data['meta'];
        if (meta is Map && meta['version'] != null) {
          responseETag = meta['version'].toString();
        }
      }
      
      final data = parser != null 
          ? parser(response.data) 
          : response.data as T;
      
      return ApiResponse<T>(
        data: data,
        notModified: false,
        etag: responseETag,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? parser,
  }) async {
    try {
      final response = await _dio.post(path, data: data, queryParameters: queryParameters);
      return _handleResponse(response, parser);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<T> put<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? parser,
  }) async {
    try {
      final response = await _dio.put(path, data: data);
      return _handleResponse(response, parser);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<T> delete<T>(String path, {T Function(dynamic)? parser}) async {
    try {
      final response = await _dio.delete(path);
      return _handleResponse(response, parser);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  T _handleResponse<T>(Response response, T Function(dynamic)? parser) {
    if (response.statusCode! >= 200 && response.statusCode! < 300) {
      if (parser != null) {
        return parser(response.data);
      }
      return response.data as T;
    }
    throw ServerException(message: 'Server error: ${response.statusCode}');
  }

  AppException _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(message: 'Connection timeout');
      case DioExceptionType.connectionError:
        return NetworkException(message: 'No internet connection');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 0;
        final message = e.response?.data?['message'] ?? 'Server error';
        if (statusCode == 401) {
          return UnauthorizedException(message: message);
        }
        return ServerException(message: message, statusCode: statusCode);
      default:
        return ServerException(message: e.message ?? 'Unknown error');
    }
  }
}
