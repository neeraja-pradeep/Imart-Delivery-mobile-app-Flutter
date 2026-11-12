import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/theme.dart';
import 'package:imart_delivery_app/app/theme/typography.dart';
import 'package:imart_delivery_app/core/widgets/app_back_button.dart';

/// Brand turn banner on the map: back arrow, next manoeuvre, stop · ETA.
class NavigationHeaderSection extends StatelessWidget {
  /// Creates the banner.
  const NavigationHeaderSection({
    super.key,
    required this.turn,
    required this.subtitle,
    required this.onBack,
  });

  /// Next manoeuvre.
  final String turn;

  /// "Stop 1 of 4 · ETA 8 min".
  final String subtitle;

  /// Back to the route list.
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.brand,
      padding: EdgeInsets.fromLTRB(
        18.w,
        AppSizes.topInset(context, AppSizes.headerTop),
        18.w,
        14.h,
      ),
      child: Row(
        children: <Widget>[
          AppBackButton(
            style: AppBackButtonStyle.plainWhite,
            onPressed: onBack,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  turn,
                  style: AppTypography.display(
                    16,
                    color: AppColors.white,
                    height: 1.2,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.body(12, color: AppColors.white78),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
