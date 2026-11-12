import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/theme.dart';
import 'package:imart_delivery_app/app/theme/typography.dart';

/// Circular avatar with branded-initial fallback.
class AppAvatar extends StatelessWidget {
  /// Creates an avatar.
  const AppAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 48,
    this.ring = false,
  });

  static const double _initialRatio = 0.4;

  /// Name used for the initial fallback.
  final String name;

  /// Optional network image.
  final String? imageUrl;

  /// Diameter in design px.
  final double size;

  /// White 2px ring with soft shadow.
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final String trimmed = name.trim();
    final String initial = trimmed.isEmpty
        ? '?'
        : trimmed.substring(0, 1).toUpperCase();
    return Container(
      width: size.r,
      height: size.r,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceTint,
        border: ring ? Border.all(color: AppColors.white, width: 2) : null,
        boxShadow: ring ? AppShadows.sm : null,
      ),
      child: imageUrl == null
          ? Text(
              initial,
              style: AppTypography.display(
                size * _initialRatio,
                weight: FontWeight.w600,
                color: AppColors.brand,
              ),
            )
          : Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              width: size.r,
              height: size.r,
            ),
    );
  }
}
