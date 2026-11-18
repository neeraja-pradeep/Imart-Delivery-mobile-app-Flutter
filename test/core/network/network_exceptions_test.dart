import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:imart_delivery_app/core/error/failure.dart';
import 'package:imart_delivery_app/core/network/network_exceptions.dart';

DioException _response(int status, Object body) {
  final RequestOptions request = RequestOptions(path: '/x');
  return DioException(
    requestOptions: request,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: request,
      statusCode: status,
      data: body,
    ),
  );
}

void main() {
  test('403 without a session is an expired session', () {
    final Failure failure = NetworkExceptions.fromDio(
      _response(403, <String, dynamic>{
        'detail': NetworkExceptions.notSignedInDetail,
      }),
    );
    expect(failure, isA<UnauthorizedFailure>());
  });

  test('403 for another reason keeps the server message', () {
    final Failure failure = NetworkExceptions.fromDio(
      _response(403, <String, dynamic>{
        'detail': 'CSRF Failed: CSRF token missing.',
      }),
    );
    expect(failure, isA<ServerFailure>());
    expect(failure.message, 'CSRF Failed: CSRF token missing.');
  });

  test('OTP errors carry the code and retry wait', () {
    final ServerFailure failure =
        NetworkExceptions.fromDio(
              _response(429, <String, dynamic>{
                'error': 'Please wait before requesting another OTP.',
                'code': 'resend_too_soon',
                'retry_after_seconds': 24,
              }),
            )
            as ServerFailure;
    expect(failure.code, 'resend_too_soon');
    expect(failure.retryAfterSeconds, 24);
  });

  test('DRF field errors surface their first message', () {
    final Failure failure = NetworkExceptions.fromDio(
      _response(400, <String, dynamic>{
        'cash_collected': <String>['This order is prepaid.'],
      }),
    );
    expect(failure.message, 'This order is prepaid.');
  });

  test('no connection is a network failure', () {
    final Failure failure = NetworkExceptions.fromDio(
      DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.connectionError,
      ),
    );
    expect(failure, isA<NetworkFailure>());
  });
}
