import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/typography.dart';

/// Vertical list of lines with a small green dot (order contents).
class AppBulletList extends StatelessWidget {
  /// Creates a bullet list.
  const AppBulletList({super.key, required this.items, this.gap = 6});

  /// Lines to render.
  final List<String> items;

  /// Vertical gap between lines (design px).
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < items.length; i++) ...<Widget>[
          if (i > 0) SizedBox(height: gap.h),
          _BulletLine(text: items[i]),
        ],
      ],
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned(
          left: 0,
          top: 8.h,
          child: Container(
            width: 5.r,
            height: 5.r,
            decoration: const BoxDecoration(
              color: AppColors.action,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: 15.w),
          child: Text(text, style: AppTypography.body(13, height: 1.5)),
        ),
      ],
    );
  }
}
