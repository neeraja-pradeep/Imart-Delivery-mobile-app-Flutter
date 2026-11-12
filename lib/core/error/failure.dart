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
