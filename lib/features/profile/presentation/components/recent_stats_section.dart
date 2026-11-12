import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/typography.dart';
import 'package:imart_delivery_app/core/utils/format_utils.dart';
import 'package:imart_delivery_app/core/widgets/app_card.dart';
import 'package:imart_delivery_app/core/widgets/app_stat_tile.dart';
import 'package:imart_delivery_app/features/profile/application/providers/profile_providers.dart';
import 'package:imart_delivery_app/features/profile/application/states/recent_stats_state.dart';

/// "Last 7 days" — Delivered / Distance / Trips (non-monetary KPIs).
class RecentStatsSection extends ConsumerWidget {
  /// Creates the section.
  const RecentStatsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RecentStatsState? stats = ref
        .watch(currentRecentStatsProvider)
        .valueOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.w),
          child: Text(
            AppStrings.last7Days,
            style: AppTypography.display(13, color: AppColors.textSecondary),
          ),
        ),
        SizedBox(height: 10.h),
        Row(
          children: <Widget>[
            _StatCard(
              value: '${stats?.delivered ?? 0}',
              label: AppStrings.delivered,
            ),
            SizedBox(width: 10.w),
            _StatCard(
              value: FormatUtils.km(stats?.distanceKm ?? 0),
              label: AppStrings.distance,
            ),
            SizedBox(width: 10.w),
            _StatCard(value: '${stats?.trips ?? 0}', label: AppStrings.trips),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
        child: AppStatTile(value: value, label: label, valueSize: 20),
      ),
    );
  }
}
