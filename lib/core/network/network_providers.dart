import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:imart_delivery_app/app/config/env.dart';
import 'package:imart_delivery_app/core/network/api_client.dart';
import 'package:imart_delivery_app/core/storage/secure_cookie_storage.dart';

/// Session cookie jar persisted in secure storage.
final Provider<CookieJar> cookieJarProvider = Provider<CookieJar>(
  (Ref ref) => PersistCookieJar(
    storage: const SecureCookieStorage(FlutterSecureStorage()),
  ),
);

/// The app's single [ApiClient].
final Provider<ApiClient> apiClientProvider = Provider<ApiClient>((Ref ref) {
  final ApiClient client = ApiClient(
    baseUrl: Env.current.apiBaseUrl,
    cookieJar: ref.watch(cookieJarProvider),
  );
  ref.onDispose(client.dispose);
  return client;
});
