import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

import 'package:imart_delivery_app/core/utils/logger.dart';

/// What [AppUpdateService.checkAsync] did.
enum AppUpdateOutcome {
  /// Nothing to do (no update, not a Play install, iOS, or the check failed).
  none,

  /// A flexible update finished downloading and waits for a restart.
  readyToInstall,

  /// The blocking Play update screen was shown.
  immediateShown,
}

/// Android Play Store in-app updates.
///
/// Only builds installed from the Play Store get answers; debug builds,
/// sideloaded APKs and emulators without Play report "no update" or throw.
/// Every call fails open: an update check must never crash or block a rider.
abstract final class AppUpdateService {
  /// Releases published with this in-app update priority (0-5, set through the
  /// Play Developer API as `inAppUpdatePriority`) use the blocking flow…
  static const int forcePriority = 4;

  /// …as do updates that have been available for this many days.
  static const int forceAfterDays = 7;

  /// Asks Play for a newer version and starts the right flow.
  ///
  /// [allowBlocking] is false while a delivery is under way: a must-have update
  /// then downloads in the background instead of taking over the screen.
  static Future<AppUpdateOutcome> checkAsync({
    required bool allowBlocking,
  }) async {
    if (kIsWeb || !Platform.isAndroid) {
      return AppUpdateOutcome.none;
    }
    try {
      final AppUpdateInfo info = await InAppUpdate.checkForUpdate();

      // A blocking update interrupted earlier (app sent to background).
      if (info.updateAvailability ==
              UpdateAvailability.developerTriggeredUpdateInProgress &&
          info.immediateUpdateAllowed &&
          allowBlocking) {
        await InAppUpdate.performImmediateUpdate();
        return AppUpdateOutcome.immediateShown;
      }

      // A background download from earlier already finished.
      if (info.installStatus == InstallStatus.downloaded) {
        return AppUpdateOutcome.readyToInstall;
      }

      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return AppUpdateOutcome.none;
      }

      final bool mustHave =
          info.updatePriority >= forcePriority ||
          (info.clientVersionStalenessDays ?? 0) >= forceAfterDays;
      if (mustHave && allowBlocking && info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
        return AppUpdateOutcome.immediateShown;
      }
      if (info.flexibleUpdateAllowed) {
        final AppUpdateResult result = await InAppUpdate.startFlexibleUpdate();
        return result == AppUpdateResult.success
            ? AppUpdateOutcome.readyToInstall
            : AppUpdateOutcome.none;
      }
      if (allowBlocking && info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
        return AppUpdateOutcome.immediateShown;
      }
    } on Object catch (error, stackTrace) {
      AppLogger.log(
        'In-app update check failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
    return AppUpdateOutcome.none;
  }

  /// Installs a downloaded flexible update; the app restarts.
  static Future<void> installAsync() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } on Object catch (error, stackTrace) {
      AppLogger.log(
        'In-app update install failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
