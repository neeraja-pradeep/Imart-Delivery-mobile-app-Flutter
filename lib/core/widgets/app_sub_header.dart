import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/theme.dart';
import 'package:imart_delivery_app/app/theme/typography.dart';
import 'package:imart_delivery_app/core/widgets/app_back_button.dart';

/// Flat brand-green header with a circular back button and a title
/// (Edit Profile, Trip History, Arrange Route).
class AppSubHeader extends StatelessWidget {
  /// Creates a sub-page header.
  const AppSubHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.subtitle,
    this.titleSize = 22,
    this.bottomPadding = 18,
  });

  /// Title text.
  final String title;

  /// Optional subtitle under the title.
  final String? subtitle;

  /// Back handler.
  final VoidCallback onBack;

  /// Title font size (22 for profile pages, 20 for Arrange Route).
  final double titleSize;

  /// Bottom padding (18 for profile pages, 16 for Arrange Route).
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.brand,
      padding: EdgeInsets.fromLTRB(
        18.w,
        AppSizes.topInset(context, AppSizes.headerTop),
        18.w,
        bottomPadding.h,
      ),
      child: Row(
        children: <Widget>[
          AppBackButton(onPressed: onBack),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  style: AppTypography.display(
                    titleSize,
                    color: AppColors.white,
                  ),
                ),
                if (subtitle != null) ...<Widget>[
                  SizedBox(height: 2.h),
                  Text(
                    subtitle!,
                    style: AppTypography.body(12, color: AppColors.white78),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
