/// Domain-level failure surfaced to the UI instead of raw exceptions.
class Failure implements Exception {
  /// Creates a failure.
  const Failure(this.message, {this.cause});

  /// Human-readable reason.
  final String message;

  /// Underlying error, if any.
  final Object? cause;

  @override
  String toString() => 'Failure($message)';
}

/// The device could not reach the server.
class NetworkFailure extends Failure {
  /// Creates a network failure.
  const NetworkFailure([super.message = 'Network unavailable', Object? cause])
    : super(cause: cause);
}

/// The session is missing or expired; the rider must sign in again.
class UnauthorizedFailure extends Failure {
  /// Creates an unauthorized failure.
  const UnauthorizedFailure([
    super.message = 'Your session has expired. Please log in again.',
  ]);
}

/// The server answered with an error the rider can act on.
class ServerFailure extends Failure {
  /// Creates a server failure.
  const ServerFailure(
    super.message, {
    this.statusCode,
    this.code,
    this.retryAfterSeconds,
    super.cause,
  });

  /// HTTP status code, when the server answered.
  final int? statusCode;

  /// Machine-readable error code (e.g. `invalid_otp`), when provided.
  final String? code;

  /// Seconds to wait before retrying (OTP resend cooldown), when provided.
  final int? retryAfterSeconds;

  @override
  String toString() => 'ServerFailure($statusCode, $code, $message)';
}
