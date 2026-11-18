import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:imart_delivery_app/app/config/env.dart';
import 'package:imart_delivery_app/core/network/network_providers.dart';
import 'package:imart_delivery_app/core/utils/logger.dart';
import 'package:imart_delivery_app/features/auth/application/providers/auth_providers.dart';
import 'package:imart_delivery_app/features/profile/application/states/recent_stats_state.dart';
import 'package:imart_delivery_app/features/profile/domain/entities/rider_profile.dart';
import 'package:imart_delivery_app/features/profile/domain/entities/trip_history_entry.dart';
import 'package:imart_delivery_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:imart_delivery_app/features/profile/infrastructure/data_sources/remote/profile_api.dart';
import 'package:imart_delivery_app/features/profile/infrastructure/data_sources/remote/profile_remote_api.dart';
import 'package:imart_delivery_app/features/profile/infrastructure/data_sources/remote/profile_static_api.dart';
import 'package:imart_delivery_app/features/profile/infrastructure/repositories/profile_repository_impl.dart';
import 'package:imart_delivery_app/features/trip/application/providers/trip_providers.dart';
import 'package:imart_delivery_app/features/trip/application/states/trip_state.dart';

/// Profile data source: the backend, or fixtures when no `API_BASE_URL` is
/// set.
final Provider<ProfileApi> profileApiProvider = Provider<ProfileApi>(
  (Ref ref) => Env.current.useStaticData
      ? ProfileStaticApi()
      : ProfileRemoteApi(ref.watch(apiClientProvider)),
);

/// Profile repository.
final Provider<ProfileRepository> profileRepositoryProvider =
    Provider<ProfileRepository>(
      (Ref ref) => ProfileRepositoryImpl(ref.watch(profileApiProvider)),
    );

/// The signed-in rider. Reloads on sign-in and is cleared on sign-out, so
/// one rider never sees another's profile.
final StateNotifierProvider<ProfileController, AsyncValue<RiderProfile>>
profileControllerProvider =
    StateNotifierProvider<ProfileController, AsyncValue<RiderProfile>>((
      Ref ref,
    ) {
      final ProfileController controller = ProfileController(
        ref.watch(profileRepositoryProvider),
      );
      ref.listen<bool>(isAuthenticatedProvider, (bool? _, bool signedIn) {
        if (signedIn) {
          controller.loadAsync();
        } else {
          controller.clear();
        }
      });
      if (ref.read(isAuthenticatedProvider)) {
        controller.loadAsync();
      }
      return controller;
    });

/// Recent trip history; refetched for each signed-in rider and whenever a
/// stop is delivered or failed.
final FutureProvider<List<TripHistoryEntry>> tripHistoryProvider =
    FutureProvider<List<TripHistoryEntry>>((Ref ref) {
      if (!ref.watch(isAuthenticatedProvider)) {
        return const <TripHistoryEntry>[];
      }
      ref.watch(
        tripControllerProvider.select((TripState trip) => trip.doneCount),
      );
      return ref.watch(profileRepositoryProvider).fetchTripHistoryAsync();
    });

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
  /// Creates the controller; [loadAsync] fetches the profile.
  ProfileController(this._repository)
    : super(const AsyncValue<RiderProfile>.loading());

  final ProfileRepository _repository;

  /// (Re)loads the profile.
  Future<void> loadAsync() async {
    final AsyncValue<RiderProfile> next = await AsyncValue.guard(
      _repository.fetchProfileAsync,
    );
    if (mounted) {
      state = next;
    }
  }

  /// Forgets the profile (sign-out).
  void clear() => state = const AsyncValue<RiderProfile>.loading();

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
      if (mounted) {
        state = AsyncValue<RiderProfile>.data(saved);
      }
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
