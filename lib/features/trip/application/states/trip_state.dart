import 'dart:math' as math;

import 'package:imart_delivery_app/features/trip/domain/entities/delivery_stop.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/order_status.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/payment_mode.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/trip_wrap_up.dart';

/// Where the trip-load request stands.
enum TripLoadStatus {
  /// Not requested yet.
  idle,

  /// Request in flight.
  loading,

  /// Stops available (possibly empty).
  loaded,

  /// Request failed.
  error,
}

/// Rider workflow phase.
enum TripPhase {
  /// Choosing which orders to carry.
  pickup,

  /// Ordering the picked stops.
  arrange,

  /// Delivering stop by stop.
  enroute,

  /// Every stop delivered or failed.
  complete,
}

/// Immutable trip-flow state.
class TripState {
  /// Creates a state.
  const TripState({
    this.loadStatus = TripLoadStatus.idle,
    this.phase = TripPhase.pickup,
    this.stops = const <DeliveryStop>[],
    this.assignedStops,
    this.currentIndex = 0,
    this.arrived = false,
    this.onLeave = false,
    this.wrapUp = TripWrapUp.none,
  });

  /// Load status.
  final TripLoadStatus loadStatus;

  /// Workflow phase.
  final TripPhase phase;

  /// Stops in route order. In pickup this is every assigned order; from
  /// arrange onwards it holds only the picked orders.
  final List<DeliveryStop> stops;

  /// Full assignment kept while arranging, so "Back" restores it.
  final List<DeliveryStop>? assignedStops;

  /// Index of the stop being delivered.
  final int currentIndex;

  /// Rider confirmed arrival at the current stop.
  final bool arrived;

  /// Rider is on leave.
  final bool onLeave;

  /// Server figures for Trip Complete (fetched once the last stop ends).
  final TripWrapUp wrapUp;

  /// Copy with changes. Pass `clearAssigned` to drop [assignedStops].
  TripState copyWith({
    TripLoadStatus? loadStatus,
    TripPhase? phase,
    List<DeliveryStop>? stops,
    List<DeliveryStop>? assignedStops,
    bool clearAssigned = false,
    int? currentIndex,
    bool? arrived,
    bool? onLeave,
    TripWrapUp? wrapUp,
  }) {
    return TripState(
      loadStatus: loadStatus ?? this.loadStatus,
      phase: phase ?? this.phase,
      stops: stops ?? this.stops,
      assignedStops: clearAssigned
          ? null
          : (assignedStops ?? this.assignedStops),
      currentIndex: currentIndex ?? this.currentIndex,
      arrived: arrived ?? this.arrived,
      onLeave: onLeave ?? this.onLeave,
      wrapUp: wrapUp ?? this.wrapUp,
    );
  }

  // ---- Derived values (read-only) ----

  /// Number of stops.
  int get stopCount => stops.length;

  /// Orders no longer in `assigned`.
  int get pickedCount =>
      stops.where((DeliveryStop s) => s.status != OrderStatus.assigned).length;

  /// Delivered orders.
  int get deliveredCount =>
      stops.where((DeliveryStop s) => s.status == OrderStatus.delivered).length;

  /// Failed orders.
  int get failedCount =>
      stops.where((DeliveryStop s) => s.status == OrderStatus.failed).length;

  /// Delivered + failed.
  int get doneCount => deliveredCount + failedCount;

  /// Whether Start Trip is enabled.
  bool get canStartTrip => pickedCount >= 1;

  /// Leave can only be marked once nothing is in progress.
  bool get canMarkLeave =>
      phase == TripPhase.complete ||
      (loadStatus == TripLoadStatus.loaded && stops.isEmpty);

  /// Stop being delivered, if any.
  DeliveryStop? get currentStop {
    if (stops.isEmpty) {
      return null;
    }
    return stops[currentIndex.clamp(0, stops.length - 1)];
  }

  /// Stops the summary reflects: the picked subset while picking (or the
  /// full assignment as a preview when nothing is picked yet).
  List<DeliveryStop> get summaryStops {
    if (phase != TripPhase.pickup || pickedCount == 0) {
      return stops;
    }
    return stops
        .where((DeliveryStop s) => s.status != OrderStatus.assigned)
        .toList();
  }

  /// Items across [summaryStops].
  int get summaryItems =>
      summaryStops.fold(0, (int a, DeliveryStop s) => a + s.itemCount);

  /// Minutes across [summaryStops]: the server's warehouse → first stop ETA,
  /// then each further leg at the same pace (see [_routeKm]).
  int get summaryEtaMinutes {
    final List<DeliveryStop> route = summaryStops;
    if (route.isEmpty) {
      return 0;
    }
    final DeliveryStop first = route.first;
    if (first.distanceKm <= 0) {
      return route.fold(0, (int a, DeliveryStop s) => a + s.etaMinutes);
    }
    final double minPerKm = first.etaMinutes / first.distanceKm;
    return (first.etaMinutes + (_routeKm(route) - first.distanceKm) * minPerKm)
        .round();
  }

  /// Total route distance across [stops] (warehouse → stop 1 → stop 2 …).
  double get tripDistanceKm => _routeKm(stops);

  /// Each stop's `distanceKm` is the server's straight-line warehouse → that
  /// customer distance, so summing them counted the trip from the warehouse
  /// once per stop (3 stops at one address showed 38.1 km for a 12.7 km
  /// trip). Use the first stop's distance, then the straight-line legs
  /// between consecutive stops - the same method as the server's
  /// `route.distance_km` on `GET /delivery-trips/{id}/`.
  static double _routeKm(List<DeliveryStop> route) {
    if (route.isEmpty) {
      return 0;
    }
    double km = route.first.distanceKm;
    for (int i = 1; i < route.length; i++) {
      final DeliveryStop a = route[i - 1];
      final DeliveryStop b = route[i];
      final bool located = a.latitude != 0 && b.latitude != 0;
      km += located
          ? _haversineKm(a.latitude, a.longitude, b.latitude, b.longitude)
          : b.distanceKm;
    }
    return km;
  }

  static double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const double r = 6371;
    double rad(double d) => d * math.pi / 180;
    final double dLat = rad(lat2 - lat1);
    final double dLng = rad(lng2 - lng1);
    final double h = math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(lat1)) *
            math.cos(rad(lat2)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * r * math.asin(math.sqrt(h));
  }

  /// Progress fraction for the summary bar.
  double get progress {
    if (stops.isEmpty) {
      return 0;
    }
    final int numerator = phase == TripPhase.pickup ? pickedCount : doneCount;
    return numerator / stops.length;
  }

  /// Cash collected on delivered COD orders (rupees).
  int get codCollected => stops
      .where(
        (DeliveryStop s) =>
            s.paymentMode == PaymentMode.cod &&
            s.status == OrderStatus.delivered,
      )
      .fold(0, (int a, DeliveryStop s) => a + s.amount);

  /// Trip Complete distance: the server's trip total, else [tripDistanceKm].
  double get completedDistanceKm => wrapUp.distanceKm ?? tripDistanceKm;

  /// Trip Complete "Cash to deposit": all COD cash the rider holds, else
  /// [codCollected] from this trip.
  int get cashToDeposit => wrapUp.cashToDeposit ?? codCollected;
}
