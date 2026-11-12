import 'package:imart_delivery_app/features/trip/domain/entities/delivery_stop.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/fail_reason.dart';

/// Contract for everything the rider's trip flow reads or writes.
abstract interface class TripRepository {
  /// Orders currently assigned to the rider, with their live status.
  Future<List<DeliveryStop>> fetchAssignedStopsAsync();

  /// Reasons a rider can pick when a delivery fails.
  Future<List<FailReason>> fetchFailReasonsAsync();

  /// Starts the trip with the picked orders in delivery order.
  Future<void> startTripAsync(List<String> orderedStopIds);

  /// Records arrival at a stop.
  Future<void> markArrivedAsync(String stopId);

  /// Records a successful hand-over.
  Future<void> markDeliveredAsync(String stopId, {required bool cashCollected});

  /// Records a failed delivery.
  Future<void> markFailedAsync(String stopId, String reasonId);

  /// Updates the rider's leave status.
  Future<void> setOnLeaveAsync({required bool onLeave});
}
