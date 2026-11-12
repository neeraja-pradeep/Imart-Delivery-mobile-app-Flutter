import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:imart_delivery_app/app/config/env.dart';
import 'package:imart_delivery_app/core/utils/logger.dart';
import 'package:imart_delivery_app/features/trip/application/states/trip_state.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/delivery_stop.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/fail_reason.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/order_status.dart';
import 'package:imart_delivery_app/features/trip/domain/repositories/trip_repository.dart';
import 'package:imart_delivery_app/features/trip/infrastructure/data_sources/remote/trip_api.dart';
import 'package:imart_delivery_app/features/trip/infrastructure/data_sources/remote/trip_static_api.dart';
import 'package:imart_delivery_app/features/trip/infrastructure/repositories/trip_repository_impl.dart';

/// Trip data source. **Swap point for API integration**: return the
/// Dio-backed `TripApi` here instead of [TripStaticApi].
final Provider<TripApi> tripApiProvider = Provider<TripApi>(
  (Ref ref) => TripStaticApi(preview: Env.current.previewScreen),
);

/// Trip repository.
final Provider<TripRepository> tripRepositoryProvider =
    Provider<TripRepository>(
      (Ref ref) => TripRepositoryImpl(ref.watch(tripApiProvider)),
    );

/// The rider's trip workflow.
final StateNotifierProvider<TripController, TripState> tripControllerProvider =
    StateNotifierProvider<TripController, TripState>(
      (Ref ref) => TripController(ref.watch(tripRepositoryProvider)),
    );

/// Fail reasons offered in the "Mark as Failed" sheet.
final FutureProvider<List<FailReason>> failReasonsProvider =
    FutureProvider<List<FailReason>>(
      (Ref ref) => ref.watch(tripRepositoryProvider).fetchFailReasonsAsync(),
    );

/// Which stop card is expanded (UI-only, resets when the screen leaves).
final AutoDisposeStateProvider<String?> expandedStopIdProvider =
    StateProvider.autoDispose<String?>((Ref ref) => null);

/// Reason selected in the fail sheet (UI-only).
final AutoDisposeStateProvider<String?> selectedFailReasonProvider =
    StateProvider.autoDispose<String?>((Ref ref) => null);

/// "I have collected cash" tick in the confirm sheet (UI-only).
final AutoDisposeStateProvider<bool> isCashCollectedProvider =
    StateProvider.autoDispose<bool>((Ref ref) => false);

/// Drives pickup → arrange → enroute → complete.
class TripController extends StateNotifier<TripState> {
  /// Creates the controller.
  TripController(this._repository) : super(const TripState());

  final TripRepository _repository;

  /// Loads the assigned stops and derives the phase from their statuses.
  Future<void> loadTripAsync() async {
    state = state.copyWith(loadStatus: TripLoadStatus.loading);
    try {
      final List<DeliveryStop> stops = await _repository
          .fetchAssignedStopsAsync();
      state = _stateFor(stops, onLeave: state.onLeave);
    } catch (error, stackTrace) {
      AppLogger.log('Trip load failed', error: error, stackTrace: stackTrace);
      state = state.copyWith(loadStatus: TripLoadStatus.error);
    }
  }

  /// Adds or removes an order from this trip during pickup.
  void setPicked(String orderId, {required bool picked}) {
    if (state.phase != TripPhase.pickup) {
      return;
    }
    state = state.copyWith(
      stops: <DeliveryStop>[
        for (final DeliveryStop s in state.stops)
          s.orderId == orderId
              ? s.copyWith(
                  status: picked ? OrderStatus.pickedUp : OrderStatus.assigned,
                )
              : s,
      ],
    );
  }

  /// Moves from pickup to arrange with only the picked orders.
  ///
  /// Returns `false` when exactly one order is picked — that trip skips
  /// arranging and the caller should go straight to
  /// [startNavigationAsync].
  bool beginArrange() {
    if (!state.canStartTrip) {
      return false;
    }
    if (state.pickedCount == 1) {
      return false;
    }
    state = state.copyWith(
      assignedStops: state.stops,
      stops: _picked(state.stops),
      phase: TripPhase.arrange,
    );
    return true;
  }

  /// Returns from arrange to pickup, restoring the full assignment.
  void backToPickup() {
    state = state.copyWith(
      stops: state.assignedStops ?? state.stops,
      phase: TripPhase.pickup,
      clearAssigned: true,
    );
  }

  /// Swaps the stop at [index] with its neighbour in [direction] (-1 / 1).
  void moveStop(int index, int direction) {
    if (state.phase != TripPhase.pickup && state.phase != TripPhase.arrange) {
      return;
    }
    final int target = index + direction;
    if (target < 0 || target >= state.stops.length) {
      return;
    }
    final List<DeliveryStop> next = List<DeliveryStop>.of(state.stops);
    final DeliveryStop moved = next[index];
    next[index] = next[target];
    next[target] = moved;
    state = state.copyWith(stops: next);
  }

  /// Sorts stops nearest-first.
  void optimizeRoute() {
    final List<DeliveryStop> next = List<DeliveryStop>.of(state.stops)
      ..sort(
        (DeliveryStop a, DeliveryStop b) =>
            a.distanceKm.compareTo(b.distanceKm),
      );
    state = state.copyWith(stops: next);
  }

  /// Sends the route to the server and starts delivering the first stop.
  Future<void> startNavigationAsync() async {
    final bool fromPickup = state.phase == TripPhase.pickup;
    final List<DeliveryStop> route = fromPickup
        ? _picked(state.stops)
        : state.stops;
    if (route.isEmpty) {
      return;
    }
    await _repository.startTripAsync(
      route.map((DeliveryStop s) => s.orderId).toList(),
    );
    final List<DeliveryStop> next = List<DeliveryStop>.of(route);
    next[0] = next[0].copyWith(status: OrderStatus.outForDelivery);
    state = state.copyWith(
      assignedStops: fromPickup ? state.stops : null,
      stops: next,
      phase: TripPhase.enroute,
      currentIndex: 0,
      arrived: false,
    );
  }

  /// Confirms arrival at the current stop (unlocks "Mark Delivered").
  Future<void> markArrivedAsync() async {
    final DeliveryStop? stop = state.currentStop;
    if (stop == null) {
      return;
    }
    await _repository.markArrivedAsync(stop.orderId);
    state = state.copyWith(arrived: true);
  }

  /// Marks the current stop delivered and advances.
  Future<void> markDeliveredAsync({required bool cashCollected}) async {
    final DeliveryStop? stop = state.currentStop;
    if (stop == null) {
      return;
    }
    await _repository.markDeliveredAsync(
      stop.orderId,
      cashCollected: cashCollected,
    );
    _finishCurrent(OrderStatus.delivered);
  }

  /// Marks the current stop failed with [reasonId] and advances.
  Future<void> markFailedAsync(String reasonId) async {
    final DeliveryStop? stop = state.currentStop;
    if (stop == null) {
      return;
    }
    await _repository.markFailedAsync(stop.orderId, reasonId);
    _finishCurrent(OrderStatus.failed);
  }

  /// Puts the rider on leave (only when no trip is active).
  Future<void> markLeaveAsync() async {
    if (!state.canMarkLeave) {
      return;
    }
    await _repository.setOnLeaveAsync(onLeave: true);
    state = state.copyWith(onLeave: true);
  }

  /// Ends leave and fetches a fresh trip.
  Future<void> endLeaveAsync() async {
    await _repository.setOnLeaveAsync(onLeave: false);
    state = state.copyWith(onLeave: false);
    await loadTripAsync();
  }

  void _finishCurrent(OrderStatus status) {
    final List<DeliveryStop> next = List<DeliveryStop>.of(state.stops);
    next[state.currentIndex] = next[state.currentIndex].copyWith(
      status: status,
    );
    final int upcoming = next.indexWhere(
      (DeliveryStop s) => s.status == OrderStatus.pickedUp,
    );
    if (upcoming < 0) {
      state = state.copyWith(
        stops: next,
        phase: TripPhase.complete,
        arrived: false,
      );
      return;
    }
    next[upcoming] = next[upcoming].copyWith(
      status: OrderStatus.outForDelivery,
    );
    state = state.copyWith(stops: next, currentIndex: upcoming, arrived: false);
  }

  static List<DeliveryStop> _picked(List<DeliveryStop> stops) => stops
      .where((DeliveryStop s) => s.status == OrderStatus.pickedUp)
      .toList();

  /// Derives the phase from server statuses, so a resumed trip lands on
  /// the right step.
  static TripState _stateFor(
    List<DeliveryStop> stops, {
    required bool onLeave,
  }) {
    final int current = stops.indexWhere(
      (DeliveryStop s) => s.status == OrderStatus.outForDelivery,
    );
    TripPhase phase = TripPhase.pickup;
    if (current >= 0) {
      phase = TripPhase.enroute;
    } else if (stops.isNotEmpty &&
        stops.every((DeliveryStop s) => s.status.isTerminal)) {
      phase = TripPhase.complete;
    } else if (stops.isNotEmpty &&
        stops.every((DeliveryStop s) => s.status == OrderStatus.pickedUp)) {
      phase = TripPhase.arrange;
    }
    return TripState(
      loadStatus: TripLoadStatus.loaded,
      phase: phase,
      stops: stops,
      assignedStops: phase == TripPhase.arrange ? stops : null,
      currentIndex: current < 0 ? 0 : current,
      onLeave: onLeave,
    );
  }
}
