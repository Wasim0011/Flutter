abstract class AppException implements Exception {
  final String message;
  final int? statusCode;

  AppException({required this.message, this.statusCode});

  @override
  String toString() => message;
}

class ServerException extends AppException {
  ServerException({required super.message, super.statusCode});
}

class NetworkException extends AppException {
  NetworkException({required super.message});
}

class CacheException extends AppException {
  CacheException({required super.message});
}

class UnauthorizedException extends AppException {
  UnauthorizedException({required super.message});
}

class ValidationException extends AppException {
  final Map<String, List<String>>? errors;

  ValidationException({required super.message, this.errors});
}
