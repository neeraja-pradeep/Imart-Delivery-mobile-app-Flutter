import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/theme.dart';

/// 6px rounded progress track with an animated action-green fill.
class AppProgressBar extends StatelessWidget {
  /// Creates a progress bar.
  const AppProgressBar({super.key, required this.fraction});

  /// Progress in `0..1`.
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadii.pill.r);
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        height: 6.h,
        color: AppColors.surfaceInset,
        alignment: Alignment.centerLeft,
        child: AnimatedFractionallySizedBox(
          duration: AppDurations.progress,
          widthFactor: fraction.clamp(0, 1),
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.action,
              borderRadius: radius,
            ),
          ),
        ),
      ),
    );
  }
}
