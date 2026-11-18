/// An OTP that was sent and is waiting to be verified.
class OtpChallenge {
  /// Creates a challenge.
  const OtpChallenge({required this.phoneNumber, this.resendAfterSeconds});

  /// The number to verify against, as the server normalised it
  /// (e.g. `+919876500001`).
  final String phoneNumber;

  /// Seconds before "Resend OTP" may be used; `null` keeps the app default.
  final int? resendAfterSeconds;
}
