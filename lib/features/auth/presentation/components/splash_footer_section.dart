import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/typography.dart';
import 'package:imart_delivery_app/core/widgets/app_button.dart';

/// Splash tagline and "Get Started" CTA pinned near the bottom.
class SplashFooterSection extends StatelessWidget {
  /// Creates the footer.
  const SplashFooterSection({super.key, required this.onGetStarted});

  /// CTA handler.
  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    return Positioned(
      left: 30.w,
      right: 30.w,
      bottom: 88.h + bottomInset,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            AppStrings.splashTagline,
            textAlign: TextAlign.center,
            style: AppTypography.accent(
              16,
              color: AppColors.white92,
              height: 1.5,
            ),
          ),
          SizedBox(height: 26.h),
          AppButton(
            label: AppStrings.getStarted,
            variant: AppButtonVariant.brand,
            onPressed: onGetStarted,
          ),
        ],
      ),
    );
  }
}
