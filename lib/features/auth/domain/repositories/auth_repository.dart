/// Contract for phone + OTP authentication.
abstract interface class AuthRepository {
  /// Sends an OTP to [phone].
  Future<void> sendOtpAsync(String phone);

  /// Verifies [otp] for [phone]; `true` when accepted.
  Future<bool> verifyOtpAsync(String phone, String otp);

  /// Ends the session and clears credentials.
  Future<void> logoutAsync();
}
