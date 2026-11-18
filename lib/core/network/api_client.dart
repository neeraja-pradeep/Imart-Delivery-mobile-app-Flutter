import 'dart:async';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/core/error/failure.dart';
import 'package:imart_delivery_app/core/network/network_exceptions.dart';
import 'package:imart_delivery_app/core/utils/logger.dart';

/// JSON object as returned by the backend.
typedef JsonMap = Map<String, dynamic>;

/// The single HTTP client for every backend call.
///
/// Auth is a Django session: the [CookieJar] keeps `sessionid` and
/// `csrftoken`, and every mutating request carries `X-CSRFToken` (plus
/// `Referer` over HTTPS). Errors are thrown as [Failure]s.
class ApiClient {
  /// Creates a client for [baseUrl] that stores cookies in [cookieJar].
  ApiClient({required String baseUrl, required CookieJar cookieJar, Dio? dio})
    : _cookieJar = cookieJar,
      _baseUrl = baseUrl,
      _dio = dio ?? Dio() {
    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: ApiConfig.timeout,
      sendTimeout: ApiConfig.timeout,
      receiveTimeout: ApiConfig.timeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    );
    _dio.interceptors.addAll(<Interceptor>[
      CookieManager(cookieJar),
      InterceptorsWrapper(onRequest: _attachCsrfAsync),
      InterceptorsWrapper(onResponse: _logResponse, onError: _logError),
    ]);
  }

  static const String _csrfCookie = 'csrftoken';
  static const String _csrfHeader = 'X-CSRFToken';
  static const String _refererHeader = 'Referer';
  static const String _https = 'https';
  static const Set<String> _safeMethods = <String>{'GET', 'HEAD', 'OPTIONS'};
  static const int _firstServerError = 500;

  final Dio _dio;
  final CookieJar _cookieJar;
  final String _baseUrl;
  final StreamController<void> _signedOut = StreamController<void>.broadcast();

  /// Fires whenever the server reports the session is gone.
  Stream<void> get signedOutEvents => _signedOut.stream;

  /// `GET` [path]; retried with exponential backoff on network errors and
  /// 5xx responses (never on 4xx).
  Future<JsonMap> getAsync(String path, {Map<String, dynamic>? query}) async {
    Duration delay = ApiConfig.retryBaseDelay;
    for (int attempt = 1; ; attempt++) {
      try {
        return await _sendAsync(
          () => _dio.get<dynamic>(path, queryParameters: query),
        );
      } on Failure catch (failure) {
        if (attempt >= ApiConfig.maxGetAttempts || !_isRetryable(failure)) {
          rethrow;
        }
        AppLogger.log('GET $path failed, retry $attempt in $delay');
        await Future<void>.delayed(delay);
        delay *= 2;
      }
    }
  }

  /// Every `results` row of a paginated list, following `next` pages
  /// (DRF page-number pagination, 25 per page) up to [ApiConfig.maxPages].
  Future<List<JsonMap>> getAllPagesAsync(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final List<JsonMap> rows = <JsonMap>[];
    for (int page = 1; page <= ApiConfig.maxPages; page++) {
      final JsonMap body = await getAsync(
        path,
        query: <String, dynamic>{...?query, 'page': page},
      );
      final Object? results = body['results'];
      if (results is List) {
        rows.addAll(results.whereType<JsonMap>());
      }
      if (body['next'] == null) {
        break;
      }
    }
    return rows;
  }

  /// `POST` [data] to [path].
  Future<JsonMap> postAsync(String path, {Object? data}) => _sendAsync(
    () => _dio.post<dynamic>(path, data: data ?? const <String, dynamic>{}),
  );

  /// `PATCH` [data] to [path].
  Future<JsonMap> patchAsync(String path, {required JsonMap data}) =>
      _sendAsync(() => _dio.patch<dynamic>(path, data: data));

  /// Forgets the session cookies (logout or expired session).
  Future<void> clearSessionAsync() => _cookieJar.deleteAll();

  /// Whether a session cookie is stored for the backend.
  Future<bool> hasSessionAsync() async {
    if (_baseUrl.isEmpty) {
      return false;
    }
    final List<Cookie> cookies = await _cookieJar.loadForRequest(
      Uri.parse(_baseUrl),
    );
    return cookies.any((Cookie c) => c.name == 'sessionid');
  }

  /// Releases resources.
  void dispose() {
    _signedOut.close();
    _dio.close();
  }

  Future<JsonMap> _sendAsync(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final Response<dynamic> response = await request();
      final Object? data = response.data;
      return data is JsonMap ? data : <String, dynamic>{'results': data};
    } on DioException catch (error) {
      final Failure failure = NetworkExceptions.fromDio(error);
      if (NetworkExceptions.isSignedOut(failure)) {
        await clearSessionAsync();
        if (!_signedOut.isClosed) {
          _signedOut.add(null);
        }
      }
      throw failure;
    }
  }

  bool _isRetryable(Failure failure) {
    if (failure is NetworkFailure) {
      return true;
    }
    final int? status = failure is ServerFailure ? failure.statusCode : null;
    return status != null && status >= _firstServerError;
  }

  Future<void> _attachCsrfAsync(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_safeMethods.contains(options.method.toUpperCase())) {
      try {
        final List<Cookie> cookies = await _cookieJar.loadForRequest(
          options.uri,
        );
        for (final Cookie cookie in cookies) {
          if (cookie.name == _csrfCookie) {
            options.headers[_csrfHeader] = cookie.value;
          }
        }
        if (options.uri.scheme == _https) {
          options.headers[_refererHeader] = '${options.uri.origin}/';
        }
      } catch (error) {
        AppLogger.log('Could not read CSRF cookie', error: error);
      }
    }
    handler.next(options);
  }

  // Logs method, path and status only — never headers or bodies, which carry
  // session cookies, OTPs and customer details.
  void _logResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final RequestOptions request = response.requestOptions;
    AppLogger.log(
      '${request.method} ${request.uri.path} → ${response.statusCode}',
    );
    handler.next(response);
  }

  void _logError(DioException error, ErrorInterceptorHandler handler) {
    final RequestOptions request = error.requestOptions;
    AppLogger.log(
      '${request.method} ${request.uri.path} → '
      '${error.response?.statusCode ?? error.type.name}'
      '${error.error == null ? '' : ' (${error.error.runtimeType})'}',
    );
    handler.next(error);
  }
}
