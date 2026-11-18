import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/typography.dart';
import 'package:imart_delivery_app/core/widgets/app_bottom_sheet.dart';
import 'package:imart_delivery_app/core/widgets/app_button.dart';
import 'package:imart_delivery_app/core/widgets/app_icon.dart';
import 'package:imart_delivery_app/features/trip/application/providers/tracking_setup_providers.dart';
import 'package:imart_delivery_app/features/trip/application/states/tracking_setup_state.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/location_access.dart';

/// Required setup for live tracking: location access, then running without
/// battery restrictions.
///
/// It only offers ways to fix the setting (or Cancel). It re-checks when the
/// rider comes back from the phone's Settings and closes itself with `true`
/// once everything is allowed.
class TrackingSetupSheet extends ConsumerStatefulWidget {
  /// Creates the sheet body.
  const TrackingSetupSheet({super.key});

  /// Before a trip starts: asks for location and notifications, then shows
  /// this sheet until location and the battery exemption are both allowed.
  /// Returns `false` when the rider cancels — the trip must not start.
  static Future<bool> ensureReadyAsync(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final bool ready = await ref
        .read(trackingSetupControllerProvider.notifier)
        .prepareAsync();
    if (ready) {
      return true;
    }
    if (!context.mounted) {
      return false;
    }
    final bool? done = await AppBottomSheet.show<bool>(
      context: context,
      builder: (_) => const TrackingSetupSheet(),
    );
    return done ?? false;
  }

  @override
  ConsumerState<TrackingSetupSheet> createState() => _TrackingSetupSheetState();
}

class _TrackingSetupSheetState extends ConsumerState<TrackingSetupSheet>
    with WidgetsBindingObserver {
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Back from the phone's Settings or a system dialog: re-check.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(trackingSetupControllerProvider.notifier).recheckAsync();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<TrackingSetupState>(trackingSetupControllerProvider, (
      TrackingSetupState? _,
      TrackingSetupState next,
    ) {
      if (next.isReady && mounted && !_closed) {
        _closed = true;
        Navigator.of(context).pop(true);
      }
    });
    final TrackingSetupState setup = ref.watch(trackingSetupControllerProvider);
    final TrackingSetupController controller = ref.read(
      trackingSetupControllerProvider.notifier,
    );
    return setup.locationReady
        ? _SetupStep(
            glyph: AppIconGlyph.navigation,
            title: AppStrings.keepTrackingOn,
            message: AppStrings.keepTrackingOnMessage,
            hint: AppStrings.batterySettingsHint,
            primaryLabel: AppStrings.allowInBackground,
            onPrimary: controller.allowUnrestrictedAsync,
            secondaryLabel: AppStrings.openPhoneSettings,
            onSecondary: controller.openPhoneSettingsAsync,
          )
        : _SetupStep(
            glyph: AppIconGlyph.pin,
            title: AppStrings.allowLocationTitle,
            message: setup.locationAccess == LocationAccess.serviceOff
                ? AppStrings.locationServiceOffMessage
                : AppStrings.allowLocationMessage,
            hint: setup.locationAccess == LocationAccess.deniedForever
                ? AppStrings.locationBlockedHint
                : null,
            primaryLabel: switch (setup.locationAccess) {
              LocationAccess.serviceOff => AppStrings.turnOnLocation,
              LocationAccess.deniedForever => AppStrings.openPhoneSettings,
              LocationAccess.denied ||
              LocationAccess.granted => AppStrings.allowLocation,
            },
            onPrimary: controller.fixLocationAsync,
          );
  }
}

/// One step of the setup sheet: icon, title, explanation, actions, Cancel.
class _SetupStep extends StatelessWidget {
  const _SetupStep({
    required this.glyph,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.hint,
    this.secondaryLabel,
    this.onSecondary,
  });

  final AppIconGlyph glyph;
  final String title;
  final String message;
  final String? hint;
  final String primaryLabel;
  final Future<void> Function() onPrimary;
  final String? secondaryLabel;
  final Future<void> Function()? onSecondary;

  @override
  Widget build(BuildContext context) {
    final String? secondary = secondaryLabel;
    final Future<void> Function()? onSecondaryTap = onSecondary;
    final String? hintText = hint;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Center(
          child: Container(
            width: 60.r,
            height: 60.r,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.surfaceTint,
              shape: BoxShape.circle,
            ),
            child: AppIcon(
              glyph,
              size: 28,
              color: AppColors.action,
              strokeWidth: 2.2,
            ),
          ),
        ),
        SizedBox(height: 14.h),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTypography.display(20),
        ),
        SizedBox(height: 8.h),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTypography.body(
            13.5,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        if (hintText != null) ...<Widget>[
          SizedBox(height: 10.h),
          Text(
            hintText,
            textAlign: TextAlign.center,
            style: AppTypography.body(
              12,
              color: AppColors.textMuted,
              height: 1.45,
            ),
          ),
        ],
        SizedBox(height: 20.h),
        AppButton(label: primaryLabel, height: 50, onPressed: onPrimary),
        if (secondary != null && onSecondaryTap != null) ...<Widget>[
          SizedBox(height: 10.h),
          AppButton(
            label: secondary,
            variant: AppButtonVariant.secondary,
            height: 50,
            onPressed: onSecondaryTap,
          ),
        ],
        SizedBox(height: 6.h),
        AppButton(
          label: AppStrings.cancel,
          variant: AppButtonVariant.ghost,
          height: 44,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}
