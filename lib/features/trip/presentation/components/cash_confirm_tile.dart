import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/theme.dart';
import 'package:imart_delivery_app/app/theme/typography.dart';
import 'package:imart_delivery_app/core/widgets/app_icon.dart';

/// Required "I have collected ₹… in cash" checkbox for COD orders.
class CashConfirmTile extends StatelessWidget {
  /// Creates the tile.
  const CashConfirmTile({
    super.key,
    required this.amount,
    required this.checked,
    required this.onToggle,
  });

  static const double _boxRadius = 7;

  /// Formatted amount.
  final String amount;

  /// Ticked.
  final bool checked;

  /// Toggle handler.
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final TextStyle text = AppTypography.body(13.5, height: 1.35);
    return Semantics(
      checked: checked,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onToggle,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 13.h),
          decoration: BoxDecoration(
            color: checked ? AppColors.surfaceTint : AppColors.coralTint7,
            borderRadius: BorderRadius.circular(AppRadii.lg.r),
            border: Border.all(
              color: checked ? AppColors.action : AppColors.coral,
              width: 1.5,
            ),
          ),
          child: Row(
            children: <Widget>[
              AnimatedContainer(
                duration: AppDurations.fast,
                width: 24.r,
                height: 24.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: checked ? AppColors.action : AppColors.white,
                  borderRadius: BorderRadius.circular(_boxRadius.r),
                  border: Border.all(
                    color: checked ? AppColors.action : AppColors.coral,
                    width: checked ? 1.5 : 2,
                  ),
                ),
                child: checked
                    ? const AppIcon(
                        AppIconGlyph.check,
                        size: 14,
                        color: AppColors.white,
                        strokeWidth: 3,
                      )
                    : null,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: AppStrings.cashCollectedPrefix,
                    children: <InlineSpan>[
                      TextSpan(
                        text: amount,
                        style: text.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(text: AppStrings.cashCollectedSuffix),
                    ],
                  ),
                  style: text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
