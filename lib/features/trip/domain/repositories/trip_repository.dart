import 'package:imart_delivery_app/features/trip/domain/entities/delivery_stop.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/fail_reason.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/geo_position.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/trip_wrap_up.dart';

/// Contract for everything the rider's trip flow reads or writes.
abstract interface class TripRepository {
  /// Orders currently assigned to the rider, with their live status.
  Future<List<DeliveryStop>> fetchAssignedStopsAsync();

  /// Reasons a rider can pick when a delivery fails.
  Future<List<FailReason>> fetchFailReasonsAsync();

  /// Whether the rider is on leave (offline, not receiving trips).
  Future<bool> fetchIsOnLeaveAsync();

  /// Starts the trip with the picked orders in delivery order.
  Future<void> startTripAsync(List<DeliveryStop> route);

  /// Sends the rider out to [stop], the next one in the route.
  Future<void> markOutForDeliveryAsync(DeliveryStop stop);

  /// Records arrival at [stop].
  Future<void> markArrivedAsync(DeliveryStop stop);

  /// Records a successful hand-over.
  Future<void> markDeliveredAsync(
    DeliveryStop stop, {
    required bool cashCollected,
  });

  /// Records a failed delivery.
  Future<void> markFailedAsync(DeliveryStop stop, String reasonId);

  /// Updates the rider's leave status.
  Future<void> setOnLeaveAsync({required bool onLeave});

  /// Shares the rider's position with every customer on the trip.
  Future<void> pushLocationAsync(GeoPosition position);

  /// Server figures for the Trip Complete screen.
  Future<TripWrapUp> fetchTripWrapUpAsync();
}
