/// Login form step.
enum LoginStep {
  /// Entering the mobile number.
  phone,

  /// Entering the OTP.
  otp,
}

/// Immutable login-form state.
class LoginState {
  /// Creates a state.
  const LoginState({
    this.step = LoginStep.phone,
    this.phone = '',
    this.otp = '',
    this.otpError,
    this.secondsLeft = 0,
    this.challengePhone,
  });

  /// Current step.
  final LoginStep step;

  /// Entered mobile number.
  final String phone;

  /// Entered OTP.
  final String otp;

  /// Inline OTP error, if any.
  final String? otpError;

  /// Seconds until "Resend OTP" unlocks.
  final int secondsLeft;

  /// The number the OTP was sent to, as the server normalised it; sent back
  /// unchanged when verifying. `null` until an OTP was sent.
  final String? challengePhone;

  /// Whether resend is available.
  bool get canResend => secondsLeft == 0;

  /// Copy with changes; pass `clearError` to drop [otpError].
  LoginState copyWith({
    LoginStep? step,
    String? phone,
    String? otp,
    String? otpError,
    bool clearError = false,
    int? secondsLeft,
    String? challengePhone,
  }) {
    return LoginState(
      step: step ?? this.step,
      phone: phone ?? this.phone,
      otp: otp ?? this.otp,
      otpError: clearError ? null : (otpError ?? this.otpError),
      secondsLeft: secondsLeft ?? this.secondsLeft,
      challengePhone: challengePhone ?? this.challengePhone,
    );
  }
}
