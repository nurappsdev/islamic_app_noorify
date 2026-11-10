import 'package:tuhfatul_muslim/core/localization/localized_failure_message.dart';

/// Base type for everything that can go wrong in the domain layer.
///
/// Repositories return `Either<Failure, T>` so the presentation layer can react
/// to a typed problem instead of catching raw exceptions.
abstract class Failure {
  const Failure(String message, {this.statusCode}) : rawMessage = message;

  /// The text as the failure was created: English for a failure the app made
  /// itself, the server's own words for an API error.
  final String rawMessage;

  /// Human readable, safe to surface directly in the UI. A failure the app made
  /// itself (no connection, timeout, ...) reads in the selected language; the
  /// server's error text is shown as the server wrote it.
  String get message => localizeFailureMessage(rawMessage);

  /// HTTP status code when the failure originated from a server response.
  final int? statusCode;

  @override
  String toString() => 'Failure($statusCode): $message';
}

/// The server responded, but with an error payload (4xx / 5xx).
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.statusCode});
}

/// The request never completed: no connectivity, DNS error, timeout, etc.
class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'No internet connection. Please try again.',
  ]);
}

/// The response was received but could not be parsed into the expected shape.
class ParsingFailure extends Failure {
  const ParsingFailure([
    super.message = 'Received an unexpected response from the server.',
  ]);
}

/// Client-side validation failed before the request was sent.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Reading from or writing to local (on-device) storage failed.
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Failed to read local storage.']);
}

/// Anything that does not fit the buckets above.
class UnknownFailure extends Failure {
  const UnknownFailure([
    super.message = 'Something went wrong. Please try again.',
  ]);
}
