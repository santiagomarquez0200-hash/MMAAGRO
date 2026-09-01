class ServerException implements Exception {
  final String message;
  final int? statusCode;
  const ServerException({required this.message, this.statusCode});
  @override
  String toString() => 'ServerException($statusCode): $message';
}

class NetworkException implements Exception {
  const NetworkException();
  @override
  String toString() => 'NetworkException: Sin conexión a internet';
}

class ErpTimeoutException implements Exception {
  final String message;
  const ErpTimeoutException({this.message = 'El servidor tardó demasiado en responder'});
  @override
  String toString() => 'ErpTimeoutException: $message';
}

class CacheException implements Exception {
  final String message;
  const CacheException({required this.message});
  @override
  String toString() => 'CacheException: $message';
}

class AuthException implements Exception {
  final String message;
  const AuthException({required this.message});
  @override
  String toString() => 'AuthException: $message';
}

class ValidationException implements Exception {
  final String message;
  const ValidationException({required this.message});
  @override
  String toString() => 'ValidationException: $message';
}

class ConflictException implements Exception {
  final String message;
  final Map<String, dynamic>? serverData;
  const ConflictException({required this.message, this.serverData});
  @override
  String toString() => 'ConflictException: $message';
}
