import 'package:imart_delivery_app/features/profile/domain/entities/rider_profile.dart';
import 'package:imart_delivery_app/features/profile/domain/entities/trip_history_entry.dart';

/// Remote data source for the profile. The API layer provides a
/// Dio-backed implementation and swaps it in `profileApiProvider`.
abstract interface class ProfileApi {
  /// `GET /rider/profile`.
  Future<RiderProfile> fetchProfileAsync();

  /// `PUT /rider/profile`.
  Future<RiderProfile> updateProfileAsync(RiderProfile profile);

  /// `GET /rider/trips?days=7`.
  Future<List<TripHistoryEntry>> fetchTripHistoryAsync();
}
