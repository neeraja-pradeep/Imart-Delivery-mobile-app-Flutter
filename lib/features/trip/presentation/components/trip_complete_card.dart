import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/theme.dart';
import 'package:imart_delivery_app/app/theme/typography.dart';
import 'package:imart_delivery_app/core/utils/format_utils.dart';
import 'package:imart_delivery_app/core/widgets/app_icon.dart';
import 'package:imart_delivery_app/core/widgets/app_stat_tile.dart';

/// Trip-complete results: Delivered / Failed / Distance, return note and
/// cash to deposit.
class TripCompleteCard extends StatelessWidget {
  /// Creates the card.
  const TripCompleteCard({
    super.key,
    required this.delivered,
    required this.failed,
    required this.distanceKm,
    required this.codCollected,
  });

  /// Delivered count.
  final int delivered;

  /// Failed count.
  final int failed;

  /// Route distance.
  final double distanceKm;

  /// Cash collected (rupees).
  final int codCollected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.xxl.r),
        boxShadow: AppShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: AppStatTile(
                    value: '$delivered',
                    label: AppStrings.delivered,
                    valueSize: 24,
                    valueColor: AppColors.action,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      border: Border.symmetric(
                        vertical: BorderSide(color: AppColors.line),
                      ),
                    ),
                    child: AppStatTile(
                      value: '$failed',
                      label: AppStrings.failed,
                      valueSize: 24,
                      valueColor: AppColors.coral,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: AppStatTile(
                    value: FormatUtils.km(distanceKm),
                    label: AppStrings.distance,
                    valueSize: 24,
                    valueColor: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (failed > 0) _ReturnNote(failed: failed),
          if (codCollected > 0) _CashRow(amount: codCollected),
        ],
      ),
    );
  }
}

class _ReturnNote extends StatelessWidget {
  const _ReturnNote({required this.failed});

  final int failed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 16.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.amberTint,
        borderRadius: BorderRadius.circular(AppRadii.md.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(top: 1.h),
            child: const AppIcon(
              AppIconGlyph.bag,
              size: 18,
              color: AppColors.amber,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              AppStrings.returnNote(failed),
              style: AppTypography.body(
                12.5,
                color: AppColors.amberOnTint,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CashRow extends StatelessWidget {
  const _CashRow({required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 14.h),
      padding: EdgeInsets.only(top: 14.h),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            children: <Widget>[
              const AppIcon(
                AppIconGlyph.card,
                size: 17,
                color: AppColors.amber,
              ),
              SizedBox(width: 8.w),
              Text(
                AppStrings.cashToDeposit,
                style: AppTypography.body(13, color: AppColors.textSecondary),
              ),
            ],
          ),
          Text(FormatUtils.rupees(amount), style: AppTypography.display(16)),
        ],
      ),
    );
  }
}
