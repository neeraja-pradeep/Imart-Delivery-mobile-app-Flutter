import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/app/config/env.dart';
import 'package:imart_delivery_app/features/auth/application/states/login_state.dart';
import 'package:imart_delivery_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:imart_delivery_app/features/auth/infrastructure/data_sources/remote/auth_api.dart';
import 'package:imart_delivery_app/features/auth/infrastructure/data_sources/remote/auth_static_api.dart';
import 'package:imart_delivery_app/features/auth/infrastructure/repositories/auth_repository_impl.dart';

/// Auth data source. **Swap point for API integration.**
final Provider<AuthApi> authApiProvider = Provider<AuthApi>(
  (Ref ref) => const AuthStaticApi(),
);

/// Auth repository.
final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>(
      (Ref ref) => AuthRepositoryImpl(ref.watch(authApiProvider)),
    );

/// Whether the rider is signed in. Drives the router's auth guard.
final StateNotifierProvider<SessionController, bool> isAuthenticatedProvider =
    StateNotifierProvider<SessionController, bool>(
      (Ref ref) => SessionController(
        ref.watch(authRepositoryProvider),
        initiallySignedIn: _previewStartsSignedIn(Env.current.previewScreen),
      ),
    );

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
  /// Creates the controller.
  SessionController(this._repository, {bool initiallySignedIn = false})
    : super(initiallySignedIn);

  final AuthRepository _repository;

  /// Marks the session active after a successful OTP verification.
  void signIn() => state = true;

  /// Ends the session.
  Future<void> logoutAsync() async {
    await _repository.logoutAsync();
    state = false;
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
  Future<void> sendOtpAsync() async {
    await _repository.sendOtpAsync(state.phone);
    state = state.copyWith(
      step: LoginStep.otp,
      otp: '',
      clearError: true,
      secondsLeft: AppTimings.otpInitialSeconds,
    );
    _startCountdown();
  }

  /// Resends the OTP once the countdown has finished.
  Future<void> resendOtpAsync() async {
    if (!state.canResend) {
      return;
    }
    await _repository.sendOtpAsync(state.phone);
    state = state.copyWith(
      otp: '',
      clearError: true,
      secondsLeft: AppTimings.otpResendSeconds,
    );
    _startCountdown();
  }

  /// Verifies the OTP. Returns `true` on success; otherwise sets the
  /// inline error.
  Future<bool> verifyOtpAsync() async {
    final bool ok = await _repository.verifyOtpAsync(state.phone, state.otp);
    if (!ok) {
      state = state.copyWith(otpError: AppStrings.otpIncorrect);
    }
    return ok;
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
