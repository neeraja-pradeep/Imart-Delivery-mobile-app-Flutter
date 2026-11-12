import 'package:imart_delivery_app/core/error/failure.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/delivery_stop.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/fail_reason.dart';
import 'package:imart_delivery_app/features/trip/domain/repositories/trip_repository.dart';
import 'package:imart_delivery_app/features/trip/infrastructure/data_sources/remote/trip_api.dart';

/// [TripRepository] backed by a [TripApi]; maps errors to [Failure].
class TripRepositoryImpl implements TripRepository {
  /// Creates the repository.
  const TripRepositoryImpl(this._api);

  final TripApi _api;

  @override
  Future<List<DeliveryStop>> fetchAssignedStopsAsync() =>
      _guardAsync(_api.fetchAssignedStopsAsync);

  @override
  Future<List<FailReason>> fetchFailReasonsAsync() =>
      _guardAsync(_api.fetchFailReasonsAsync);

  @override
  Future<void> startTripAsync(List<String> orderedStopIds) =>
      _guardAsync(() => _api.startTripAsync(orderedStopIds));

  @override
  Future<void> markArrivedAsync(String stopId) =>
      _guardAsync(() => _api.markArrivedAsync(stopId));

  @override
  Future<void> markDeliveredAsync(
    String stopId, {
    required bool cashCollected,
  }) => _guardAsync(
    () => _api.markDeliveredAsync(stopId, cashCollected: cashCollected),
  );

  @override
  Future<void> markFailedAsync(String stopId, String reasonId) =>
      _guardAsync(() => _api.markFailedAsync(stopId, reasonId));

  @override
  Future<void> setOnLeaveAsync({required bool onLeave}) =>
      _guardAsync(() => _api.setOnLeaveAsync(onLeave: onLeave));

  Future<T> _guardAsync<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Failure {
      rethrow;
    } catch (error) {
      throw Failure('Trip request failed', cause: error);
    }
  }
}
