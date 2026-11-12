import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/app/router/app_routes.dart';
import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/theme.dart';
import 'package:imart_delivery_app/app/theme/typography.dart';
import 'package:imart_delivery_app/core/widgets/app_button.dart';
import 'package:imart_delivery_app/core/widgets/app_icon.dart';
import 'package:imart_delivery_app/core/widgets/app_pattern_background.dart';
import 'package:imart_delivery_app/core/widgets/app_status_bar_style.dart';
import 'package:imart_delivery_app/features/common/feedback/application/providers/app_feedback_provider.dart';
import 'package:imart_delivery_app/features/profile/application/providers/profile_providers.dart';
import 'package:imart_delivery_app/features/trip/application/providers/trip_providers.dart';
import 'package:imart_delivery_app/features/trip/application/states/trip_state.dart';
import 'package:imart_delivery_app/features/trip/presentation/components/trip_complete_card.dart';

/// Celebration + results once every stop is delivered or failed.
class TripCompleteScreen extends ConsumerWidget {
  /// Creates the screen.
  const TripCompleteScreen({super.key});

  static const double _patternOpacity = 0.12;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TripState trip = ref.watch(tripControllerProvider);
    final String firstName =
        ref.watch(profileControllerProvider).valueOrNull?.firstName ?? '';
    return AppStatusBarStyle(
      dark: false,
      child: ColoredBox(
        color: AppColors.brand,
        child: Stack(
          children: <Widget>[
            const Positioned.fill(
              child: AppPatternBackground(
                opacity: _patternOpacity,
                screenBlend: true,
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.fromLTRB(30.w, 30.h, 30.w, 90.h),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      width: 74.r,
                      height: 74.r,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.amber,
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.celebrate,
                      ),
                      child: const AppIcon(
                        AppIconGlyph.check,
                        size: 36,
                        color: AppColors.white,
                        strokeWidth: 3,
                      ),
                    ),
                    SizedBox(height: 18.h),
                    Text(
                      AppStrings.tripComplete,
                      style: AppTypography.display(26, color: AppColors.white),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      AppStrings.greatWork(firstName),
                      style: AppTypography.body(14, color: AppColors.white80),
                    ),
                    SizedBox(height: 24.h),
                    TripCompleteCard(
                      delivered: trip.deliveredCount,
                      failed: trip.failedCount,
                      distanceKm: trip.tripDistanceKm,
                      codCollected: trip.codCollected,
                    ),
                    SizedBox(height: 18.h),
                    AppButton(
                      label: AppStrings.startNewTrip,
                      onPressed: () => _onStartNewTripAsync(context, ref),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onStartNewTripAsync(BuildContext context, WidgetRef ref) async {
    await ref
        .read(appFeedbackProvider.notifier)
        .runWithLoadingAsync(
          AppStrings.loadingNewTrip,
          ref.read(tripControllerProvider.notifier).loadTripAsync,
        );
    if (context.mounted) {
      context.go(AppRoutes.trip);
    }
  }
}
