import 'package:imart_delivery_app/core/error/failure.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/delivery_stop.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/fail_reason.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/geo_position.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/trip_wrap_up.dart';
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
  Future<bool> fetchIsOnLeaveAsync() => _guardAsync(_api.fetchIsOnLeaveAsync);

  @override
  Future<void> startTripAsync(List<DeliveryStop> route) =>
      _guardAsync(() => _api.startTripAsync(route));

  @override
  Future<void> markOutForDeliveryAsync(DeliveryStop stop) =>
      _guardAsync(() => _api.markOutForDeliveryAsync(stop));

  @override
  Future<void> markArrivedAsync(DeliveryStop stop) =>
      _guardAsync(() => _api.markArrivedAsync(stop));

  @override
  Future<void> markDeliveredAsync(
    DeliveryStop stop, {
    required bool cashCollected,
  }) => _guardAsync(
    () => _api.markDeliveredAsync(stop, cashCollected: cashCollected),
  );

  @override
  Future<void> markFailedAsync(DeliveryStop stop, String reasonId) =>
      _guardAsync(() => _api.markFailedAsync(stop, reasonId));

  @override
  Future<void> setOnLeaveAsync({required bool onLeave}) =>
      _guardAsync(() => _api.setOnLeaveAsync(onLeave: onLeave));

  @override
  Future<void> pushLocationAsync(GeoPosition position) =>
      _guardAsync(() => _api.pushLocationAsync(position));

  @override
  Future<TripWrapUp> fetchTripWrapUpAsync() =>
      _guardAsync(_api.fetchTripWrapUpAsync);

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
