import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/typography.dart';
import 'package:imart_delivery_app/core/widgets/app_icon.dart';

/// Coral "No internet connection" strip shown under the status bar.
class AppOfflineBanner extends StatelessWidget {
  /// Creates the banner.
  const AppOfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.coral,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const AppIcon(AppIconGlyph.wifiOff, size: 15, color: AppColors.white),
          SizedBox(width: 8.w),
          Text(
            AppStrings.noInternet,
            style: AppTypography.display(
              12.5,
              weight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}
