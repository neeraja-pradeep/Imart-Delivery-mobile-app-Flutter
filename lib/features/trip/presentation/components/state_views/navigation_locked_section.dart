import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/app/router/app_routes.dart';
import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/core/error/error_view.dart';
import 'package:imart_delivery_app/core/widgets/app_icon.dart';
import 'package:imart_delivery_app/core/widgets/app_status_bar_style.dart';

/// Map tab before the trip starts: "Navigation Locked".
class NavigationLockedSection extends StatelessWidget {
  /// Creates the section.
  const NavigationLockedSection({super.key});

  @override
  Widget build(BuildContext context) {
    return AppStatusBarStyle(
      dark: true,
      child: ErrorView(
        icon: const ErrorViewIcon(
          glyph: AppIconGlyph.navigation,
          circleSize: 76,
          iconSize: 34,
          circleColor: AppColors.surfaceTint,
          iconColor: AppColors.action,
        ),
        title: AppStrings.navigationLocked,
        titleSize: 18,
        message: AppStrings.navigationLockedMessage,
        actionLabel: AppStrings.goToPickup,
        onAction: () => context.go(AppRoutes.trip),
      ),
    );
  }
}
