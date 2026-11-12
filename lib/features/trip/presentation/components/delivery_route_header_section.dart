import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/typography.dart';

/// "Delivery Route" title with a phase-specific hint.
class DeliveryRouteHeaderSection extends StatelessWidget {
  /// Creates the header.
  const DeliveryRouteHeaderSection({super.key, required this.pickup});

  /// Pickup phase (else enroute).
  final bool pickup;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(AppStrings.deliveryRoute, style: AppTypography.display(15)),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              pickup ? AppStrings.setOrderNext : AppStrings.tapStopForDetails,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: AppTypography.body(12, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
