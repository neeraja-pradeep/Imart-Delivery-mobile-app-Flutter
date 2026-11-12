import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/theme.dart';
import 'package:imart_delivery_app/app/theme/typography.dart';
import 'package:imart_delivery_app/core/utils/format_utils.dart';
import 'package:imart_delivery_app/core/widgets/app_card.dart';
import 'package:imart_delivery_app/core/widgets/app_icon.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/delivery_stop.dart';

/// Compact stop row on Arrange Route with up/down reorder arrows.
class ArrangeStopTile extends StatelessWidget {
  /// Creates the tile.
  const ArrangeStopTile({
    super.key,
    required this.stop,
    required this.sequence,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  /// Stop shown.
  final DeliveryStop stop;

  /// 1-based position.
  final int sequence;

  /// Up arrow enabled.
  final bool canMoveUp;

  /// Down arrow enabled.
  final bool canMoveDown;

  /// Up handler.
  final VoidCallback onMoveUp;

  /// Down handler.
  final VoidCallback onMoveDown;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: AppRadii.lg,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: <Widget>[
          Container(
            width: 26.r,
            height: 26.r,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.brand,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$sequence',
              style: AppTypography.display(13, color: AppColors.white),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  stop.customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.display(14),
                ),
                Text(
                  '${stop.area} · ${FormatUtils.stopKm(stop.distanceKm)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _ArrowButton(
                glyph: AppIconGlyph.caretUp,
                label: AppStrings.moveUp,
                enabled: canMoveUp,
                onTap: onMoveUp,
              ),
              SizedBox(height: 4.h),
              _ArrowButton(
                glyph: AppIconGlyph.caretDown,
                label: AppStrings.moveDown,
                enabled: canMoveDown,
                onTap: onMoveDown,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.glyph,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  static const double _disabledOpacity = 0.35;

  final AppIconGlyph glyph;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: Opacity(
          opacity: enabled ? 1 : _disabledOpacity,
          child: Container(
            width: 38.w,
            height: 30.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadii.sm.r),
              border: Border.all(color: AppColors.line),
            ),
            child: AppIcon(
              glyph,
              size: 16,
              color: AppColors.ink800,
              strokeWidth: 2.4,
            ),
          ),
        ),
      ),
    );
  }
}
