import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/theme.dart';
import 'package:imart_delivery_app/app/theme/typography.dart';
import 'package:imart_delivery_app/core/utils/format_utils.dart';
import 'package:imart_delivery_app/core/widgets/app_card.dart';
import 'package:imart_delivery_app/core/widgets/app_progress_bar.dart';
import 'package:imart_delivery_app/core/widgets/app_stat_tile.dart';
import 'package:imart_delivery_app/features/trip/application/states/trip_state.dart';

/// "Today's Trip" card: progress label, Stops / Items / Est. Time tiles and
/// a progress bar.
class TripSummaryCard extends StatelessWidget {
  /// Creates the card.
  const TripSummaryCard({super.key, required this.trip});

  /// Trip state to summarise.
  final TripState trip;

  @override
  Widget build(BuildContext context) {
    final bool pickup = trip.phase == TripPhase.pickup;
    final String progressLabel = pickup
        ? AppStrings.pickedProgress(trip.pickedCount, trip.stopCount)
        : AppStrings.deliveredProgress(trip.doneCount, trip.stopCount);
    return AppCard(
      radius: AppRadii.xl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(
                child: Text(
                  AppStrings.todaysTrip,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.display(16),
                ),
              ),
              Text(
                progressLabel,
                style: AppTypography.display(
                  13,
                  weight: FontWeight.w600,
                  color: AppColors.action,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: <Widget>[
              _TintTile(
                value: '${trip.summaryStops.length}',
                label: AppStrings.stops,
              ),
              SizedBox(width: 8.w),
              _TintTile(value: '${trip.summaryItems}', label: AppStrings.items),
              SizedBox(width: 8.w),
              _TintTile(
                value: FormatUtils.compactDuration(trip.summaryEtaMinutes),
                label: AppStrings.estTime,
              ),
            ],
          ),
          SizedBox(height: 14.h),
          AppProgressBar(fraction: trip.progress),
        ],
      ),
    );
  }
}

class _TintTile extends StatelessWidget {
  const _TintTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: AppColors.surfaceTint,
          borderRadius: BorderRadius.circular(AppRadii.md.r),
        ),
        child: AppStatTile(value: value, label: label),
      ),
    );
  }
}
