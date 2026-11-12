import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/theme.dart';
import 'package:imart_delivery_app/app/theme/typography.dart';
import 'package:imart_delivery_app/core/widgets/app_icon.dart';

/// Toast colourways.
enum AppToastTone {
  /// Dark green with mint text — success.
  success(AppColors.toastSuccessBg, AppColors.toastSuccessFg),

  /// Dark amber with yellow text — warning (failed delivery).
  warning(AppColors.toastWarningBg, AppColors.toastWarningFg),

  /// Charcoal with white text — neutral (order removed).
  muted(AppColors.ink800, AppColors.white);

  const AppToastTone(this.background, this.foreground);

  /// Pill fill.
  final Color background;

  /// Text / icon colour.
  final Color foreground;
}

/// Transient pill confirmation with a check icon.
class AppToast extends StatelessWidget {
  /// Creates a toast.
  const AppToast({super.key, required this.message, required this.tone});

  static const double _maxWidthFactor = 0.88;

  /// Message text.
  final String message;

  /// Colourway.
  final AppToastTone tone;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: _maxWidthFactor.sw),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 11.h),
        decoration: BoxDecoration(
          color: tone.background,
          borderRadius: BorderRadius.circular(AppRadii.pill.r),
          boxShadow: AppShadows.toast,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppIcon(
              AppIconGlyph.check,
              size: 16,
              color: tone.foreground,
              strokeWidth: 2.4,
            ),
            SizedBox(width: 9.w),
            Flexible(
              child: Text(
                message,
                style: AppTypography.display(
                  13.5,
                  weight: FontWeight.w600,
                  color: tone.foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
