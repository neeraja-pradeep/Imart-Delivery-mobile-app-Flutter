import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/theme.dart';
import 'package:imart_delivery_app/app/theme/typography.dart';
import 'package:imart_delivery_app/core/utils/date_utils.dart';
import 'package:imart_delivery_app/features/profile/application/providers/profile_providers.dart';
import 'package:imart_delivery_app/features/profile/domain/entities/rider_profile.dart';

/// Curved brand header: greeting, rider name, hub and "On Duty" pill.
class TripHeaderSection extends ConsumerWidget {
  /// Creates the header.
  const TripHeaderSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RiderProfile? profile = ref
        .watch(profileControllerProvider)
        .valueOrNull;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        22.w,
        AppSizes.topInset(context, AppSizes.headerTop),
        22.w,
        20.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.brand,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadii.header.r),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  AppDateUtils.greeting(AppClock.now()),
                  style: AppTypography.body(13, color: AppColors.white72),
                ),
                SizedBox(height: 2.h),
                Text(
                  profile?.name ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.display(25, color: AppColors.white),
                ),
                SizedBox(height: 4.h),
                Text(
                  profile?.hubName ?? '',
                  style: AppTypography.body(12, color: AppColors.white72),
                ),
              ],
            ),
          ),
          const _OnDutyPill(),
        ],
      ),
    );
  }
}

class _OnDutyPill extends StatelessWidget {
  const _OnDutyPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: AppColors.white16,
        borderRadius: BorderRadius.circular(AppRadii.pill.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 7.r,
            height: 7.r,
            decoration: const BoxDecoration(
              color: AppColors.onlineDot,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            AppStrings.onDuty,
            style: AppTypography.display(
              12,
              weight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}
