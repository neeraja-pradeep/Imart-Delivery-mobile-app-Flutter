import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/theme.dart';
import 'package:imart_delivery_app/app/theme/typography.dart';
import 'package:imart_delivery_app/core/widgets/app_badge.dart';
import 'package:imart_delivery_app/core/widgets/app_button.dart';
import 'package:imart_delivery_app/core/widgets/app_icon.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/delivery_stop.dart';
import 'package:imart_delivery_app/features/trip/presentation/components/pay_chip.dart';

/// Persistent panel over the map for the current stop: customer, address,
/// payment, Call / Navigate, then "I've Arrived" → "Mark Delivered", and
/// "Failed Delivery".
class DeliveryPanelCard extends StatelessWidget {
  /// Creates the panel.
  const DeliveryPanelCard({
    super.key,
    required this.stop,
    required this.arrived,
    required this.onCall,
    required this.onNavigate,
    required this.onArrived,
    required this.onDelivered,
    required this.onFailed,
  });

  /// Current stop.
  final DeliveryStop stop;

  /// Arrival confirmed.
  final bool arrived;

  /// Call customer.
  final VoidCallback onCall;

  /// Open turn-by-turn.
  final VoidCallback onNavigate;

  /// "I've Arrived".
  final VoidCallback onArrived;

  /// "Mark Delivered".
  final VoidCallback onDelivered;

  /// "Failed Delivery".
  final VoidCallback onFailed;

  @override
  Widget build(BuildContext context) {
    final TextStyle meta = AppTypography.body(12, color: AppColors.textMuted);
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.sheetMap.r),
        ),
        boxShadow: AppShadows.sheet,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: Container(
              width: 38.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.borderField,
                borderRadius: BorderRadius.circular(AppRadii.pill.r),
              ),
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  stop.customerName,
                  style: AppTypography.display(17),
                ),
              ),
              SizedBox(width: 8.w),
              AppBadge(
                label: arrived
                    ? AppStrings.arrivedBadge
                    : AppStrings.outForDelivery,
                tone: arrived ? AppBadgeTone.green : AppBadgeTone.amber,
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            stop.address,
            style: AppTypography.body(
              13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          SizedBox(height: 6.h),
          Row(
            children: <Widget>[
              Text(AppStrings.orderId(stop.orderId), style: meta),
              SizedBox(width: 16.w),
              Text(AppStrings.itemCount(stop.itemCount), style: meta),
            ],
          ),
          SizedBox(height: 12.h),
          PayChip(
            mode: stop.paymentMode,
            amount: stop.amount,
            size: PayChipSize.large,
          ),
          SizedBox(height: 14.h),
          Row(
            children: <Widget>[
              Expanded(
                child: AppButton(
                  label: AppStrings.call,
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.md,
                  leading: const AppIcon(
                    AppIconGlyph.phone,
                    size: 16,
                    color: AppColors.action,
                    strokeWidth: 1.9,
                  ),
                  onPressed: onCall,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: AppButton(
                  label: AppStrings.navigate,
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.md,
                  leading: const AppIcon(
                    AppIconGlyph.navigation,
                    size: 16,
                    color: AppColors.action,
                    strokeWidth: 1.9,
                  ),
                  onPressed: onNavigate,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          if (arrived)
            AppButton(
              label: AppStrings.markDelivered,
              leading: const AppIcon(
                AppIconGlyph.check,
                size: 18,
                color: AppColors.white,
                strokeWidth: 2.4,
              ),
              onPressed: onDelivered,
            )
          else
            AppButton(
              label: AppStrings.iveArrived,
              leading: const AppIcon(
                AppIconGlyph.pin,
                size: 18,
                color: AppColors.white,
              ),
              onPressed: onArrived,
            ),
          SizedBox(height: 8.h),
          AppButton(
            label: AppStrings.failedDelivery,
            variant: AppButtonVariant.dangerOutline,
            height: AppSizes.tapMin,
            fontSize: 14,
            onPressed: onFailed,
          ),
        ],
      ),
    );
  }
}
