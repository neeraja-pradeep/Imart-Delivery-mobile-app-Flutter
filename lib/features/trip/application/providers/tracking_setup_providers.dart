import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:imart_delivery_app/app/config/env.dart';
import 'package:imart_delivery_app/features/trip/application/providers/trip_providers.dart';
import 'package:imart_delivery_app/features/trip/application/states/tracking_setup_state.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/location_access.dart';
import 'package:imart_delivery_app/features/trip/infrastructure/data_sources/local/location_local_ds.dart';
import 'package:imart_delivery_app/features/trip/infrastructure/data_sources/local/tracking_permissions_local_ds.dart';

/// Phone settings for background tracking (battery, notifications).
final Provider<TrackingPermissionsLocalDs> trackingPermissionsLocalDsProvider =
    Provider<TrackingPermissionsLocalDs>(
      (Ref ref) => const TrackingPermissionsLocalDs(),
    );

/// Checks and requests what live tracking needs. A trip can't start until
/// [TrackingSetupState.isReady].
final StateNotifierProvider<TrackingSetupController, TrackingSetupState>
trackingSetupControllerProvider =
    StateNotifierProvider<TrackingSetupController, TrackingSetupState>(
      (Ref ref) => TrackingSetupController(
        location: ref.watch(locationLocalDsProvider),
        permissions: ref.watch(trackingPermissionsLocalDsProvider),
        enabled: !Env.current.useStaticData,
      ),
    );

/// Prepares the phone for live tracking: location permission, the
/// notification permission and the battery-optimisation exemption.
class TrackingSetupController extends StateNotifier<TrackingSetupState> {
  /// Creates the controller. When not `enabled` (static data), the phone is
  /// treated as ready and nothing is requested.
  TrackingSetupController({
    required this._location,
    required this._permissions,
    required this._enabled,
  }) : super(const TrackingSetupState());

  final LocationLocalDs _location;
  final TrackingPermissionsLocalDs _permissions;
  final bool _enabled;

  /// Asks for location and notifications (system dialogs, first time only)
  /// and checks the battery setting. Returns [TrackingSetupState.isReady].
  Future<bool> prepareAsync() async {
    if (!_enabled) {
      return true;
    }
    final LocationAccess access = await _location.requestAccessAsync();
    if (access == LocationAccess.granted) {
      await _permissions.requestNotificationsAsync();
    }
    await _update(locationAccess: access);
    return state.isReady;
  }

  /// Re-reads both settings without asking (e.g. back from Settings).
  /// Returns [TrackingSetupState.isReady].
  Future<bool> recheckAsync() async {
    if (!_enabled) {
      return true;
    }
    await _update(locationAccess: await _location.checkAccessAsync());
    return state.isReady;
  }

  /// Fixes location: asks again when the phone allows it, otherwise opens
  /// the phone's location or app settings.
  Future<void> fixLocationAsync() async {
    switch (state.locationAccess) {
      case LocationAccess.serviceOff:
        await _location.openLocationSettingsAsync();
      case LocationAccess.deniedForever:
        await _permissions.openAppSettingsAsync();
      case LocationAccess.denied:
        final LocationAccess access = await _location.requestAccessAsync();
        if (access == LocationAccess.deniedForever) {
          await _permissions.openAppSettingsAsync();
        }
        await _update(locationAccess: access);
      case LocationAccess.granted:
        break;
    }
  }

  /// Shows the phone's own "run in background" dialog.
  Future<void> allowUnrestrictedAsync() async {
    final bool granted = await _permissions.requestBatteryUnrestrictedAsync();
    if (mounted) {
      state = state.copyWith(batteryUnrestricted: granted);
    }
  }

  /// Opens this app's page in the phone's Settings, for brand-specific
  /// switches (Battery → Unrestricted, Autostart). The result is read by
  /// [recheckAsync] when the rider comes back.
  Future<void> openPhoneSettingsAsync() => _permissions.openAppSettingsAsync();

  Future<void> _update({required LocationAccess locationAccess}) async {
    final bool unrestricted = await _permissions.isBatteryUnrestrictedAsync();
    if (mounted) {
      state = state.copyWith(
        locationAccess: locationAccess,
        batteryUnrestricted: unrestricted,
      );
    }
  }
}
