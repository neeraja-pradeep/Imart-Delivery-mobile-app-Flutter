import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Cookie-jar [Storage] backed by Keychain / Keystore.
///
/// The Django `sessionid` and `csrftoken` cookies are the app's credentials,
/// so they are persisted in secure storage rather than plain files.
class SecureCookieStorage implements Storage {
  /// Creates the storage over [secureStorage].
  const SecureCookieStorage(this._secureStorage);

  static const String _keyPrefix = 'cookie_jar.';

  final FlutterSecureStorage _secureStorage;

  @override
  Future<void> init(bool persistSession, bool ignoreExpires) async {}

  @override
  Future<String?> read(String key) =>
      _secureStorage.read(key: '$_keyPrefix$key');

  @override
  Future<void> write(String key, String value) =>
      _secureStorage.write(key: '$_keyPrefix$key', value: value);

  @override
  Future<void> delete(String key) =>
      _secureStorage.delete(key: '$_keyPrefix$key');

  @override
  Future<void> deleteAll(List<String> keys) async {
    for (final String key in keys) {
      await delete(key);
    }
  }
}
