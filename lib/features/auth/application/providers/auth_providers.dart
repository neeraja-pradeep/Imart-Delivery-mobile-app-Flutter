import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/app/config/env.dart';
import 'package:imart_delivery_app/core/error/failure.dart';
import 'package:imart_delivery_app/core/network/network_providers.dart';
import 'package:imart_delivery_app/core/utils/logger.dart';
import 'package:imart_delivery_app/features/auth/application/states/login_state.dart';
import 'package:imart_delivery_app/features/auth/domain/entities/otp_challenge.dart';
import 'package:imart_delivery_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:imart_delivery_app/features/auth/infrastructure/data_sources/remote/auth_api.dart';
import 'package:imart_delivery_app/features/auth/infrastructure/data_sources/remote/auth_remote_api.dart';
import 'package:imart_delivery_app/features/auth/infrastructure/data_sources/remote/auth_static_api.dart';
import 'package:imart_delivery_app/features/auth/infrastructure/repositories/auth_repository_impl.dart';

/// Auth data source: the backend, or fixtures when no `API_BASE_URL` is set.
final Provider<AuthApi> authApiProvider = Provider<AuthApi>(
  (Ref ref) => Env.current.useStaticData
      ? const AuthStaticApi()
      : AuthRemoteApi(ref.watch(apiClientProvider)),
);

/// Auth repository.
final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>(
      (Ref ref) => AuthRepositoryImpl(ref.watch(authApiProvider)),
    );

/// Whether the rider is signed in. Drives the router's auth guard.
///
/// On start it validates any stored session with the server (auto-login),
/// and it signs out when the server reports the session has expired.
final StateNotifierProvider<SessionController, bool> isAuthenticatedProvider =
    StateNotifierProvider<SessionController, bool>((Ref ref) {
      final bool previewSignedIn = _previewStartsSignedIn(
        Env.current.previewScreen,
      );
      final SessionController controller = SessionController(
        ref.watch(authRepositoryProvider),
        initiallySignedIn: previewSignedIn,
        signedOutEvents: Env.current.useStaticData
            ? null
            : ref.watch(apiClientProvider).signedOutEvents,
      );
      if (!previewSignedIn) {
        unawaited(controller.restoreAsync());
      }
      return controller;
    });

/// Login form controller (disposed when the login screen closes).
final AutoDisposeStateNotifierProvider<LoginController, LoginState>
loginControllerProvider =
    StateNotifierProvider.autoDispose<LoginController, LoginState>(
      (Ref ref) => LoginController(ref.watch(authRepositoryProvider)),
    );

bool _previewStartsSignedIn(PreviewScreen screen) =>
    screen != PreviewScreen.splash && screen != PreviewScreen.login;

/// Holds the signed-in flag.
class SessionController extends StateNotifier<bool> {
  /// Creates the controller; [signedOutEvents] fire when the server rejects
  /// the session.
  SessionController(
    this._repository, {
    bool initiallySignedIn = false,
    Stream<void>? signedOutEvents,
  }) : super(initiallySignedIn) {
    _signedOutSub = signedOutEvents?.listen((_) => _expire());
  }

  final AuthRepository _repository;
  StreamSubscription<void>? _signedOutSub;

  @override
  void dispose() {
    _signedOutSub?.cancel();
    super.dispose();
  }

  /// Signs in silently when a stored session is still valid.
  Future<void> restoreAsync() async {
    try {
      final bool valid = await _repository.restoreSessionAsync();
      if (valid && mounted) {
        state = true;
      }
    } on Failure catch (failure) {
      AppLogger.log('Session restore failed', error: failure);
    }
  }

  /// Marks the session active after a successful OTP verification.
  void signIn() => state = true;

  /// Ends the session. The rider is signed out locally even when the
  /// server call fails.
  Future<void> logoutAsync() async {
    try {
      await _repository.logoutAsync();
    } finally {
      if (mounted) {
        state = false;
      }
    }
  }

  void _expire() {
    if (mounted && state) {
      AppLogger.log('Session expired; signing out');
      state = false;
    }
  }
}

/// Phone → OTP login flow with resend countdown.
class LoginController extends StateNotifier<LoginState> {
  /// Creates the controller.
  LoginController(this._repository) : super(const LoginState());

  final AuthRepository _repository;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Updates the mobile number.
  void setPhone(String value) => state = state.copyWith(phone: value);

  /// Updates the OTP and clears any error.
  void setOtp(String value) =>
      state = state.copyWith(otp: value, clearError: true);

  /// Sends the OTP and moves to the OTP step.
  ///
  /// Sent again too soon (after "Edit number" with the same number), the
  /// earlier code is still valid: go straight back to the OTP step with the
  /// server's remaining wait.
  Future<void> sendOtpAsync() async {
    final OtpChallenge challenge;
    try {
      challenge = await _repository.sendOtpAsync(state.phone);
    } on ServerFailure catch (failure) {
      final int? wait = failure.retryAfterSeconds;
      final String sentTo = state.challengePhone ?? '';
      final String digits = state.phone.replaceAll(RegExp(r'\D'), '');
      if (wait == null || digits.isEmpty || !sentTo.endsWith(digits)) {
        rethrow;
      }
      state = state.copyWith(
        step: LoginStep.otp,
        otp: '',
        clearError: true,
        secondsLeft: wait,
      );
      _startCountdown();
      return;
    }
    state = state.copyWith(
      step: LoginStep.otp,
      otp: '',
      clearError: true,
      challengePhone: challenge.phoneNumber,
      secondsLeft: challenge.resendAfterSeconds ?? AppTimings.otpInitialSeconds,
    );
    _startCountdown();
  }

  /// Resends the OTP once the countdown has finished.
  Future<void> resendOtpAsync() async {
    if (!state.canResend) {
      return;
    }
    try {
      final OtpChallenge challenge = await _repository.sendOtpAsync(
        state.phone,
      );
      state = state.copyWith(
        otp: '',
        clearError: true,
        challengePhone: challenge.phoneNumber,
        secondsLeft:
            challenge.resendAfterSeconds ?? AppTimings.otpResendSeconds,
      );
      _startCountdown();
    } on ServerFailure catch (failure) {
      final int? wait = failure.retryAfterSeconds;
      if (wait == null) {
        rethrow;
      }
      // Resent too soon: restart the countdown with the server's wait.
      state = state.copyWith(secondsLeft: wait);
      _startCountdown();
    }
  }

  /// Verifies the OTP. Returns `true` on success; otherwise sets the
  /// inline error (wrong, expired or too many attempts).
  Future<bool> verifyOtpAsync() async {
    try {
      final bool ok = await _repository.verifyOtpAsync(
        state.challengePhone ?? state.phone,
        state.otp,
      );
      if (!ok) {
        state = state.copyWith(otpError: AppStrings.otpIncorrect);
      }
      return ok;
    } on ServerFailure catch (failure) {
      state = state.copyWith(otpError: failure.message);
      return false;
    }
  }

  /// Returns to the phone step.
  void editNumber() {
    _timer?.cancel();
    state = state.copyWith(step: LoginStep.phone, otp: '', clearError: true);
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(AppTimings.tick, (Timer timer) {
      if (state.step != LoginStep.otp || state.secondsLeft <= 0) {
        timer.cancel();
        return;
      }
      state = state.copyWith(secondsLeft: state.secondsLeft - 1);
    });
  }
}
