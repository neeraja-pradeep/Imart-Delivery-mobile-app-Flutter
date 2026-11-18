import 'package:imart_delivery_app/features/auth/domain/entities/otp_challenge.dart';

/// Remote data source for authentication.
///
/// `AuthRemoteApi` talks to the backend; `AuthStaticApi` serves the design
/// fixtures when no backend is configured.
abstract interface class AuthApi {
  /// `POST /api/auth/v1/delivery/otp/send/`.
  Future<OtpChallenge> sendOtpAsync(String phone);

  /// `POST /api/auth/v1/delivery/otp/verify/`; `true` when a session started.
  Future<bool> verifyOtpAsync(String phone, String otp);

  /// `GET /api/delivery/v1/delivery-profiles/me/`; `true` when a stored
  /// session is still valid.
  Future<bool> restoreSessionAsync();

  /// `POST /api/auth/v1/logout/`, then forgets the stored session.
  Future<void> logoutAsync();
}
