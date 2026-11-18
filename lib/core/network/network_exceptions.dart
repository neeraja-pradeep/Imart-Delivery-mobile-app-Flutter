import 'package:dio/dio.dart';

import 'package:imart_delivery_app/core/error/failure.dart';

/// Maps transport and HTTP errors to domain [Failure]s.
///
/// The backend uses Django REST Framework error shapes:
/// `{"error": "...", "code": "..."}`, `{"detail": "..."}` or field errors
/// `{"<field>": ["message", ...]}`.
abstract final class NetworkExceptions {
  /// The body DRF returns when no session cookie was sent (403, not 401).
  static const String notSignedInDetail =
      'Authentication credentials were not provided.';

  static const String _fallbackMessage =
      'Something went wrong. Please try again.';
  static const int _forbidden = 403;

  /// Converts [error] into a [Failure].
  static Failure fromDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return NetworkFailure('Network unavailable', error);
      case DioExceptionType.badResponse:
        return _fromResponse(error);
      case DioExceptionType.transformTimeout:
      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return Failure(_fallbackMessage, cause: error);
    }
  }

  /// Whether [failure] means the session is gone.
  static bool isSignedOut(Failure failure) => failure is UnauthorizedFailure;

  static Failure _fromResponse(DioException error) {
    final Response<dynamic>? response = error.response;
    final int? status = response?.statusCode;
    final Object? body = response?.data;
    final String message = messageFrom(body) ?? _fallbackMessage;
    if (status == _forbidden && message == notSignedInDetail) {
      return const UnauthorizedFailure();
    }
    return ServerFailure(
      message,
      statusCode: status,
      code: body is Map<String, dynamic> ? body['code'] as String? : null,
      retryAfterSeconds: body is Map<String, dynamic>
          ? (body['retry_after_seconds'] as num?)?.toInt()
          : null,
      cause: error,
    );
  }

  /// Best human-readable message in a DRF error [body], if any.
  static String? messageFrom(Object? body) {
    if (body is! Map<String, dynamic>) {
      return null;
    }
    for (final String key in <String>['error', 'detail']) {
      final Object? value = body[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    for (final Object? value in body.values) {
      if (value is String && value.isNotEmpty) {
        return value;
      }
      if (value is List && value.isNotEmpty && value.first is String) {
        return value.first as String;
      }
    }
    return null;
  }
}
