import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/features/auth/application/providers/auth_providers.dart';
import 'package:imart_delivery_app/features/auth/application/states/login_state.dart';
import 'package:imart_delivery_app/features/auth/infrastructure/data_sources/remote/auth_api.dart';

class _InstantAuthApi implements AuthApi {
  @override
  Future<void> sendOtpAsync(String phone) async {}

  @override
  Future<bool> verifyOtpAsync(String phone, String otp) async => otp == '1234';

  @override
  Future<void> logoutAsync() async {}
}

void main() {
  test('OTP step, countdown, wrong code and resend', () {
    fakeAsync((FakeAsync async) {
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          authApiProvider.overrideWithValue(_InstantAuthApi()),
        ],
      );
      final ProviderSubscription<LoginState> sub = container.listen(
        loginControllerProvider,
        (_, _) {},
      );
      final LoginController c = container.read(
        loginControllerProvider.notifier,
      );

      c.sendOtpAsync();
      async.flushMicrotasks();
      expect(sub.read().step, LoginStep.otp);
      expect(sub.read().secondsLeft, AppTimings.otpInitialSeconds);

      async.elapse(const Duration(seconds: 3));
      expect(sub.read().secondsLeft, AppTimings.otpInitialSeconds - 3);
      expect(sub.read().canResend, isFalse);

      c.setOtp('1111');
      bool? ok;
      c.verifyOtpAsync().then((bool v) => ok = v);
      async.flushMicrotasks();
      expect(ok, isFalse);
      expect(sub.read().otpError, AppStrings.otpIncorrect);

      c.setOtp('1234');
      expect(sub.read().otpError, isNull);
      c.verifyOtpAsync().then((bool v) => ok = v);
      async.flushMicrotasks();
      expect(ok, isTrue);

      async.elapse(const Duration(seconds: AppTimings.otpInitialSeconds));
      expect(sub.read().canResend, isTrue);
      c.resendOtpAsync();
      async.flushMicrotasks();
      expect(sub.read().secondsLeft, AppTimings.otpResendSeconds);
      expect(sub.read().otp, isEmpty);

      c.editNumber();
      expect(sub.read().step, LoginStep.phone);
      container.dispose();
    });
  });
}
