import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/typography.dart';
import 'package:imart_delivery_app/core/utils/date_utils.dart';
import 'package:imart_delivery_app/core/utils/format_utils.dart';
import 'package:imart_delivery_app/core/widgets/app_card.dart';
import 'package:imart_delivery_app/features/profile/domain/entities/trip_history_entry.dart';

/// One past trip: date, stops · failed · km, and payout.
class TripHistoryTile extends StatelessWidget {
  /// Creates the tile.
  const TripHistoryTile({super.key, required this.entry});

  /// Entry shown.
  final TripHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  AppDateUtils.historyLabel(entry.date, AppClock.now()),
                  style: AppTypography.display(15),
                ),
                SizedBox(height: 3.h),
                Text(
                  AppStrings.historySummary(
                    entry.stops,
                    entry.failed,
                    FormatUtils.km(entry.distanceKm),
                  ),
                  style: AppTypography.body(12.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                FormatUtils.rupees(entry.earned),
                style: AppTypography.display(16, color: AppColors.action),
              ),
              Text(
                AppStrings.earned,
                style: AppTypography.body(11, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
