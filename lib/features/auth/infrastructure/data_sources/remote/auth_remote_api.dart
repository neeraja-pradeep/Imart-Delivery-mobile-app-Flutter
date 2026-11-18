import 'package:imart_delivery_app/core/error/failure.dart';
import 'package:imart_delivery_app/core/network/api_client.dart';
import 'package:imart_delivery_app/core/network/endpoints.dart';
import 'package:imart_delivery_app/core/utils/logger.dart';
import 'package:imart_delivery_app/features/auth/domain/entities/otp_challenge.dart';
import 'package:imart_delivery_app/features/auth/infrastructure/data_sources/remote/auth_api.dart';

/// [AuthApi] backed by the iMart delivery-partner API (phone + OTP login,
/// Django session cookie).
class AuthRemoteApi implements AuthApi {
  /// Creates the API over [client].
  const AuthRemoteApi(this._client);

  /// Server code for a wrong OTP; mapped to "Incorrect OTP" in the UI.
  static const String invalidOtpCode = 'invalid_otp';

  final ApiClient _client;

  @override
  Future<OtpChallenge> sendOtpAsync(String phone) async {
    final JsonMap body = await _client.postAsync(
      ApiEndpoints.otpSend,
      data: <String, dynamic>{'phone_number': phone},
    );
    return OtpChallenge(
      phoneNumber: body['phone_number'] as String? ?? phone,
      resendAfterSeconds: (body['resend_after_seconds'] as num?)?.toInt(),
    );
  }

  @override
  Future<bool> verifyOtpAsync(String phone, String otp) async {
    // Drop any previous rider's session before starting a new one.
    await _client.clearSessionAsync();
    try {
      await _client.postAsync(
        ApiEndpoints.otpVerify,
        data: <String, dynamic>{'phone_number': phone, 'otp_code': otp},
      );
      return true;
    } on ServerFailure catch (failure) {
      if (failure.code == invalidOtpCode) {
        return false;
      }
      rethrow;
    }
  }

  @override
  Future<bool> restoreSessionAsync() async {
    if (!await _client.hasSessionAsync()) {
      return false;
    }
    try {
      await _client.getAsync(ApiEndpoints.myDeliveryProfile);
      return true;
    } on UnauthorizedFailure {
      return false;
    } on ServerFailure catch (failure) {
      // Signed in, but not as a delivery partner (or no profile yet).
      AppLogger.log('Stored session rejected', error: failure);
      await _client.clearSessionAsync();
      return false;
    }
  }

  @override
  Future<void> logoutAsync() async {
    try {
      await _client.postAsync(ApiEndpoints.logout);
    } on Failure catch (failure) {
      // The local session is cleared below either way.
      AppLogger.log('Logout call failed', error: failure);
    } finally {
      await _client.clearSessionAsync();
    }
  }
}
