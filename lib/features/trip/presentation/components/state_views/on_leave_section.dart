import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/core/error/error_view.dart';
import 'package:imart_delivery_app/core/widgets/app_icon.dart';
import 'package:imart_delivery_app/core/widgets/app_status_bar_style.dart';
import 'package:imart_delivery_app/features/common/feedback/application/providers/app_feedback_provider.dart';
import 'package:imart_delivery_app/features/trip/application/providers/trip_providers.dart';

/// "You're On Leave" state with "End Leave".
class OnLeaveSection extends ConsumerWidget {
  /// Creates the section.
  const OnLeaveSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppStatusBarStyle(
      dark: true,
      child: ErrorView(
        icon: const ErrorViewIcon(
          glyph: AppIconGlyph.clock,
          circleSize: 80,
          iconSize: 36,
          circleColor: AppColors.amberTint,
          iconColor: AppColors.amber,
        ),
        title: AppStrings.onLeaveTitle,
        message: AppStrings.onLeaveMessage,
        actionLabel: AppStrings.endLeave,
        onAction: () => ref
            .read(appFeedbackProvider.notifier)
            .runWithLoadingAsync(
              AppStrings.loadingNewTrip,
              ref.read(tripControllerProvider.notifier).endLeaveAsync,
            ),
      ),
    );
  }
}
