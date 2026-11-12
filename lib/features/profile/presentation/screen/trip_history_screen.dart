import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/app/router/app_routes.dart';
import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/core/widgets/app_status_bar_style.dart';
import 'package:imart_delivery_app/core/widgets/app_sub_header.dart';
import 'package:imart_delivery_app/features/profile/application/providers/profile_providers.dart';
import 'package:imart_delivery_app/features/profile/domain/entities/trip_history_entry.dart';
import 'package:imart_delivery_app/features/profile/presentation/components/trip_history_tile.dart';

/// Recent trips list.
class TripHistoryScreen extends ConsumerWidget {
  /// Creates the screen.
  const TripHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<TripHistoryEntry> history =
        ref.watch(tripHistoryProvider).valueOrNull ??
        const <TripHistoryEntry>[];
    void back() => context.go(AppRoutes.profile);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop) {
          back();
        }
      },
      child: AppStatusBarStyle(
        dark: false,
        child: ColoredBox(
          color: AppColors.surfacePage,
          child: Column(
            children: <Widget>[
              AppSubHeader(title: AppStrings.tripHistory, onBack: back),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.all(18.r),
                  itemCount: history.length,
                  separatorBuilder: (_, _) => SizedBox(height: 12.h),
                  itemBuilder: (_, int i) => TripHistoryTile(entry: history[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
