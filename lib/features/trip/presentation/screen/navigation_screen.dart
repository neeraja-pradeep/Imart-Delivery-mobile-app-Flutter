import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/app/router/app_routes.dart';
import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/theme.dart';
import 'package:imart_delivery_app/core/utils/format_utils.dart';
import 'package:imart_delivery_app/core/utils/logger.dart';
import 'package:imart_delivery_app/core/utils/map_links.dart';
import 'package:imart_delivery_app/core/widgets/app_bottom_sheet.dart';
import 'package:imart_delivery_app/core/widgets/app_status_bar_style.dart';
import 'package:imart_delivery_app/features/common/feedback/application/providers/app_feedback_provider.dart';
import 'package:imart_delivery_app/features/common/feedback/application/states/app_feedback_state.dart';
import 'package:imart_delivery_app/features/trip/application/providers/trip_providers.dart';
import 'package:imart_delivery_app/features/trip/application/states/trip_state.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/delivery_stop.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/payment_mode.dart';
import 'package:imart_delivery_app/features/trip/presentation/components/confirm_delivery_sheet.dart';
import 'package:imart_delivery_app/features/trip/presentation/components/delivery_panel_card.dart';
import 'package:imart_delivery_app/features/trip/presentation/components/fail_delivery_sheet.dart';
import 'package:imart_delivery_app/features/trip/presentation/components/navigation_header_section.dart';
import 'package:imart_delivery_app/features/trip/presentation/components/trip_map_view.dart';

/// Live delivery to the current stop: embedded map, turn banner and the
/// stop panel with Call / Navigate / Arrived / Delivered / Failed.
class NavigationScreen extends ConsumerWidget {
  /// Creates the screen.
  const NavigationScreen({super.key});

  static const double _mapTop = 96;

  // Share of the map's height under the delivery panel, kept clear when
  // framing the current stop and the rider.
  static const double _panelCover = 0.55;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TripState trip = ref.watch(tripControllerProvider);
    final DeliveryStop? stop = trip.currentStop;
    if (stop == null) {
      return const SizedBox.shrink();
    }
    final double navBottom =
        AppSizes.navBar.h + MediaQuery.paddingOf(context).bottom;
    return AppStatusBarStyle(
      dark: false,
      child: ColoredBox(
        color: AppColors.mapBackground,
        child: Stack(
          children: <Widget>[
            Positioned(
              top: AppSizes.topInset(context, _mapTop),
              left: 0,
              right: 0,
              bottom: navBottom,
              // Only the map rebuilds on each GPS fix, not the whole screen.
              child: Consumer(
                builder: (BuildContext _, WidgetRef mapRef, Widget? _) =>
                    TripMapView(
                      stops: trip.stops,
                      currentIndex: trip.currentIndex,
                      rider: mapRef.watch(riderPositionProvider),
                      obscuredBottom: _panelCover,
                      // The delivery panel covers the bottom of the map.
                      attributionAlignment: Alignment.topRight,
                    ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: NavigationHeaderSection(
                turn: stop.turnInstruction,
                subtitle: AppStrings.stopOf(
                  trip.currentIndex + 1,
                  trip.summaryStops.length,
                  FormatUtils.minutes(stop.etaMinutes),
                ),
                onBack: () => context.go(AppRoutes.trip),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: navBottom,
              // The web map is a DOM iframe; without the interceptor it
              // swallows taps meant for the panel drawn over it.
              child: PointerInterceptor(
                child: DeliveryPanelCard(
                  stop: stop,
                  arrived: trip.arrived,
                  onCall: () => _launchAsync(MapLinks.dial(stop.customerPhone)),
                  onNavigate: () => _launchAsync(
                    MapLinks.directions(stop.latitude, stop.longitude),
                  ),
                  onArrived: ref
                      .read(tripControllerProvider.notifier)
                      .markArrivedAsync,
                  onDelivered: () => _onDeliveredAsync(context, ref, stop),
                  onFailed: () => _onFailedAsync(context, ref),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchAsync(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (error, stackTrace) {
      AppLogger.log('Launch failed', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> _onDeliveredAsync(
    BuildContext context,
    WidgetRef ref,
    DeliveryStop stop,
  ) async {
    final bool? confirmed = await AppBottomSheet.show<bool>(
      context: context,
      builder: (_) => ConfirmDeliverySheet(stop: stop),
    );
    if (confirmed != true) {
      return;
    }
    // Read before awaiting: after the last stop this screen is replaced by
    // Trip Complete, and `ref` can't be used once it's gone.
    final AppFeedbackController feedback = ref.read(
      appFeedbackProvider.notifier,
    );
    final TripController trip = ref.read(tripControllerProvider.notifier);
    await feedback.runWithLoadingAsync(
      AppStrings.updatingDelivery,
      () => trip.markDeliveredAsync(
        cashCollected: stop.paymentMode == PaymentMode.cod,
      ),
    );
    feedback.showToast(AppStrings.toastDelivered(stop.customerName));
  }

  Future<void> _onFailedAsync(BuildContext context, WidgetRef ref) async {
    final String? reasonId = await AppBottomSheet.show<String>(
      context: context,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
      builder: (_) => const FailDeliverySheet(),
    );
    if (reasonId == null) {
      return;
    }
    final AppFeedbackController feedback = ref.read(
      appFeedbackProvider.notifier,
    );
    final TripController trip = ref.read(tripControllerProvider.notifier);
    await feedback.runWithLoadingAsync(
      AppStrings.updatingDelivery,
      () => trip.markFailedAsync(reasonId),
    );
    feedback.showToast(AppStrings.toastFailed, tone: FeedbackTone.warning);
  }
}
