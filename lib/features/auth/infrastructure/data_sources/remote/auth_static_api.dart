import 'package:imart_delivery_app/features/auth/infrastructure/data_sources/remote/auth_api.dart';

/// Fixture [AuthApi]: any number receives an OTP and [demoOtp] verifies.
class AuthStaticApi implements AuthApi {
  /// Creates the static API.
  const AuthStaticApi();

  /// The only OTP the static API accepts (shown as the design's demo hint).
  static const String demoOtp = '1234';

  static const Duration _sendLatency = Duration(milliseconds: 800);
  static const Duration _verifyLatency = Duration(milliseconds: 300);

  @override
  Future<void> sendOtpAsync(String phone) => Future<void>.delayed(_sendLatency);

  @override
  Future<bool> verifyOtpAsync(String phone, String otp) async {
    if (otp != demoOtp) {
      return false;
    }
    await Future<void>.delayed(_verifyLatency);
    return true;
  }

  @override
  Future<void> logoutAsync() async {}
}
