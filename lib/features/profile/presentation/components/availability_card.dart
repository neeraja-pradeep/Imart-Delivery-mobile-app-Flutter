import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/theme.dart';
import 'package:imart_delivery_app/app/theme/typography.dart';
import 'package:imart_delivery_app/core/widgets/app_card.dart';
import 'package:imart_delivery_app/core/widgets/app_icon.dart';

/// Availability card: On Duty / On Leave status with the leave action.
///
/// "Mark Leave" is only enabled once the trip is complete.
class AvailabilityCard extends StatelessWidget {
  /// Creates the card.
  const AvailabilityCard({
    super.key,
    required this.onLeave,
    required this.canMarkLeave,
    required this.onMarkLeave,
    required this.onEndLeave,
  });

  /// Rider is on leave.
  final bool onLeave;

  /// Leave can be applied now.
  final bool canMarkLeave;

  /// "Mark Leave".
  final VoidCallback onMarkLeave;

  /// "End Leave".
  final VoidCallback onEndLeave;

  @override
  Widget build(BuildContext context) {
    final Color tone = onLeave ? AppColors.amber : AppColors.action;
    final String note = onLeave
        ? AppStrings.leaveNoteOnLeave
        : (canMarkLeave
              ? AppStrings.leaveNoteAvailable
              : AppStrings.leaveNoteBlocked);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 38.r,
                height: 38.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: onLeave ? AppColors.amberTint : AppColors.surfaceTint,
                  shape: BoxShape.circle,
                ),
                child: AppIcon(AppIconGlyph.clock, size: 19, color: tone),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      AppStrings.availability,
                      style: AppTypography.body(11, color: AppColors.textMuted),
                    ),
                    Text(
                      onLeave ? AppStrings.onLeave : AppStrings.onDuty,
                      style: AppTypography.display(15, color: tone),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              _LeaveButton(
                onLeave: onLeave,
                enabled: onLeave || canMarkLeave,
                onTap: onLeave ? onEndLeave : onMarkLeave,
              ),
            ],
          ),
          Container(
            margin: EdgeInsets.only(top: 12.h),
            padding: EdgeInsets.only(top: 12.h),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: Text(
              note,
              style: AppTypography.body(
                12,
                color: AppColors.textMuted,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaveButton extends StatelessWidget {
  const _LeaveButton({
    required this.onLeave,
    required this.enabled,
    required this.onTap,
  });

  final bool onLeave;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    late final Color background;
    late final Color foreground;
    late final Border border;
    if (!enabled) {
      background = AppColors.surfaceInset;
      foreground = AppColors.ink400;
      border = Border.all(color: AppColors.line);
    } else if (onLeave) {
      background = AppColors.action;
      foreground = AppColors.white;
      border = Border.all(color: Colors.transparent, width: 0);
    } else {
      background = Colors.transparent;
      foreground = AppColors.coral;
      border = Border.all(color: AppColors.coral, width: 1.5);
    }
    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: Container(
          height: 40.h,
          padding: EdgeInsets.symmetric(horizontal: 18.w),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppRadii.pill.r),
            border: border,
          ),
          child: Text(
            onLeave ? AppStrings.endLeave : AppStrings.markLeave,
            style: AppTypography.display(
              13,
              weight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }
}
