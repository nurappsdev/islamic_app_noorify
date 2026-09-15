// Low-level errors thrown inside the data layer (datasources).
// Repositories catch these and translate them into `Failure`s.

/// Thrown when the API returns a non-2xx response.
class ServerException implements Exception {
  ServerException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ServerException($statusCode): $message';
}

/// Thrown when the request cannot reach the server (socket / timeout).
class NetworkException implements Exception {
  NetworkException([this.message = 'No internet connection.']);

  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

/// Thrown when a response body cannot be decoded into the expected model.
class ParsingException implements Exception {
  ParsingException([this.message = 'Failed to parse server response.']);

  final String message;

  @override
  String toString() => 'ParsingException: $message';
}

/// Thrown when reading from or writing to local (on-device) storage fails.
class CacheException implements Exception {
  CacheException([this.message = 'Failed to read local storage.']);

  final String message;

  @override
  String toString() => 'CacheException: $message';
}
