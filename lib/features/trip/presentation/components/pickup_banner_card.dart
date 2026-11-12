import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/theme.dart';
import 'package:imart_delivery_app/app/theme/typography.dart';
import 'package:imart_delivery_app/core/widgets/app_icon.dart';

/// Brand-green "Pickup from Warehouse" banner with selection count.
class PickupBannerCard extends StatelessWidget {
  /// Creates the banner.
  const PickupBannerCard({
    super.key,
    required this.picked,
    required this.total,
  });

  /// Orders selected.
  final int picked;

  /// Orders assigned.
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: AppColors.brand,
        borderRadius: BorderRadius.circular(AppRadii.xl.r),
      ),
      child: Row(
        children: <Widget>[
          const AppIcon(
            AppIconGlyph.bag,
            size: 22,
            color: AppColors.white,
            strokeWidth: 1.8,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  AppStrings.pickupFromWarehouse,
                  style: AppTypography.display(15, color: AppColors.white),
                ),
                SizedBox(height: 2.h),
                Text(
                  AppStrings.chooseOrders(picked, total),
                  style: AppTypography.body(12, color: AppColors.white80),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
