import 'package:imart_delivery_app/core/error/failure.dart';
import 'package:imart_delivery_app/features/profile/domain/entities/rider_profile.dart';
import 'package:imart_delivery_app/features/profile/domain/entities/trip_history_entry.dart';
import 'package:imart_delivery_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:imart_delivery_app/features/profile/infrastructure/data_sources/remote/profile_api.dart';

/// [ProfileRepository] backed by a [ProfileApi].
class ProfileRepositoryImpl implements ProfileRepository {
  /// Creates the repository.
  const ProfileRepositoryImpl(this._api);

  final ProfileApi _api;

  @override
  Future<RiderProfile> fetchProfileAsync() =>
      _guardAsync(_api.fetchProfileAsync);

  @override
  Future<RiderProfile> updateProfileAsync(RiderProfile profile) =>
      _guardAsync(() => _api.updateProfileAsync(profile));

  @override
  Future<List<TripHistoryEntry>> fetchTripHistoryAsync() =>
      _guardAsync(_api.fetchTripHistoryAsync);

  Future<T> _guardAsync<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Failure {
      rethrow;
    } catch (error) {
      throw Failure('Profile request failed', cause: error);
    }
  }
}
