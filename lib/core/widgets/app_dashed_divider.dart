import 'package:flutter/material.dart';

import 'package:imart_delivery_app/app/theme/colors.dart';

/// 1px dashed horizontal rule (CSS `border-top: 1px dashed`).
class AppDashedDivider extends StatelessWidget {
  /// Creates a dashed rule.
  const AppDashedDivider({super.key, this.color = AppColors.line});

  /// Dash colour.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      width: double.infinity,
      child: CustomPaint(painter: _DashPainter(color)),
    );
  }
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color);

  static const double _dash = 3;
  static const double _gap = 3;

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    double x = 0;
    while (x < size.width) {
      final double end = (x + _dash).clamp(0, size.width);
      canvas.drawRect(Rect.fromLTRB(x, 0, end, size.height), paint);
      x += _dash + _gap;
    }
  }

  @override
  bool shouldRepaint(_DashPainter oldDelegate) => oldDelegate.color != color;
}
