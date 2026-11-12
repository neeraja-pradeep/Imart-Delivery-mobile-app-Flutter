import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/app/router/app_routes.dart';
import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/theme.dart';
import 'package:imart_delivery_app/core/widgets/app_back_button.dart';
import 'package:imart_delivery_app/core/widgets/app_logo.dart';
import 'package:imart_delivery_app/core/widgets/app_pattern_background.dart';
import 'package:imart_delivery_app/core/widgets/app_status_bar_style.dart';
import 'package:imart_delivery_app/features/auth/application/providers/auth_providers.dart';
import 'package:imart_delivery_app/features/auth/application/states/login_state.dart';
import 'package:imart_delivery_app/features/auth/presentation/components/login_form_section.dart';
import 'package:imart_delivery_app/features/common/feedback/application/providers/app_feedback_provider.dart';
import 'package:imart_delivery_app/features/trip/application/providers/trip_providers.dart';

/// Phone + OTP login over a faint vegetable texture.
class LoginScreen extends ConsumerWidget {
  /// Creates the login screen.
  const LoginScreen({super.key});

  static const double _patternHeight = 420;
  static const double _patternOpacity = 0.06;
  static const double _backTop = 48;
  static const double _logoTop = 120;
  static const double _logoSize = 66;
  static const double _sheetTop = 300;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LoginStep step = ref.watch(
      loginControllerProvider.select((LoginState s) => s.step),
    );
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop) {
          _onBack(context, ref, step);
        }
      },
      child: AppStatusBarStyle(
        dark: true,
        child: Scaffold(
          backgroundColor: AppColors.white,
          body: Stack(
            children: <Widget>[
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: _patternHeight.h,
                child: const AppPatternBackground(opacity: _patternOpacity),
              ),
              Positioned(
                top: AppSizes.topInset(context, _backTop),
                left: 14.w,
                child: AppBackButton(
                  style: AppBackButtonStyle.plainBrand,
                  onPressed: () => _onBack(context, ref, step),
                ),
              ),
              Positioned(
                top: AppSizes.topInset(context, _logoTop),
                left: 0,
                right: 0,
                child: const Center(child: AppLogo(size: _logoSize)),
              ),
              Positioned(
                top: AppSizes.topInset(context, _sheetTop),
                left: 0,
                right: 0,
                bottom: 0,
                child: LoginFormSection(
                  onPrimary: () => _onPrimaryAsync(ref, step),
                  onResend: () => _onResendAsync(ref),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onBack(BuildContext context, WidgetRef ref, LoginStep step) {
    if (step == LoginStep.otp) {
      ref.read(loginControllerProvider.notifier).editNumber();
      return;
    }
    context.go(AppRoutes.splash);
  }

  Future<void> _onPrimaryAsync(WidgetRef ref, LoginStep step) async {
    final AppFeedbackController feedback = ref.read(
      appFeedbackProvider.notifier,
    );
    final LoginController login = ref.read(loginControllerProvider.notifier);
    if (step == LoginStep.phone) {
      await feedback.runWithLoadingAsync(
        AppStrings.sendingOtp,
        login.sendOtpAsync,
      );
      return;
    }
    final bool ok = await feedback.runWithLoadingAsync(
      AppStrings.verifying,
      () async {
        final bool verified = await login.verifyOtpAsync();
        if (verified) {
          await ref.read(tripControllerProvider.notifier).loadTripAsync();
        }
        return verified;
      },
    );
    if (ok) {
      ref.read(isAuthenticatedProvider.notifier).signIn();
    }
  }

  Future<void> _onResendAsync(WidgetRef ref) => ref
      .read(appFeedbackProvider.notifier)
      .runWithLoadingAsync(
        AppStrings.sendingOtp,
        ref.read(loginControllerProvider.notifier).resendOtpAsync,
      );
}
