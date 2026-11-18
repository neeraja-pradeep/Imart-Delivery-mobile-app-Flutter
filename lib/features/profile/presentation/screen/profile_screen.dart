import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/app/router/app_routes.dart';
import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/core/widgets/app_icon.dart';
import 'package:imart_delivery_app/core/widgets/app_status_bar_style.dart';
import 'package:imart_delivery_app/features/auth/application/providers/auth_providers.dart';
import 'package:imart_delivery_app/features/common/feedback/application/providers/app_feedback_provider.dart';
import 'package:imart_delivery_app/features/profile/application/providers/profile_providers.dart';
import 'package:imart_delivery_app/features/profile/domain/entities/rider_profile.dart';
import 'package:imart_delivery_app/features/profile/presentation/components/availability_card.dart';
import 'package:imart_delivery_app/features/profile/presentation/components/profile_header_section.dart';
import 'package:imart_delivery_app/features/profile/presentation/components/profile_menu_tile.dart';
import 'package:imart_delivery_app/features/profile/presentation/components/recent_stats_section.dart';
import 'package:imart_delivery_app/features/trip/application/providers/trip_providers.dart';
import 'package:imart_delivery_app/features/trip/application/states/trip_state.dart';

/// Profile tab: rider card, availability / leave, KPIs, menu.
class ProfileScreen extends ConsumerWidget {
  /// Creates the tab.
  const ProfileScreen({super.key});

  static const double _bottomPadding = 110;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RiderProfile? profile = ref
        .watch(profileControllerProvider)
        .valueOrNull;
    final TripState trip = ref.watch(tripControllerProvider);
    final TripController tripController = ref.read(
      tripControllerProvider.notifier,
    );
    return AppStatusBarStyle(
      dark: false,
      child: ColoredBox(
        color: AppColors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            if (profile != null) ProfileHeaderSection(profile: profile),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, _bottomPadding.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AvailabilityCard(
                    onLeave: trip.onLeave,
                    canMarkLeave: trip.canMarkLeave,
                    onMarkLeave: () => ref
                        .read(appFeedbackProvider.notifier)
                        .runWithLoadingAsync(
                          AppStrings.updatingAvailability,
                          tripController.markLeaveAsync,
                        ),
                    onEndLeave: () => ref
                        .read(appFeedbackProvider.notifier)
                        .runWithLoadingAsync(
                          AppStrings.loadingNewTrip,
                          tripController.endLeaveAsync,
                        ),
                  ),
                  SizedBox(height: 18.h),
                  const RecentStatsSection(),
                  SizedBox(height: 18.h),
                  ProfileMenuTile(
                    glyph: AppIconGlyph.user,
                    label: AppStrings.editProfile,
                    onTap: () => context.go(AppRoutes.profileEdit),
                  ),
                  SizedBox(height: 14.h),
                  ProfileMenuTile(
                    glyph: AppIconGlyph.bag,
                    label: AppStrings.tripHistory,
                    onTap: () => context.go(AppRoutes.profileHistory),
                  ),
                  SizedBox(height: 14.h),
                  ProfileMenuTile(
                    glyph: AppIconGlyph.signOut,
                    label: AppStrings.logOut,
                    onTap: () => _onLogoutAsync(ref),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onLogoutAsync(WidgetRef ref) async {
    await ref.read(isAuthenticatedProvider.notifier).logoutAsync();
    ref
      ..invalidate(tripControllerProvider)
      ..invalidate(profileControllerProvider)
      ..invalidate(tripHistoryProvider);
  }
}
