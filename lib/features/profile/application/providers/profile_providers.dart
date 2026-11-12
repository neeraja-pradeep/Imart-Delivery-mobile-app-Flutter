import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:imart_delivery_app/core/utils/logger.dart';
import 'package:imart_delivery_app/features/profile/application/states/recent_stats_state.dart';
import 'package:imart_delivery_app/features/profile/domain/entities/rider_profile.dart';
import 'package:imart_delivery_app/features/profile/domain/entities/trip_history_entry.dart';
import 'package:imart_delivery_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:imart_delivery_app/features/profile/infrastructure/data_sources/remote/profile_api.dart';
import 'package:imart_delivery_app/features/profile/infrastructure/data_sources/remote/profile_static_api.dart';
import 'package:imart_delivery_app/features/profile/infrastructure/repositories/profile_repository_impl.dart';

/// Profile data source. **Swap point for API integration.**
final Provider<ProfileApi> profileApiProvider = Provider<ProfileApi>(
  (Ref ref) => ProfileStaticApi(),
);

/// Profile repository.
final Provider<ProfileRepository> profileRepositoryProvider =
    Provider<ProfileRepository>(
      (Ref ref) => ProfileRepositoryImpl(ref.watch(profileApiProvider)),
    );

/// The signed-in rider.
final StateNotifierProvider<ProfileController, AsyncValue<RiderProfile>>
profileControllerProvider =
    StateNotifierProvider<ProfileController, AsyncValue<RiderProfile>>(
      (Ref ref) => ProfileController(ref.watch(profileRepositoryProvider)),
    );

/// Recent trip history.
final FutureProvider<List<TripHistoryEntry>> tripHistoryProvider =
    FutureProvider<List<TripHistoryEntry>>(
      (Ref ref) => ref.watch(profileRepositoryProvider).fetchTripHistoryAsync(),
    );

/// "Last 7 days" KPIs derived from [tripHistoryProvider].
final Provider<AsyncValue<RecentStatsState>> currentRecentStatsProvider =
    Provider<AsyncValue<RecentStatsState>>((Ref ref) {
      return ref
          .watch(tripHistoryProvider)
          .whenData(
            (List<TripHistoryEntry> history) => RecentStatsState(
              delivered: history.fold(
                0,
                (int a, TripHistoryEntry e) => a + e.delivered,
              ),
              distanceKm: history.fold(
                0,
                (double a, TripHistoryEntry e) => a + e.distanceKm,
              ),
              trips: history.length,
            ),
          );
    });

/// Loads and edits the rider profile.
class ProfileController extends StateNotifier<AsyncValue<RiderProfile>> {
  /// Creates the controller and loads the profile.
  ProfileController(this._repository)
    : super(const AsyncValue<RiderProfile>.loading()) {
    loadAsync();
  }

  final ProfileRepository _repository;

  /// (Re)loads the profile.
  Future<void> loadAsync() async {
    state = await AsyncValue.guard(_repository.fetchProfileAsync);
  }

  /// Saves edited fields. Returns `true` on success.
  Future<bool> saveAsync({
    required String name,
    required String phone,
    required String email,
    required String vehicle,
  }) async {
    final RiderProfile? current = state.valueOrNull;
    if (current == null) {
      return false;
    }
    try {
      final RiderProfile saved = await _repository.updateProfileAsync(
        current.copyWith(
          name: name,
          phone: phone,
          email: email,
          vehicle: vehicle,
        ),
      );
      state = AsyncValue<RiderProfile>.data(saved);
      return true;
    } catch (error, stackTrace) {
      AppLogger.log(
        'Profile save failed',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
