import 'package:imart_delivery_app/features/profile/domain/entities/rider_profile.dart';
import 'package:imart_delivery_app/features/profile/domain/entities/trip_history_entry.dart';

/// Remote data source for the profile.
///
/// `ProfileRemoteApi` talks to the backend; `ProfileStaticApi` serves the
/// design fixtures when no backend is configured.
abstract interface class ProfileApi {
  /// `GET /api/auth/v1/profile/` + `GET /api/delivery/v1/delivery-profiles/me/`.
  Future<RiderProfile> fetchProfileAsync();

  /// `PATCH` both profiles; returns the stored profile.
  Future<RiderProfile> updateProfileAsync(RiderProfile profile);

  /// `GET /api/delivery/v1/deliveries/history/?days=7`, one entry per day.
  Future<List<TripHistoryEntry>> fetchTripHistoryAsync();
}
