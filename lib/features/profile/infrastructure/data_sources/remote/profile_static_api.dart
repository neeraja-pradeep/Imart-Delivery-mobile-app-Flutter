import 'package:imart_delivery_app/features/profile/domain/entities/rider_profile.dart';
import 'package:imart_delivery_app/features/profile/domain/entities/trip_history_entry.dart';
import 'package:imart_delivery_app/features/profile/infrastructure/data_sources/remote/profile_api.dart';

/// Fixture [ProfileApi] carrying the design's sample rider and history.
class ProfileStaticApi implements ProfileApi {
  /// Creates the static API.
  ProfileStaticApi();

  RiderProfile _profile = const RiderProfile(
    name: 'Aman Sharma',
    phone: '+91 99000 11223',
    email: 'aman.sharma@imart.in',
    vehicle: 'Bike · KA 01 AB 1234',
    hubName: 'Koramangala Fulfilment Hub',
  );

  @override
  Future<RiderProfile> fetchProfileAsync() async => _profile;

  @override
  Future<RiderProfile> updateProfileAsync(RiderProfile profile) async {
    _profile = profile;
    return _profile;
  }

  @override
  Future<List<TripHistoryEntry>> fetchTripHistoryAsync() async =>
      <TripHistoryEntry>[
        TripHistoryEntry(
          date: DateTime(2024, 6, 22),
          stops: 6,
          failed: 0,
          distanceKm: 18,
          earned: 210,
        ),
        TripHistoryEntry(
          date: DateTime(2024, 6, 21),
          stops: 5,
          failed: 1,
          distanceKm: 14,
          earned: 175,
        ),
        TripHistoryEntry(
          date: DateTime(2024, 6, 20),
          stops: 7,
          failed: 0,
          distanceKm: 23,
          earned: 245,
        ),
      ];
}
