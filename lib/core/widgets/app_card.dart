import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/theme.dart';

/// White surface card: hairline border, soft shadow, rounded corners.
class AppCard extends StatelessWidget {
  /// Creates a card.
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = AppRadii.card,
    this.borderColor = AppColors.borderHairline,
    this.borderWidth = 1,
    this.onTap,
  });

  /// Card content.
  final Widget child;

  /// Inner padding (design px, scaled internally).
  final EdgeInsets padding;

  /// Corner radius (design px).
  final double radius;

  /// Border colour.
  final Color borderColor;

  /// Border width (logical px, unscaled like CSS borders).
  final double borderWidth;

  /// Optional tap handler.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget card = AnimatedContainer(
      duration: AppDurations.base,
      padding: EdgeInsets.fromLTRB(
        padding.left.w,
        padding.top.h,
        padding.right.w,
        padding.bottom.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(radius.r),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: AppShadows.card,
      ),
      child: child,
    );
    if (onTap == null) {
      return card;
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: card,
    );
  }
}
