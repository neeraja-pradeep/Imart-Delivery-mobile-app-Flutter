import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/app/config/env.dart';
import 'package:imart_delivery_app/core/error/failure.dart';
import 'package:imart_delivery_app/core/network/network_providers.dart';
import 'package:imart_delivery_app/core/utils/logger.dart';
import 'package:imart_delivery_app/features/auth/application/providers/auth_providers.dart';
import 'package:imart_delivery_app/features/trip/application/states/trip_state.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/delivery_stop.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/fail_reason.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/order_status.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/trip_wrap_up.dart';
import 'package:imart_delivery_app/features/trip/domain/repositories/trip_repository.dart';
import 'package:imart_delivery_app/features/trip/infrastructure/data_sources/local/location_local_ds.dart';
import 'package:imart_delivery_app/features/trip/infrastructure/data_sources/remote/trip_api.dart';
import 'package:imart_delivery_app/features/trip/infrastructure/data_sources/remote/trip_remote_api.dart';
import 'package:imart_delivery_app/features/trip/infrastructure/data_sources/remote/trip_static_api.dart';
import 'package:imart_delivery_app/features/trip/infrastructure/repositories/trip_repository_impl.dart';

/// Trip data source: the backend, or fixtures when no `API_BASE_URL` is set.
final Provider<TripApi> tripApiProvider = Provider<TripApi>(
  (Ref ref) => Env.current.useStaticData
      ? TripStaticApi(preview: Env.current.previewScreen)
      : TripRemoteApi(ref.watch(apiClientProvider)),
);

/// Trip repository.
final Provider<TripRepository> tripRepositoryProvider =
    Provider<TripRepository>(
      (Ref ref) => TripRepositoryImpl(ref.watch(tripApiProvider)),
    );

/// Device location, shared with the customer while delivering.
final Provider<LocationLocalDs> locationLocalDsProvider =
    Provider<LocationLocalDs>((Ref ref) => const LocationLocalDs());

/// The rider's latest GPS position while a trip is under way (`null`
/// before the first fix). Drives the rider's dot on the map.
final StateNotifierProvider<RiderPositionController, GeoPosition?>
riderPositionProvider =
    StateNotifierProvider<RiderPositionController, GeoPosition?>(
      (Ref ref) => RiderPositionController(),
    );

/// Holds the rider's latest position.
class RiderPositionController extends StateNotifier<GeoPosition?> {
  /// Creates the controller with no position.
  RiderPositionController() : super(null);

  /// Records a new position.
  void update(GeoPosition position) => state = position;

  /// Forgets the position (sign-out).
  void clear() => state = null;
}

/// The rider's trip workflow. Cleared on sign-out so the next rider starts
/// fresh.
final StateNotifierProvider<TripController, TripState> tripControllerProvider =
    StateNotifierProvider<TripController, TripState>((Ref ref) {
      final bool live = !Env.current.useStaticData;
      final TripController controller = TripController(
        ref.watch(tripRepositoryProvider),
        location: live ? ref.watch(locationLocalDsProvider) : null,
        pollForTrips: live,
        onPosition: ref.read(riderPositionProvider.notifier).update,
      );
      ref.listen<bool>(isAuthenticatedProvider, (bool? _, bool signedIn) {
        if (!signedIn) {
          controller.reset();
          ref.read(riderPositionProvider.notifier).clear();
        }
      });
      return controller;
    });

/// Fail reasons offered in the "Mark as Failed" sheet (fetched per rider).
final FutureProvider<List<FailReason>> failReasonsProvider =
    FutureProvider<List<FailReason>>((Ref ref) {
      if (!ref.watch(isAuthenticatedProvider)) {
        return const <FailReason>[];
      }
      return ref.watch(tripRepositoryProvider).fetchFailReasonsAsync();
    });

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
  /// Creates the controller. With a `location` source, the rider's position
  /// is sent while delivering; with `pollForTrips`, an idle rider is checked
  /// for a new trip every [ApiConfig.newTripPollInterval]; `onPosition`
  /// receives every GPS fix (for the rider's dot on the map).
  TripController(
    this._repository, {
    this._location,
    this._pollForTrips = false,
    this._onPosition,
  }) : super(const TripState());

  final TripRepository _repository;
  final LocationLocalDs? _location;
  final bool _pollForTrips;
  final void Function(GeoPosition position)? _onPosition;
  Timer? _pollTimer;
  StreamSubscription<GeoPosition>? _positionSub;
  bool _pinging = false;

  @override
  void dispose() {
    _stopBackgroundWork();
    super.dispose();
  }

  /// Loads the assigned stops and leave status, and derives the phase from
  /// the server statuses.
  Future<void> loadTripAsync() async {
    state = state.copyWith(loadStatus: TripLoadStatus.loading);
    try {
      final List<Object> results = await Future.wait<Object>(<Future<Object>>[
        _repository.fetchAssignedStopsAsync(),
        _repository.fetchIsOnLeaveAsync(),
      ]);
      if (!mounted) {
        return;
      }
      state = _stateFor(
        results[0] as List<DeliveryStop>,
        onLeave: results[1] as bool,
      );
      await _resumeNextStopAsync();
      if (state.phase == TripPhase.complete) {
        await _loadWrapUpAsync();
      }
    } catch (error, stackTrace) {
      AppLogger.log('Trip load failed', error: error, stackTrace: stackTrace);
      if (mounted) {
        state = state.copyWith(loadStatus: TripLoadStatus.error);
      }
    }
    _syncBackgroundWork();
  }

  /// Clears the trip (sign-out).
  void reset() {
    _stopBackgroundWork();
    state = const TripState();
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
    await _repository.startTripAsync(route);
    final List<DeliveryStop> next = List<DeliveryStop>.of(route);
    next[0] = next[0].copyWith(status: OrderStatus.outForDelivery);
    state = state.copyWith(
      assignedStops: fromPickup ? state.stops : null,
      stops: next,
      phase: TripPhase.enroute,
      currentIndex: 0,
      arrived: false,
    );
    _syncBackgroundWork();
  }

  /// Confirms arrival at the current stop (unlocks "Mark Delivered").
  Future<void> markArrivedAsync() async {
    final DeliveryStop? stop = state.currentStop;
    if (stop == null) {
      return;
    }
    await _repository.markArrivedAsync(stop);
    state = state.copyWith(arrived: true);
  }

  /// Marks the current stop delivered and advances.
  Future<void> markDeliveredAsync({required bool cashCollected}) async {
    final DeliveryStop? stop = state.currentStop;
    if (stop == null) {
      return;
    }
    await _repository.markDeliveredAsync(stop, cashCollected: cashCollected);
    await _finishCurrentAsync(OrderStatus.delivered);
  }

  /// Marks the current stop failed with [reasonId] and advances.
  Future<void> markFailedAsync(String reasonId) async {
    final DeliveryStop? stop = state.currentStop;
    if (stop == null) {
      return;
    }
    await _repository.markFailedAsync(stop, reasonId);
    await _finishCurrentAsync(OrderStatus.failed);
  }

  /// Puts the rider on leave (only when no trip is active).
  Future<void> markLeaveAsync() async {
    if (!state.canMarkLeave) {
      return;
    }
    await _repository.setOnLeaveAsync(onLeave: true);
    state = state.copyWith(onLeave: true);
    _syncBackgroundWork();
  }

  /// Ends leave and fetches a fresh trip.
  Future<void> endLeaveAsync() async {
    await _repository.setOnLeaveAsync(onLeave: false);
    state = state.copyWith(onLeave: false);
    await loadTripAsync();
  }

  Future<void> _finishCurrentAsync(OrderStatus status) async {
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
      _syncBackgroundWork();
      await _loadWrapUpAsync();
      return;
    }
    next[upcoming] = next[upcoming].copyWith(
      status: OrderStatus.outForDelivery,
    );
    state = state.copyWith(stops: next, currentIndex: upcoming, arrived: false);
    await _sendOutForDeliveryAsync(next[upcoming]);
  }

  // Trip Complete falls back to the app's own figures if this fails.
  Future<void> _loadWrapUpAsync() async {
    try {
      final TripWrapUp wrapUp = await _repository.fetchTripWrapUpAsync();
      if (mounted && state.phase == TripPhase.complete) {
        state = state.copyWith(wrapUp: wrapUp);
      }
    } on Failure catch (failure) {
      AppLogger.log('Trip wrap-up unavailable', error: failure);
    }
  }

  /// After a restart between stops, nothing is out for delivery yet: send
  /// the rider on to the next picked-up stop.
  Future<void> _resumeNextStopAsync() async {
    final bool started = state.stops.any(
      (DeliveryStop s) => s.status.isTerminal,
    );
    final bool delivering = state.stops.any(
      (DeliveryStop s) => s.status == OrderStatus.outForDelivery,
    );
    final int upcoming = state.stops.indexWhere(
      (DeliveryStop s) => s.status == OrderStatus.pickedUp,
    );
    if (!started || delivering || upcoming < 0) {
      return;
    }
    final List<DeliveryStop> next = List<DeliveryStop>.of(state.stops);
    next[upcoming] = next[upcoming].copyWith(
      status: OrderStatus.outForDelivery,
    );
    state = state.copyWith(
      stops: next,
      phase: TripPhase.enroute,
      currentIndex: upcoming,
      arrived: false,
      clearAssigned: true,
    );
    await _sendOutForDeliveryAsync(next[upcoming]);
  }

  // A failure here is logged, not thrown: the previous stop is already
  // recorded, and the next load resumes this step.
  Future<void> _sendOutForDeliveryAsync(DeliveryStop stop) async {
    try {
      await _repository.markOutForDeliveryAsync(stop);
    } on Failure catch (failure) {
      AppLogger.log('Out-for-delivery not sent', error: failure);
    }
  }

  /// Starts or stops polling for a new trip and sharing location, to match
  /// the current phase.
  void _syncBackgroundWork() {
    if (!mounted) {
      return;
    }
    final bool loaded =
        state.loadStatus == TripLoadStatus.loaded && !state.onLeave;
    final bool idle = loaded && state.stops.isEmpty;
    // While still at the warehouse the admin can add orders to the trip or
    // unassign them, so keep checking during pickup as well; otherwise the
    // rider keeps seeing orders that are no longer theirs (and never sees
    // new ones) until the app is restarted.
    final bool atPickup = loaded && state.phase == TripPhase.pickup;
    if (_pollForTrips && (idle || atPickup)) {
      _pollTimer ??= Timer.periodic(
        ApiConfig.newTripPollInterval,
        (_) => _checkForNewTripAsync(),
      );
    } else {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
    // Tracking runs only while the trip is under way. Listening starts the
    // "Tracking your delivery" foreground service; cancelling stops it.
    final LocationLocalDs? location = _location;
    if (location != null && state.phase == TripPhase.enroute) {
      _positionSub ??= location.watchPositions().listen(
        _sendPositionAsync,
        onError: (Object error) =>
            AppLogger.log('Location stream error', error: error),
      );
    } else {
      _stopTracking();
    }
  }

  void _stopBackgroundWork() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _stopTracking();
  }

  void _stopTracking() {
    _positionSub?.cancel();
    _positionSub = null;
  }

  Future<void> _checkForNewTripAsync() async {
    try {
      final List<DeliveryStop> stops = await _repository
          .fetchAssignedStopsAsync();
      if (!mounted) {
        return;
      }
      if (stops.isNotEmpty && state.stops.isEmpty) {
        state = _stateFor(stops, onLeave: state.onLeave);
        _syncBackgroundWork();
      } else if (state.phase == TripPhase.pickup &&
          state.loadStatus == TripLoadStatus.loaded) {
        _applyPickupChanges(stops);
      }
    } on Failure catch (failure) {
      AppLogger.log('New-trip check failed', error: failure);
    }
  }

  // One request at a time; a position that arrives while one is in flight
  // is skipped (the next one follows within seconds). The server passes
  // each point to every customer on the trip, not just the current stop.
  Future<void> _sendPositionAsync(GeoPosition position) async {
    _onPosition?.call(position);
    if (_pinging || state.phase != TripPhase.enroute) {
      return;
    }
    _pinging = true;
    try {
      await _repository.pushLocationAsync(position);
    } on Failure catch (failure) {
      AppLogger.log('Location ping failed', error: failure);
    } finally {
      _pinging = false;
    }
  }

  static List<DeliveryStop> _picked(List<DeliveryStop> stops) => stops
      .where((DeliveryStop s) => s.status == OrderStatus.pickedUp)
      .toList();

  /// Derives the phase from server statuses, so a resumed trip lands on
  /// the right step. Once the trip has started, orders the rider left at
  /// the warehouse (still `assigned`) are not part of it, as before the
  /// restart; they come back for the next trip.
  /// Merges a fresh assignment list into the pickup screen: adds newly
  /// assigned orders, drops unassigned ones, and keeps the rider's local
  /// "picked" ticks for orders that are still assigned.
  void _applyPickupChanges(List<DeliveryStop> fresh) {
    final Set<String> current = <String>{
      for (final DeliveryStop s in state.stops) s.orderId,
    };
    // What the server says this round is. The list can also hold orders
    // already finished earlier in the same open trip; those aren't part of
    // the pickup round and must not count as "moved on" (that reset the
    // rider's picks on every poll, so Start Trip never got going).
    final TripState fromServer = _stateFor(fresh, onLeave: state.onLeave);
    final Set<String> latest = <String>{
      for (final DeliveryStop s in fromServer.stops) s.orderId,
    };
    // The admin can also move an order on from the panel (Out for delivery,
    // Mark delivered). Follow the server once an order on this pickup screen
    // has left `assigned`.
    final bool serverMovedOn =
        fromServer.phase != TripPhase.pickup ||
        fresh.any(
          (DeliveryStop s) =>
              current.contains(s.orderId) && s.status != OrderStatus.assigned,
        );
    if (serverMovedOn) {
      state = fromServer;
      _syncBackgroundWork();
      if (state.phase == TripPhase.complete) {
        unawaited(_loadWrapUpAsync());
      }
      return;
    }
    if (current.length == latest.length && current.containsAll(latest)) {
      return;
    }
    if (fresh.isEmpty) {
      state = _stateFor(const <DeliveryStop>[], onLeave: state.onLeave);
      _syncBackgroundWork();
      return;
    }
    final Set<String> pickedLocally = <String>{
      for (final DeliveryStop s in state.stops)
        if (s.status == OrderStatus.pickedUp) s.orderId,
    };
    final TripState next = fromServer;
    if (next.phase != TripPhase.pickup) {
      state = next;
    } else {
      state = next.copyWith(
        stops: <DeliveryStop>[
          for (final DeliveryStop s in next.stops)
            pickedLocally.contains(s.orderId) &&
                    s.status == OrderStatus.assigned
                ? s.copyWith(status: OrderStatus.pickedUp)
                : s,
        ],
      );
    }
    _syncBackgroundWork();
  }

  static TripState _stateFor(
    List<DeliveryStop> allStops, {
    required bool onLeave,
  }) {
    final List<DeliveryStop> begun = allStops
        .where((DeliveryStop s) => s.status != OrderStatus.assigned)
        .toList();
    final List<DeliveryStop> waiting = allStops
        .where((DeliveryStop s) => s.status == OrderStatus.assigned)
        .toList();
    // Once every started order is finished, orders still waiting at the
    // warehouse (left behind at pickup, or added to the open trip later) are
    // the next round. They used to be dropped here, leaving the rider on
    // Trip Complete with "Start New Trip" doing nothing.
    final bool roundDone =
        begun.isNotEmpty &&
        begun.every((DeliveryStop s) => s.status.isTerminal) &&
        waiting.isNotEmpty;
    final bool started = begun.isNotEmpty && !roundDone;
    final List<DeliveryStop> stops = started
        ? begun
        : (roundDone ? waiting : allStops);
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
