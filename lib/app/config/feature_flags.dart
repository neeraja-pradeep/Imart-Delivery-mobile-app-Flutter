/// Staged-rollout switches.
abstract final class FeatureFlags {
  /// Shows "Demo code: 1234" under the OTP field. Must be off once the real
  /// SMS OTP API is wired.
  static const bool showDemoOtpHint = bool.fromEnvironment(
    'SHOW_DEMO_OTP_HINT',
    defaultValue: true,
  );
}
