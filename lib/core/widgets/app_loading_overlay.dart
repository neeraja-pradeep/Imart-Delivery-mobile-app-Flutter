import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/theme.dart';
import 'package:imart_delivery_app/app/theme/typography.dart';

/// Full-screen branded loading state: spinner + status message.
class AppLoadingOverlay extends StatelessWidget {
  /// Creates the overlay.
  const AppLoadingOverlay({super.key, required this.message});

  /// Status message under the spinner.
  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.loadingScrim,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const AppSpinner(),
            SizedBox(height: 18.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.display(
                14,
                weight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 48px ring spinner with an action-green top arc.
class AppSpinner extends StatefulWidget {
  /// Creates a spinner.
  const AppSpinner({super.key, this.size = 48});

  /// Diameter in design px.
  final double size;

  @override
  State<AppSpinner> createState() => _AppSpinnerState();
}

class _AppSpinnerState extends State<AppSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.spin,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: CustomPaint(
        size: Size.square(widget.size.r),
        painter: _RingPainter(stroke: 4.r),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.stroke});

  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = (Offset.zero & size).deflate(stroke / 2);
    final Paint track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.surfaceInset;
    final Paint arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.action;
    canvas
      ..drawArc(rect, 0, math.pi * 2, false, track)
      ..drawArc(rect, -math.pi * 3 / 4, math.pi / 2, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => oldDelegate.stroke != stroke;
}
