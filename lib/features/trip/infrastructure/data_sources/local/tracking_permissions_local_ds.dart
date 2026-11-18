import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:imart_delivery_app/core/utils/logger.dart';

/// Phone settings that background tracking depends on (Android).
///
/// Some phones (Xiaomi, Oppo, Vivo, Realme, some Samsung) stop background
/// apps to save battery even while a foreground service runs. Exempting the
/// app from battery optimisation ("Unrestricted" / "No restrictions") keeps
/// tracking alive on those phones.
class TrackingPermissionsLocalDs {
  /// Creates the data source.
  const TrackingPermissionsLocalDs();

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// `true` when the app is already exempt (or the platform has no such
  /// restriction).
  Future<bool> isBatteryUnrestrictedAsync() async {
    if (!_isAndroid) {
      return true;
    }
    try {
      return await Permission.ignoreBatteryOptimizations.isGranted;
    } catch (error) {
      AppLogger.log('Battery optimisation check failed', error: error);
      return true;
    }
  }

  /// Shows the phone's "Let app always run in background?" dialog; `true`
  /// when the rider allowed it.
  Future<bool> requestBatteryUnrestrictedAsync() async {
    if (!_isAndroid) {
      return true;
    }
    try {
      return await Permission.ignoreBatteryOptimizations.request().isGranted;
    } catch (error) {
      AppLogger.log('Battery optimisation request failed', error: error);
      return false;
    }
  }

  /// Asks to show notifications (Android 13+), so the tracking
  /// notification is visible. A refusal does not stop tracking.
  Future<void> requestNotificationsAsync() async {
    if (!_isAndroid) {
      return;
    }
    try {
      await Permission.notification.request();
    } catch (error) {
      AppLogger.log('Notification permission request failed', error: error);
    }
  }

  /// Opens this app's page in the phone's Settings (Battery, Autostart and
  /// other brand-specific switches live there).
  Future<void> openAppSettingsAsync() async {
    try {
      await openAppSettings();
    } catch (error) {
      AppLogger.log('Could not open app settings', error: error);
    }
  }
}
