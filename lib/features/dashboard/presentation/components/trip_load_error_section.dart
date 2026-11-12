import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/core/error/error_view.dart';
import 'package:imart_delivery_app/core/widgets/app_icon.dart';
import 'package:imart_delivery_app/core/widgets/app_status_bar_style.dart';
import 'package:imart_delivery_app/features/common/feedback/application/providers/app_feedback_provider.dart';
import 'package:imart_delivery_app/features/trip/application/providers/trip_providers.dart';

/// Full-screen "Connection Lost" state with Retry (covers the nav).
class TripLoadErrorSection extends ConsumerWidget {
  /// Creates the section.
  const TripLoadErrorSection({super.key});

  static const double _bottomPadding = 80;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppStatusBarStyle(
      dark: true,
      child: ErrorView(
        icon: const ErrorViewIcon(
          glyph: AppIconGlyph.connectionLost,
          circleSize: 84,
          iconSize: 40,
          circleColor: AppColors.coralTint12,
          iconColor: AppColors.coral,
        ),
        title: AppStrings.connectionLost,
        message: AppStrings.connectionLostMessage,
        actionLabel: AppStrings.retry,
        bottomPadding: _bottomPadding,
        onAction: () => ref
            .read(appFeedbackProvider.notifier)
            .runWithLoadingAsync(
              AppStrings.reconnecting,
              ref.read(tripControllerProvider.notifier).loadTripAsync,
            ),
      ),
    );
  }
}
