import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/theme.dart';
import 'package:imart_delivery_app/app/theme/typography.dart';

/// Badge tones from the design-system `Badge` (subtle variant).
enum AppBadgeTone {
  /// Green — Delivered, Prepaid, Arrived.
  green(AppColors.green800, AppColors.green100),

  /// Red — Failed.
  red(AppColors.redFg, AppColors.redTint),

  /// Amber — COD, Out for Delivery.
  amber(AppColors.amberFg, AppColors.amberTint),

  /// Blue — Picked Up.
  blue(AppColors.blueFg, AppColors.blueTint),

  /// Violet — Assigned.
  violet(AppColors.violetFg, AppColors.violetTint);

  const AppBadgeTone(this.foreground, this.tint);

  /// Text colour.
  final Color foreground;

  /// Fill colour.
  final Color tint;
}

/// Soft tinted status pill.
class AppBadge extends StatelessWidget {
  /// Creates a badge.
  const AppBadge({super.key, required this.label, required this.tone});

  /// Badge text.
  final String label;

  /// Colour tone.
  final AppBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: tone.tint,
        borderRadius: BorderRadius.circular(AppRadii.pill.r),
        border: Border.all(color: Colors.transparent),
      ),
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        style: AppTypography.body(
          12,
          weight: FontWeight.w500,
          color: tone.foreground,
          height: 1,
        ),
      ),
    );
  }
}
