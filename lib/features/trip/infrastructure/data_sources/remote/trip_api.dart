import 'package:imart_delivery_app/features/trip/domain/entities/delivery_stop.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/fail_reason.dart';

/// Remote data source for trips.
///
/// `TripStaticApi` implements this with fixtures today. The API layer
/// adds a Dio-backed implementation of the same interface and swaps it in
/// `tripApiProvider` — nothing above this layer changes.
abstract interface class TripApi {
  /// `GET /rider/trip/stops`.
  Future<List<DeliveryStop>> fetchAssignedStopsAsync();

  /// `GET /rider/trip/fail-reasons`.
  Future<List<FailReason>> fetchFailReasonsAsync();

  /// `POST /rider/trip/start`.
  Future<void> startTripAsync(List<String> orderedStopIds);

  /// `POST /rider/trip/stops/{id}/arrived`.
  Future<void> markArrivedAsync(String stopId);

  /// `POST /rider/trip/stops/{id}/delivered`.
  Future<void> markDeliveredAsync(String stopId, {required bool cashCollected});

  /// `POST /rider/trip/stops/{id}/failed`.
  Future<void> markFailedAsync(String stopId, String reasonId);

  /// `PUT /rider/availability`.
  Future<void> setOnLeaveAsync({required bool onLeave});
}
