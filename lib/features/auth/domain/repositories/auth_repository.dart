import 'package:imart_delivery_app/features/auth/domain/entities/otp_challenge.dart';

/// Contract for phone + OTP authentication.
abstract interface class AuthRepository {
  /// Sends an OTP to [phone].
  Future<OtpChallenge> sendOtpAsync(String phone);

  /// Verifies [otp] for [phone]; `true` when accepted.
  Future<bool> verifyOtpAsync(String phone, String otp);

  /// `true` when a stored session is still valid (auto-login).
  Future<bool> restoreSessionAsync();

  /// Ends the session and clears credentials.
  Future<void> logoutAsync();
}
