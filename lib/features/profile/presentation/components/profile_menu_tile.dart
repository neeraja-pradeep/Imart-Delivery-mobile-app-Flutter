import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/typography.dart';
import 'package:imart_delivery_app/core/widgets/app_card.dart';
import 'package:imart_delivery_app/core/widgets/app_icon.dart';

/// Profile menu row: green icon disc + label.
class ProfileMenuTile extends StatelessWidget {
  /// Creates the row.
  const ProfileMenuTile({
    super.key,
    required this.glyph,
    required this.label,
    required this.onTap,
  });

  /// Icon.
  final AppIconGlyph glyph;

  /// Label.
  final String label;

  /// Tap handler.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: <Widget>[
            Container(
              width: 36.r,
              height: 36.r,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.action,
                shape: BoxShape.circle,
              ),
              child: AppIcon(glyph, size: 18, color: AppColors.white),
            ),
            SizedBox(width: 16.w),
            Text(label, style: AppTypography.body(16)),
          ],
        ),
      ),
    );
  }
}
