import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/theme.dart';
import 'package:imart_delivery_app/core/widgets/app_icon.dart';

/// Back-button styles used in the design.
enum AppBackButtonStyle {
  /// 44px white circle with a brand-green arrow (sub-page headers).
  circle,

  /// Bare brand-green arrow on light background (login).
  plainBrand,

  /// Bare white arrow on brand background (map header).
  plainWhite,
}

/// 44 × 44 back control.
class AppBackButton extends StatelessWidget {
  /// Creates a back button.
  const AppBackButton({
    super.key,
    required this.onPressed,
    this.style = AppBackButtonStyle.circle,
  });

  /// Tap handler.
  final VoidCallback onPressed;

  /// Visual style.
  final AppBackButtonStyle style;

  @override
  Widget build(BuildContext context) {
    final bool circle = style == AppBackButtonStyle.circle;
    final Color arrow = style == AppBackButtonStyle.plainWhite
        ? AppColors.white
        : AppColors.brand;
    final double iconSize = switch (style) {
      AppBackButtonStyle.circle => 22,
      AppBackButtonStyle.plainBrand => 24,
      AppBackButtonStyle.plainWhite => 26,
    };
    final double stroke = circle ? 2.4 : 2.2;
    return Semantics(
      button: true,
      label: AppStrings.back,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          width: AppSizes.tapMin.r,
          height: AppSizes.tapMin.r,
          alignment: Alignment.center,
          decoration: circle
              ? const BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                )
              : null,
          child: AppIcon(
            AppIconGlyph.arrowLeft,
            size: iconSize,
            color: arrow,
            strokeWidth: stroke,
          ),
        ),
      ),
    );
  }
}
