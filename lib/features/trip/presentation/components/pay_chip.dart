import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/theme.dart';
import 'package:imart_delivery_app/app/theme/typography.dart';
import 'package:imart_delivery_app/core/utils/format_utils.dart';
import 'package:imart_delivery_app/core/widgets/app_icon.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/payment_mode.dart';

/// Payment strip sizes.
enum PayChipSize {
  /// Card / confirm-sheet strip.
  small,

  /// Navigation panel strip.
  large,
}

/// Amber "Collect ₹312 · Cash on Delivery" or green "Prepaid · ₹845 (no
/// collection)" strip.
class PayChip extends StatelessWidget {
  /// Creates the strip.
  const PayChip({
    super.key,
    required this.mode,
    required this.amount,
    this.size = PayChipSize.small,
    this.showIcon = true,
    this.centered = false,
  });

  /// Payment mode.
  final PaymentMode mode;

  /// Amount in rupees.
  final int amount;

  /// Size preset.
  final PayChipSize size;

  /// Leading card icon (the confirm sheet omits it).
  final bool showIcon;

  /// Center the content (confirm sheet).
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final bool cod = mode == PaymentMode.cod;
    final bool large = size == PayChipSize.large;
    final Color fg = cod ? AppColors.amberOnTint : AppColors.green800;
    final String value = FormatUtils.rupees(amount);
    final String text = cod
        ? AppStrings.collectCod(value)
        : AppStrings.prepaidNoCollection(value);
    return Container(
      width: double.infinity,
      padding: large
          ? EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h)
          : EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: cod ? AppColors.amberTint : AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(AppRadii.md.r),
      ),
      child: Row(
        mainAxisAlignment: centered
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: <Widget>[
          if (showIcon) ...<Widget>[
            AppIcon(AppIconGlyph.card, size: large ? 16 : 15, color: fg),
            SizedBox(width: 8.w),
          ],
          Flexible(
            child: Text(
              text,
              style: AppTypography.body(
                large ? 13 : 12.5,
                weight: large ? FontWeight.w600 : FontWeight.w400,
                color: fg,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
