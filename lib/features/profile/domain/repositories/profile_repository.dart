import 'package:imart_delivery_app/features/profile/domain/entities/rider_profile.dart';
import 'package:imart_delivery_app/features/profile/domain/entities/trip_history_entry.dart';

/// Contract for rider profile and trip history.
abstract interface class ProfileRepository {
  /// The signed-in rider.
  Future<RiderProfile> fetchProfileAsync();

  /// Saves edits and returns the stored profile.
  Future<RiderProfile> updateProfileAsync(RiderProfile profile);

  /// Recent trips, newest first.
  Future<List<TripHistoryEntry>> fetchTripHistoryAsync();
}
