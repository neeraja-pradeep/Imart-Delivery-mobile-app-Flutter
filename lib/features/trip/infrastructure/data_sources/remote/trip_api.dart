import 'package:imart_delivery_app/features/trip/domain/entities/delivery_stop.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/fail_reason.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/geo_position.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/trip_wrap_up.dart';

/// Remote data source for trips.
///
/// `TripRemoteApi` talks to the backend; `TripStaticApi` serves the design
/// fixtures when no backend is configured.
abstract interface class TripApi {
  /// `GET /api/delivery/v1/deliveries/` — the open trip's stops, in the
  /// rider's saved order.
  Future<List<DeliveryStop>> fetchAssignedStopsAsync();

  /// `GET /api/delivery/v1/deliveries/fail-reasons/`.
  Future<List<FailReason>> fetchFailReasonsAsync();

  /// `GET /api/delivery/v1/delivery-profiles/me/` — `true` when offline.
  Future<bool> fetchIsOnLeaveAsync();

  /// Saves [route] as the stop order (`POST /deliveries/arrange/`), marks
  /// every stop in it picked up (`at_pickup` → `picked_up`) and the first
  /// one out for delivery.
  Future<void> startTripAsync(List<DeliveryStop> route);

  /// `PATCH` [stop] to `out_for_delivery` (the next stop in the route).
  Future<void> markOutForDeliveryAsync(DeliveryStop stop);

  /// Records arrival at [stop] (no backend call: the API has no such step).
  Future<void> markArrivedAsync(DeliveryStop stop);

  /// `PATCH` [stop] to `delivered`, with the cash collected for COD.
  Future<void> markDeliveredAsync(
    DeliveryStop stop, {
    required bool cashCollected,
  });

  /// `PATCH` [stop] to `failed` with the reason [reasonId].
  Future<void> markFailedAsync(DeliveryStop stop, String reasonId);

  /// `PATCH /delivery-profiles/me/` availability `offline` / `online`.
  Future<void> setOnLeaveAsync({required bool onLeave});

  /// `POST /delivery-profiles/me/location/`: one point for every active
  /// delivery of the rider.
  Future<void> pushLocationAsync(GeoPosition position);

  /// Trip Complete figures: `GET /delivery-trips/{id}/` and
  /// `GET /deliveries/cash-summary/`.
  Future<TripWrapUp> fetchTripWrapUpAsync();
}
