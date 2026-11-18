import 'package:imart_delivery_app/app/config/env.dart';

/// Staged-rollout switches.
abstract final class FeatureFlags {
  static const bool _demoOtpHintDefine = bool.fromEnvironment(
    'SHOW_DEMO_OTP_HINT',
    defaultValue: true,
  );

  /// Shows "Demo code: 1234" under the OTP field. Only with static data:
  /// the real SMS OTP API never accepts the demo code.
  static bool get showDemoOtpHint =>
      _demoOtpHintDefine && Env.current.useStaticData;
}
