import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:imart_delivery_app/core/widgets/app_button.dart';
import 'package:imart_delivery_app/features/trip/application/providers/trip_providers.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/delivery_stop.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/payment_mode.dart';
import 'package:imart_delivery_app/features/trip/presentation/components/confirm_delivery_sheet.dart';
import 'package:imart_delivery_app/features/trip/presentation/screen/trip_list_screen.dart';

import '../../helpers/fake_trip_api.dart';
import '../../helpers/pump_app.dart';

AppButton _button(WidgetTester tester, String label) =>
    tester.widget<AppButton>(find.widgetWithText(AppButton, label));

void main() {
  setUpAll(FakeTripApi.warmUpAsync);

  testWidgets('picking an order enables Start Trip with the count', (
    WidgetTester tester,
  ) async {
    final FakeTripApi api = FakeTripApi();
    await pumpInApp(
      tester,
      const TripListScreen(),
      overrides: <Override>[tripApiProvider.overrideWithValue(api)],
    );
    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(TripListScreen)),
    );
    await container.read(tripControllerProvider.notifier).loadTripAsync();
    await tester.pump();

    expect(find.text('Pick at least one order'), findsOneWidget);
    expect(_button(tester, 'Pick at least one order').enabled, isFalse);
    expect(find.text('0/4 picked'), findsOneWidget);

    await tester.tap(find.text('Mark Picked Up').first);
    await tester.pump();
    expect(find.text('Start Trip · 1 order'), findsOneWidget);
    expect(find.text('Added to this trip'), findsOneWidget);
    expect(find.text('1/4 picked'), findsOneWidget);

    await tester.tap(find.text('Ananya Rao'));
    await tester.pump();
    expect(find.text('ORDER CONTENTS · #IM-4821'), findsOneWidget);
    expect(find.text('Prepaid · ₹845 (no collection)'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('COD delivery stays blocked until cash is confirmed', (
    WidgetTester tester,
  ) async {
    await FakeTripApi.warmUpAsync();
    final DeliveryStop cod = (await FakeTripApi().fetchAssignedStopsAsync())
        .firstWhere((DeliveryStop s) => s.paymentMode == PaymentMode.cod);
    await pumpInApp(
      tester,
      SingleChildScrollView(child: ConfirmDeliverySheet(stop: cod)),
    );

    expect(find.text('Collect ₹312 · Cash on Delivery'), findsOneWidget);
    expect(_button(tester, 'Yes, Delivered').enabled, isFalse);

    await tester.tap(find.textContaining('from the customer in cash'));
    await tester.pump();
    expect(_button(tester, 'Yes, Delivered').enabled, isTrue);
  });
}
