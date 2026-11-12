import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/core/error/error_view.dart';
import 'package:imart_delivery_app/core/widgets/app_icon.dart';
import 'package:imart_delivery_app/core/widgets/app_status_bar_style.dart';
import 'package:imart_delivery_app/features/common/feedback/application/providers/app_feedback_provider.dart';
import 'package:imart_delivery_app/features/trip/application/providers/trip_providers.dart';

/// "No Trip Assigned Yet" empty state with "Refresh".
class NoTripSection extends ConsumerWidget {
  /// Creates the section.
  const NoTripSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppStatusBarStyle(
      dark: true,
      child: ErrorView(
        icon: const ErrorViewIcon(
          glyph: AppIconGlyph.bag,
          circleSize: 84,
          iconSize: 38,
          circleColor: AppColors.surfaceTint,
          iconColor: AppColors.action,
          strokeWidth: 1.7,
        ),
        title: AppStrings.noTripTitle,
        message: AppStrings.noTripMessage,
        actionLabel: AppStrings.refresh,
        onAction: () => ref
            .read(appFeedbackProvider.notifier)
            .runWithLoadingAsync(
              AppStrings.checkingTrips,
              ref.read(tripControllerProvider.notifier).loadTripAsync,
            ),
      ),
    );
  }
}
