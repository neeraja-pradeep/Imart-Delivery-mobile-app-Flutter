import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/typography.dart';
import 'package:imart_delivery_app/core/widgets/app_icon.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/order_status.dart';

/// 28px sequence disc on a stop card; turns into a check once collected
/// or delivered.
class StopNumberBadge extends StatelessWidget {
  /// Creates the disc.
  const StopNumberBadge({
    super.key,
    required this.sequence,
    required this.status,
    required this.isCurrent,
  });

  /// 1-based position.
  final int sequence;

  /// Order status.
  final OrderStatus status;

  /// Whether this is the stop being delivered.
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final bool check =
        status == OrderStatus.delivered || status == OrderStatus.pickedUp;
    final bool onColour = status != OrderStatus.assigned;
    final Color background = switch (status) {
      OrderStatus.failed => AppColors.coral,
      _ when isCurrent => AppColors.brand,
      OrderStatus.delivered || OrderStatus.pickedUp => AppColors.action,
      _ => AppColors.surfaceInset,
    };
    return Container(
      width: 28.r,
      height: 28.r,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: check
          ? const AppIcon(
              AppIconGlyph.check,
              size: 16,
              color: AppColors.white,
              strokeWidth: 3,
            )
          : Text(
              '$sequence',
              style: AppTypography.display(
                13,
                color: onColour ? AppColors.white : AppColors.textSecondary,
              ),
            ),
    );
  }
}
