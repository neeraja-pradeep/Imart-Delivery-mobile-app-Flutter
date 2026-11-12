import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/typography.dart';
import 'package:imart_delivery_app/core/widgets/app_button.dart';
import 'package:imart_delivery_app/core/widgets/app_icon.dart';

/// Visual recipe for an [ErrorView] icon disc.
class ErrorViewIcon {
  /// Creates an icon recipe.
  const ErrorViewIcon({
    required this.glyph,
    required this.circleSize,
    required this.iconSize,
    required this.circleColor,
    required this.iconColor,
    this.strokeWidth = 1.8,
  });

  /// Glyph inside the disc.
  final AppIconGlyph glyph;

  /// Disc diameter (design px).
  final double circleSize;

  /// Glyph size (design px).
  final double iconSize;

  /// Disc fill.
  final Color circleColor;

  /// Glyph colour.
  final Color iconColor;

  /// Glyph stroke width.
  final double strokeWidth;
}

/// Centered full-screen state: icon disc, title, message, single action.
///
/// Used for every generic error / empty / blocked state in the app
/// (Connection Lost, No Trip Assigned, On Leave, Navigation Locked).
class ErrorView extends StatelessWidget {
  /// Creates the state view.
  const ErrorView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.titleSize = 19,
    this.bottomPadding = 110,
  });

  /// Icon disc recipe.
  final ErrorViewIcon icon;

  /// Bold title.
  final String title;

  /// Supporting copy.
  final String message;

  /// Action button label.
  final String actionLabel;

  /// Action handler.
  final VoidCallback onAction;

  /// Title font size.
  final double titleSize;

  /// Bottom padding — keeps content visually centred above the nav.
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final double gap = 16.h;
    return ColoredBox(
      color: AppColors.white,
      child: Padding(
        padding: EdgeInsets.fromLTRB(34.w, 48.h, 34.w, bottomPadding.h),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: icon.circleSize.r,
                height: icon.circleSize.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: icon.circleColor,
                  shape: BoxShape.circle,
                ),
                child: AppIcon(
                  icon.glyph,
                  size: icon.iconSize,
                  color: icon.iconColor,
                  strokeWidth: icon.strokeWidth,
                ),
              ),
              SizedBox(height: gap),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.display(titleSize),
              ),
              SizedBox(height: gap),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.body(
                  14,
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),
              SizedBox(height: gap),
              AppButton(
                label: actionLabel,
                onPressed: onAction,
                size: AppButtonSize.md,
                expand: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
