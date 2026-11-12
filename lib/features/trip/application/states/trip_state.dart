import 'package:imart_delivery_app/features/trip/domain/entities/delivery_stop.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/order_status.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/payment_mode.dart';

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
  bool get canMarkLeave => phase == TripPhase.complete;

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

  /// Minutes across [summaryStops].
  int get summaryEtaMinutes =>
      summaryStops.fold(0, (int a, DeliveryStop s) => a + s.etaMinutes);

  /// Total route distance across [stops].
  double get tripDistanceKm =>
      stops.fold(0, (double a, DeliveryStop s) => a + s.distanceKm);

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
}
