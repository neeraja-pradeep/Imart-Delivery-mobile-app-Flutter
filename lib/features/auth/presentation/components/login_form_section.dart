import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/theme.dart';
import 'package:imart_delivery_app/app/theme/typography.dart';
import 'package:imart_delivery_app/core/widgets/app_button.dart';
import 'package:imart_delivery_app/core/widgets/app_text_field.dart';
import 'package:imart_delivery_app/features/auth/application/providers/auth_providers.dart';
import 'package:imart_delivery_app/features/auth/application/states/login_state.dart';
import 'package:imart_delivery_app/features/auth/presentation/components/otp_field_section.dart';

/// Rounded white sheet holding the title, the active step's field and the
/// primary CTA.
class LoginFormSection extends ConsumerWidget {
  /// Creates the form sheet.
  const LoginFormSection({
    super.key,
    required this.onPrimary,
    required this.onResend,
  });

  /// "Send OTP" / "Verify & Login".
  final VoidCallback onPrimary;

  /// "Resend OTP".
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LoginStep step = ref.watch(
      loginControllerProvider.select((LoginState s) => s.step),
    );
    final bool otpStep = step == LoginStep.otp;
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 28.h + bottomInset),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.header.r),
        ),
        boxShadow: AppShadows.sheet,
      ),
      child: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: <Widget>[
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  otpStep ? AppStrings.otpTitle : AppStrings.loginTitle,
                  style: AppTypography.display(22),
                ),
                SizedBox(height: 4.h),
                Text(
                  otpStep ? AppStrings.otpSubtitle : AppStrings.loginSubtitle,
                  style: AppTypography.body(13, color: AppColors.textMuted),
                ),
                SizedBox(height: 24.h),
                if (otpStep)
                  OtpFieldSection(onResend: onResend)
                else
                  AppTextField(
                    label: AppStrings.mobileNumber,
                    placeholder: AppStrings.mobilePlaceholder,
                    initialValue: ref.read(loginControllerProvider).phone,
                    keyboardType: TextInputType.phone,
                    digitsOnly: true,
                    maxLength: AppLimits.phoneLength,
                    onChanged: ref
                        .read(loginControllerProvider.notifier)
                        .setPhone,
                  ),
                const Spacer(),
                SizedBox(height: 20.h),
                AppButton(
                  label: otpStep ? AppStrings.verifyLogin : AppStrings.sendOtp,
                  onPressed: onPrimary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
