import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/app/router/app_routes.dart';
import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/theme.dart';
import 'package:imart_delivery_app/core/widgets/app_action_bar.dart';
import 'package:imart_delivery_app/core/widgets/app_button.dart';
import 'package:imart_delivery_app/core/widgets/app_icon.dart';
import 'package:imart_delivery_app/core/widgets/app_status_bar_style.dart';
import 'package:imart_delivery_app/features/common/feedback/application/providers/app_feedback_provider.dart';
import 'package:imart_delivery_app/features/common/feedback/application/states/app_feedback_state.dart';
import 'package:imart_delivery_app/features/trip/application/providers/trip_providers.dart';
import 'package:imart_delivery_app/features/trip/application/states/trip_state.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/delivery_stop.dart';
import 'package:imart_delivery_app/features/trip/presentation/components/delivery_route_header_section.dart';
import 'package:imart_delivery_app/features/trip/presentation/components/pickup_banner_card.dart';
import 'package:imart_delivery_app/features/trip/presentation/components/stop_card.dart';
import 'package:imart_delivery_app/features/trip/presentation/components/trip_header_section.dart';
import 'package:imart_delivery_app/features/trip/presentation/components/trip_summary_card.dart';

/// Trip home: summary, pickup selection (or live route) and the phase's
/// single primary action.
class TripListScreen extends ConsumerWidget {
  /// Creates the screen.
  const TripListScreen({super.key});

  static const double _listTop = 148;
  static const double _listBottom = 150;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TripState trip = ref.watch(tripControllerProvider);
    final String? expandedId = ref.watch(expandedStopIdProvider);
    final bool pickup = trip.phase == TripPhase.pickup;
    final double navBottom =
        AppSizes.navBar.h + MediaQuery.paddingOf(context).bottom;

    return AppStatusBarStyle(
      dark: false,
      child: ColoredBox(
        color: AppColors.surfacePage,
        child: Stack(
          children: <Widget>[
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: TripHeaderSection(),
            ),
            Positioned(
              top: AppSizes.topInset(context, _listTop),
              left: 0,
              right: 0,
              bottom: 0,
              child: ListView(
                padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, _listBottom.h),
                children: <Widget>[
                  TripSummaryCard(trip: trip),
                  SizedBox(height: 16.h),
                  if (pickup) ...<Widget>[
                    PickupBannerCard(
                      picked: trip.pickedCount,
                      total: trip.stopCount,
                    ),
                    SizedBox(height: 18.h),
                  ],
                  DeliveryRouteHeaderSection(pickup: pickup),
                  SizedBox(height: 12.h),
                  for (int i = 0; i < trip.stops.length; i++) ...<Widget>[
                    _buildCard(ref, trip, trip.stops[i], i, expandedId),
                    SizedBox(height: 12.h),
                  ],
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: navBottom,
              child: AppActionBar(
                child: pickup
                    ? AppButton(
                        label: trip.canStartTrip
                            ? AppStrings.startTrip(trip.pickedCount)
                            : AppStrings.pickAtLeastOne,
                        enabled: trip.canStartTrip,
                        height: 52,
                        onPressed: () => _onStartTripAsync(context, ref),
                      )
                    : AppButton(
                        label: AppStrings.openNavigation,
                        leading: const AppIcon(
                          AppIconGlyph.navigation,
                          size: 18,
                          color: AppColors.white,
                        ),
                        onPressed: () => context.go(AppRoutes.map),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    WidgetRef ref,
    TripState trip,
    DeliveryStop stop,
    int index,
    String? expandedId,
  ) {
    final TripController controller = ref.read(tripControllerProvider.notifier);
    final AppFeedbackController feedback = ref.read(
      appFeedbackProvider.notifier,
    );
    return StopCard(
      key: ValueKey<String>(stop.orderId),
      stop: stop,
      sequence: index + 1,
      pickupPhase: trip.phase == TripPhase.pickup,
      isCurrent: trip.phase == TripPhase.enroute && index == trip.currentIndex,
      expanded: expandedId == stop.orderId,
      onToggleExpand: () => ref
          .read(expandedStopIdProvider.notifier)
          .update((String? id) => id == stop.orderId ? null : stop.orderId),
      onPick: () {
        controller.setPicked(stop.orderId, picked: true);
        feedback.showToast(AppStrings.toastAdded);
      },
      onRemove: () {
        controller.setPicked(stop.orderId, picked: false);
        feedback.showToast(AppStrings.toastRemoved, tone: FeedbackTone.muted);
      },
    );
  }

  Future<void> _onStartTripAsync(BuildContext context, WidgetRef ref) async {
    final TripController controller = ref.read(tripControllerProvider.notifier);
    if (controller.beginArrange()) {
      return;
    }
    await ref
        .read(appFeedbackProvider.notifier)
        .runWithLoadingAsync(
          AppStrings.startingNavigation,
          controller.startNavigationAsync,
        );
    if (context.mounted) {
      context.go(AppRoutes.map);
    }
  }
}
