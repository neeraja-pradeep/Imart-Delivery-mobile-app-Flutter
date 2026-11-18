import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/core/utils/logger.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/geo_position.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/location_access.dart';

export 'package:imart_delivery_app/features/trip/domain/entities/geo_position.dart';

/// Device GPS, used to share the rider's position while delivering.
///
/// On Android the position stream runs inside geolocator's foreground
/// service (type `location`), shown as the "Tracking your delivery"
/// notification, so it keeps going while Google Maps is open or the screen
/// is off. On iOS it uses background location updates.
class LocationLocalDs {
  /// Creates the data source.
  const LocationLocalDs();

  /// Current location access, without asking.
  Future<LocationAccess> checkAccessAsync() => _accessAsync(request: false);

  /// Location access, asking for "while using the app" permission when the
  /// phone still allows the app to ask.
  Future<LocationAccess> requestAccessAsync() => _accessAsync(request: true);

  /// Opens the phone's location (GPS) settings.
  Future<void> openLocationSettingsAsync() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (error) {
      AppLogger.log('Could not open location settings', error: error);
    }
  }

  Future<LocationAccess> _accessAsync({required bool request}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return LocationAccess.serviceOff;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (request && permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return switch (permission) {
        LocationPermission.whileInUse ||
        LocationPermission.always => LocationAccess.granted,
        LocationPermission.deniedForever => LocationAccess.deniedForever,
        LocationPermission.denied ||
        LocationPermission.unableToDetermine => LocationAccess.denied,
      };
    } catch (error) {
      AppLogger.log('Location permission check failed', error: error);
      return LocationAccess.denied;
    }
  }

  /// Positions while the rider moves (at most every
  /// [ApiConfig.locationPingInterval], after at least
  /// [ApiConfig.locationDistanceFilterMeters]). Listening starts the
  /// foreground service; cancelling the subscription stops it.
  Stream<GeoPosition> watchPositions() => Geolocator.getPositionStream(
    locationSettings: _settings(),
  ).map(_toGeoPosition);

  // Unknown readings come back negative (iOS) or 0 (Android) and are
  // dropped. Heading means nothing while standing still, so it is sent only
  // while moving.
  static GeoPosition _toGeoPosition(Position p) => (
    latitude: p.latitude,
    longitude: p.longitude,
    accuracyM: p.accuracy > 0 ? p.accuracy : null,
    speedMps: p.speed >= 0 ? p.speed : null,
    heading: p.speed > 0 && p.heading >= 0 ? p.heading : null,
    recordedAt: p.timestamp,
  );

  static LocationSettings _settings() {
    if (kIsWeb) {
      return const LocationSettings(
        distanceFilter: ApiConfig.locationDistanceFilterMeters,
      );
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => AndroidSettings(
        distanceFilter: ApiConfig.locationDistanceFilterMeters,
        intervalDuration: ApiConfig.locationPingInterval,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: AppStrings.trackingNotificationTitle,
          notificationText: AppStrings.trackingNotificationText,
          notificationChannelName: AppStrings.trackingNotificationChannel,
          enableWakeLock: true,
          setOngoing: true,
        ),
      ),
      TargetPlatform.iOS || TargetPlatform.macOS => AppleSettings(
        activityType: ActivityType.automotiveNavigation,
        distanceFilter: ApiConfig.locationDistanceFilterMeters,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
      ),
      _ => const LocationSettings(
        distanceFilter: ApiConfig.locationDistanceFilterMeters,
      ),
    };
  }
}
