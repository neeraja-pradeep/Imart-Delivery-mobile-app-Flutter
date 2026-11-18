import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:imart_delivery_app/app/theme/theme.dart';
import 'package:imart_delivery_app/core/widgets/app_loading_overlay.dart';
import 'package:imart_delivery_app/core/widgets/app_offline_banner.dart';
import 'package:imart_delivery_app/core/widgets/app_toast.dart';
import 'package:imart_delivery_app/features/common/feedback/application/providers/app_feedback_provider.dart';
import 'package:imart_delivery_app/features/common/feedback/application/states/app_feedback_state.dart';

/// Paints app-wide feedback above every route: offline banner, toast and
/// blocking loader (in that z-order, matching the design).
class AppFeedbackHost extends ConsumerWidget {
  /// Wraps the router output.
  const AppFeedbackHost({super.key, required this.child});

  static const double _toastBottom = 88;

  /// Router content.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppFeedbackState feedback = ref.watch(appFeedbackProvider);
    final bool offline = ref.watch(isOfflineProvider).valueOrNull ?? false;
    final double statusTop = MediaQuery.paddingOf(context).top;
    // Keep the toast above the keyboard (e.g. a login error while typing).
    final double bottomInset = math.max(
      MediaQuery.paddingOf(context).bottom,
      MediaQuery.viewInsetsOf(context).bottom,
    );
    final FeedbackToast? toast = feedback.toast;
    return Stack(
      children: <Widget>[
        Positioned.fill(child: child),
        if (offline)
          Positioned(
            top: statusTop > 0 ? statusTop : AppSizes.statusBar.h,
            left: 0,
            right: 0,
            child: const AppOfflineBanner(),
          ),
        if (toast != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: _toastBottom.h + bottomInset,
            child: IgnorePointer(
              child: Center(
                child: AppToast(
                  message: toast.message,
                  tone: switch (toast.tone) {
                    FeedbackTone.success => AppToastTone.success,
                    FeedbackTone.warning => AppToastTone.warning,
                    FeedbackTone.muted => AppToastTone.muted,
                  },
                ),
              ),
            ),
          ),
        if (feedback.isLoading)
          Positioned.fill(
            child: AppLoadingOverlay(message: feedback.loadingMessage ?? ''),
          ),
      ],
    );
  }
}
