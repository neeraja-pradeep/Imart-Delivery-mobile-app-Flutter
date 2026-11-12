import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/app/router/app_routes.dart';
import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/theme.dart';
import 'package:imart_delivery_app/app/theme/typography.dart';
import 'package:imart_delivery_app/core/utils/format_utils.dart';
import 'package:imart_delivery_app/core/utils/map_links.dart';
import 'package:imart_delivery_app/core/widgets/app_action_bar.dart';
import 'package:imart_delivery_app/core/widgets/app_button.dart';
import 'package:imart_delivery_app/core/widgets/app_icon.dart';
import 'package:imart_delivery_app/core/widgets/app_status_bar_style.dart';
import 'package:imart_delivery_app/core/widgets/app_sub_header.dart';
import 'package:imart_delivery_app/features/common/feedback/application/providers/app_feedback_provider.dart';
import 'package:imart_delivery_app/features/trip/application/providers/trip_providers.dart';
import 'package:imart_delivery_app/features/trip/application/states/trip_state.dart';
import 'package:imart_delivery_app/features/trip/presentation/components/arrange_stop_tile.dart';
import 'package:imart_delivery_app/features/trip/presentation/components/map_embed_view.dart';

/// Second step after Start Trip: order the picked stops, then start
/// navigation.
class ArrangeRouteScreen extends ConsumerWidget {
  /// Creates the screen.
  const ArrangeRouteScreen({super.key});

  static const double _listTop = 104;
  static const double _mapHeight = 180;
  static const double _listBottom = 150;
  static const double _overviewLat = 12.95;
  static const double _overviewLng = 77.64;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TripState trip = ref.watch(tripControllerProvider);
    final TripController controller = ref.read(tripControllerProvider.notifier);
    final double navBottom =
        AppSizes.navBar.h + MediaQuery.paddingOf(context).bottom;
    final String subtitle = AppStrings.arrangeSubtitle(
      trip.stopCount,
      FormatUtils.km(trip.tripDistanceKm),
      FormatUtils.compactDuration(trip.summaryEtaMinutes),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop) {
          controller.backToPickup();
        }
      },
      child: AppStatusBarStyle(
        dark: false,
        child: ColoredBox(
          color: AppColors.surfacePage,
          child: Stack(
            children: <Widget>[
              Positioned(
                top: AppSizes.topInset(context, _listTop),
                left: 0,
                right: 0,
                bottom: 0,
                child: ListView(
                  padding: EdgeInsets.only(bottom: _listBottom.h),
                  children: <Widget>[
                    SizedBox(
                      height: _mapHeight.h,
                      child: MapEmbedView(
                        url: MapLinks.overview(_overviewLat, _overviewLng),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18.w,
                        vertical: 16.h,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          AppButton(
                            label: AppStrings.optimizeByDistance,
                            variant: AppButtonVariant.tinted,
                            height: 46,
                            fontSize: 14,
                            leading: const AppIcon(
                              AppIconGlyph.sort,
                              size: 16,
                              color: AppColors.action,
                            ),
                            onPressed: controller.optimizeRoute,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            AppStrings.arrangeHint,
                            textAlign: TextAlign.center,
                            style: AppTypography.body(
                              12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          for (
                            int i = 0;
                            i < trip.stops.length;
                            i++
                          ) ...<Widget>[
                            ArrangeStopTile(
                              key: ValueKey<String>(trip.stops[i].orderId),
                              stop: trip.stops[i],
                              sequence: i + 1,
                              canMoveUp: i > 0,
                              canMoveDown: i < trip.stops.length - 1,
                              onMoveUp: () => controller.moveStop(i, -1),
                              onMoveDown: () => controller.moveStop(i, 1),
                            ),
                            SizedBox(height: 10.h),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AppSubHeader(
                  title: AppStrings.arrangeRoute,
                  subtitle: subtitle,
                  titleSize: 20,
                  bottomPadding: 16,
                  onBack: controller.backToPickup,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: navBottom,
                child: AppActionBar(
                  child: AppButton(
                    label: AppStrings.startNavigation,
                    leading: const AppIcon(
                      AppIconGlyph.navigation,
                      size: 18,
                      color: AppColors.white,
                    ),
                    onPressed: () => _onStartNavigationAsync(context, ref),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onStartNavigationAsync(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await ref
        .read(appFeedbackProvider.notifier)
        .runWithLoadingAsync(
          AppStrings.startingNavigation,
          ref.read(tripControllerProvider.notifier).startNavigationAsync,
        );
    if (context.mounted) {
      context.go(AppRoutes.map);
    }
  }
}
