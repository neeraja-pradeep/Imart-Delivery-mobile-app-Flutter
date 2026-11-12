/// Remote data source for authentication. The API layer provides a
/// Dio-backed implementation and swaps it in `authApiProvider`.
abstract interface class AuthApi {
  /// `POST /auth/otp`.
  Future<void> sendOtpAsync(String phone);

  /// `POST /auth/otp/verify`.
  Future<bool> verifyOtpAsync(String phone, String otp);

  /// `POST /auth/logout`.
  Future<void> logoutAsync();
}
