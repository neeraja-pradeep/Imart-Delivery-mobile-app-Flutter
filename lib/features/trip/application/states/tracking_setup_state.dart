import 'package:imart_delivery_app/features/trip/domain/entities/location_access.dart';

/// What the phone allows for live tracking.
///
/// Both are required: without location nothing can be sent, and without the
/// battery exemption some phones stop the app mid-trip, so the customer's
/// tracking map freezes.
class TrackingSetupState {
  /// Creates a state.
  const TrackingSetupState({
    this.locationAccess = LocationAccess.granted,
    this.batteryUnrestricted = true,
  });

  /// Whether the app can read the phone's location.
  final LocationAccess locationAccess;

  /// The app is exempt from battery optimisation ("Unrestricted").
  final bool batteryUnrestricted;

  /// Location is allowed.
  bool get locationReady => locationAccess == LocationAccess.granted;

  /// Everything live tracking needs is in place.
  bool get isReady => locationReady && batteryUnrestricted;

  /// Copy with changes.
  TrackingSetupState copyWith({
    LocationAccess? locationAccess,
    bool? batteryUnrestricted,
  }) {
    return TrackingSetupState(
      locationAccess: locationAccess ?? this.locationAccess,
      batteryUnrestricted: batteryUnrestricted ?? this.batteryUnrestricted,
    );
  }
}
