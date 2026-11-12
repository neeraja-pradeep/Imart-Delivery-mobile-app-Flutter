import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:imart_delivery_app/features/trip/application/providers/trip_providers.dart';
import 'package:imart_delivery_app/features/trip/application/states/trip_state.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/order_status.dart';

import '../../helpers/fake_trip_api.dart';

void main() {
  late FakeTripApi api;
  late ProviderContainer container;

  TripController controller() =>
      container.read(tripControllerProvider.notifier);
  TripState state() => container.read(tripControllerProvider);

  setUpAll(FakeTripApi.warmUpAsync);

  setUp(() async {
    api = FakeTripApi();
    container = ProviderContainer(
      overrides: <Override>[tripApiProvider.overrideWithValue(api)],
    );
    await controller().loadTripAsync();
  });

  tearDown(() => container.dispose());

  test('loads the assignment in pickup with design summary values', () {
    expect(state().loadStatus, TripLoadStatus.loaded);
    expect(state().phase, TripPhase.pickup);
    expect(state().stopCount, 4);
    expect(state().summaryItems, 19);
    expect(state().summaryEtaMinutes, 72);
    expect(state().canStartTrip, isFalse);
  });

  test('summary reflects only the picked subset', () {
    controller().setPicked('#IM-4822', picked: true);
    expect(state().pickedCount, 1);
    expect(state().summaryStops.length, 1);
    expect(state().summaryItems, 3);
    expect(state().summaryEtaMinutes, 14);
    expect(state().progress, 0.25);
  });

  test('a single picked order skips arrange', () async {
    controller().setPicked('#IM-4822', picked: true);
    expect(controller().beginArrange(), isFalse);
    expect(state().phase, TripPhase.pickup);
    await controller().startNavigationAsync();
    expect(state().phase, TripPhase.enroute);
    expect(state().stops.single.status, OrderStatus.outForDelivery);
    expect(api.startedWith, <String>['#IM-4822']);
  });

  test('arrange keeps only picked orders and Back restores all', () {
    controller()
      ..setPicked('#IM-4821', picked: true)
      ..setPicked('#IM-4824', picked: true);
    expect(controller().beginArrange(), isTrue);
    expect(state().phase, TripPhase.arrange);
    expect(state().stopCount, 2);
    controller().backToPickup();
    expect(state().phase, TripPhase.pickup);
    expect(state().stopCount, 4);
    expect(state().pickedCount, 2);
  });

  test('reorder and optimize change the delivery order sent', () async {
    for (final String id in <String>['#IM-4821', '#IM-4822', '#IM-4824']) {
      controller().setPicked(id, picked: true);
    }
    controller()
      ..beginArrange()
      ..moveStop(2, -1)
      ..moveStop(0, -1);
    expect(state().stops.map((s) => s.orderId), <String>[
      '#IM-4821',
      '#IM-4824',
      '#IM-4822',
    ]);
    controller().optimizeRoute();
    await controller().startNavigationAsync();
    expect(api.startedWith, <String>['#IM-4821', '#IM-4822', '#IM-4824']);
  });

  test('deliver / fail advance stops and complete the trip', () async {
    for (final String id in <String>['#IM-4821', '#IM-4822']) {
      controller().setPicked(id, picked: true);
    }
    controller().beginArrange();
    await controller().startNavigationAsync();
    expect(state().arrived, isFalse);
    await controller().markArrivedAsync();
    expect(state().arrived, isTrue);
    await controller().markDeliveredAsync(cashCollected: false);
    expect(state().currentIndex, 1);
    expect(state().arrived, isFalse);
    expect(state().currentStop?.status, OrderStatus.outForDelivery);
    await controller().markFailedAsync('customer_unavailable');
    expect(state().phase, TripPhase.complete);
    expect(state().deliveredCount, 1);
    expect(state().failedCount, 1);
    expect(state().codCollected, 0);
    expect(api.failed, <String, String>{'#IM-4822': 'customer_unavailable'});
  });

  test('cash to deposit sums delivered COD orders only', () async {
    for (final String id in <String>['#IM-4822', '#IM-4824']) {
      controller().setPicked(id, picked: true);
    }
    controller().beginArrange();
    await controller().startNavigationAsync();
    await controller().markDeliveredAsync(cashCollected: true);
    await controller().markDeliveredAsync(cashCollected: true);
    expect(state().codCollected, 872);
    expect(state().tripDistanceKm, closeTo(15.1, 0.001));
  });

  test('leave is blocked until the trip is complete', () async {
    await controller().markLeaveAsync();
    expect(state().onLeave, isFalse);
    expect(api.leaveCalls, isEmpty);

    controller().setPicked('#IM-4821', picked: true);
    await controller().startNavigationAsync();
    await controller().markDeliveredAsync(cashCollected: false);
    expect(state().canMarkLeave, isTrue);
    await controller().markLeaveAsync();
    expect(state().onLeave, isTrue);
    await controller().endLeaveAsync();
    expect(state().onLeave, isFalse);
    expect(state().phase, TripPhase.pickup);
    expect(api.leaveCalls, <bool>[true, false]);
  });

  test('a failed load surfaces the error state', () async {
    api.failFetch = true;
    await controller().loadTripAsync();
    expect(state().loadStatus, TripLoadStatus.error);
  });
}
