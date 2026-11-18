import 'package:imart_delivery_app/core/error/failure.dart';
import 'package:imart_delivery_app/features/auth/domain/entities/otp_challenge.dart';
import 'package:imart_delivery_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:imart_delivery_app/features/auth/infrastructure/data_sources/remote/auth_api.dart';

/// [AuthRepository] backed by an [AuthApi].
class AuthRepositoryImpl implements AuthRepository {
  /// Creates the repository.
  const AuthRepositoryImpl(this._api);

  final AuthApi _api;

  @override
  Future<OtpChallenge> sendOtpAsync(String phone) =>
      _guardAsync(() => _api.sendOtpAsync(phone));

  @override
  Future<bool> verifyOtpAsync(String phone, String otp) =>
      _guardAsync(() => _api.verifyOtpAsync(phone, otp));

  @override
  Future<bool> restoreSessionAsync() => _guardAsync(_api.restoreSessionAsync);

  @override
  Future<void> logoutAsync() => _guardAsync(_api.logoutAsync);

  Future<T> _guardAsync<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Failure {
      rethrow;
    } catch (error) {
      throw Failure('Auth request failed', cause: error);
    }
  }
}
