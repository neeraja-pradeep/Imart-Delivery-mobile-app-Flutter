import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/app/config/feature_flags.dart';
import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/typography.dart';
import 'package:imart_delivery_app/core/widgets/app_icon.dart';
import 'package:imart_delivery_app/core/widgets/app_text_field.dart';
import 'package:imart_delivery_app/features/auth/application/providers/auth_providers.dart';
import 'package:imart_delivery_app/features/auth/application/states/login_state.dart';
import 'package:imart_delivery_app/features/auth/infrastructure/data_sources/remote/auth_static_api.dart';

/// OTP label row, field, inline error, resend countdown and demo hint.
class OtpFieldSection extends ConsumerStatefulWidget {
  /// Creates the OTP block.
  const OtpFieldSection({super.key, required this.onResend});

  /// "Resend OTP" handler.
  final VoidCallback onResend;

  @override
  ConsumerState<OtpFieldSection> createState() => _OtpFieldSectionState();
}

class _OtpFieldSectionState extends ConsumerState<OtpFieldSection> {
  final TextEditingController _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(
      loginControllerProvider.select((LoginState s) => s.otp),
      (String? _, String next) {
        if (next.isEmpty && _otpController.text.isNotEmpty) {
          _otpController.clear();
        }
      },
    );
    final LoginState login = ref.watch(loginControllerProvider);
    final LoginController controller = ref.read(
      loginControllerProvider.notifier,
    );
    final String? error = login.otpError;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              AppStrings.otpLabel,
              style: AppTypography.body(
                12,
                weight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            _LinkButton(
              label: AppStrings.editNumber,
              size: 12,
              color: AppColors.textLink,
              padding: EdgeInsets.symmetric(vertical: 6.h),
              onTap: controller.editNumber,
            ),
          ],
        ),
        SizedBox(height: 7.h),
        AppTextField(
          controller: _otpController,
          placeholder: AppStrings.otpPlaceholder,
          keyboardType: TextInputType.number,
          digitsOnly: true,
          maxLength: AppLimits.otpLength,
          onChanged: controller.setOtp,
        ),
        if (error != null) ...<Widget>[
          SizedBox(height: 8.h),
          Row(
            children: <Widget>[
              const AppIcon(
                AppIconGlyph.alertCircle,
                size: 15,
                color: AppColors.coral,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  error,
                  style: AppTypography.body(12.5, color: AppColors.coral),
                ),
              ),
            ],
          ),
        ],
        SizedBox(height: 8.h),
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: 32.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                login.canResend
                    ? AppStrings.didntGetCode
                    : AppStrings.resendIn(login.secondsLeft),
                style: AppTypography.body(13, color: AppColors.textMuted),
              ),
              _LinkButton(
                label: AppStrings.resendOtp,
                size: 13,
                color: login.canResend ? AppColors.textLink : AppColors.ink400,
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 8.h),
                onTap: login.canResend ? widget.onResend : null,
              ),
            ],
          ),
        ),
        if (FeatureFlags.showDemoOtpHint) ...<Widget>[
          SizedBox(height: 6.h),
          Text.rich(
            TextSpan(
              text: AppStrings.demoCode,
              children: <InlineSpan>[
                TextSpan(
                  text: AuthStaticApi.demoOtp,
                  style: AppTypography.body(
                    11.5,
                    weight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            style: AppTypography.body(11.5, color: AppColors.textMuted),
          ),
        ],
      ],
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({
    required this.label,
    required this.size,
    required this.color,
    required this.padding,
    required this.onTap,
  });

  final String label;
  final double size;
  final Color color;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: padding,
        child: Text(
          label,
          style: AppTypography.body(
            size,
            weight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}
