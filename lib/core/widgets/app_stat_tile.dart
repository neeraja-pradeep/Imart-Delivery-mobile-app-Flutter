import 'package:flutter/material.dart';

import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/typography.dart';

/// Centered value-over-label metric used by the trip summary, profile
/// stats and trip-complete card. The container is supplied by the caller.
class AppStatTile extends StatelessWidget {
  /// Creates a metric.
  const AppStatTile({
    super.key,
    required this.value,
    required this.label,
    this.valueSize = 18,
    this.valueColor = AppColors.brand,
  });

  /// Metric value.
  final String value;

  /// Caption under the value.
  final String label;

  /// Value font size.
  final double valueSize;

  /// Value colour.
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          value,
          textAlign: TextAlign.center,
          style: AppTypography.display(valueSize, color: valueColor),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.body(11, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
