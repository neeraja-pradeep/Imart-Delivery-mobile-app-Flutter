import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/typography.dart';

/// Logo colourways.
enum AppLogoTone {
  /// Brand green on light surfaces.
  green,

  /// White on the brand-green splash.
  white,
}

/// iMart lockup: apple-bowl mark, "i mart" wordmark, optional tagline.
class AppLogo extends StatelessWidget {
  /// Creates the logo lockup.
  const AppLogo({
    super.key,
    this.tone = AppLogoTone.green,
    this.size = 64,
    this.tagline = false,
  });

  static const double _markAspect = 102.615 / 101.891;
  static const double _gapRatio = 0.12;
  static const double _wordRatio = 0.42;
  static const double _taglineRatio = 0.26;
  static const double _wordTracking = 0.02;
  static const double _taglineTracking = 0.09;

  /// Colourway.
  final AppLogoTone tone;

  /// Mark width in design px.
  final double size;

  /// Shows "online grocery app" under the wordmark.
  final bool tagline;

  @override
  Widget build(BuildContext context) {
    final bool white = tone == AppLogoTone.white;
    final Color color = white ? AppColors.white : AppColors.brand;
    final double wordSize = size * _wordRatio;
    final double tagSize = size * _taglineRatio;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SvgPicture.asset(
          white ? AppAssets.logoMarkWhite : AppAssets.logoMarkGreen,
          width: size.r,
          height: (size * _markAspect).r,
        ),
        SizedBox(height: (size * _gapRatio).r),
        Text(
          AppStrings.wordmark,
          style: AppTypography.display(
            wordSize,
            color: color,
            height: 1,
            letterSpacing: (wordSize * _wordTracking).sp,
          ),
        ),
        if (tagline) ...<Widget>[
          SizedBox(height: (size * _gapRatio).r),
          Text(
            AppStrings.logoTagline,
            style: AppTypography.display(
              tagSize,
              color: white ? AppColors.white : AppColors.ink900,
              height: 1,
              letterSpacing: (tagSize * _taglineTracking).sp,
            ),
          ),
        ],
      ],
    );
  }
}
