import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:imart_delivery_app/features/trip/application/providers/trip_providers.dart';
import 'package:imart_delivery_app/features/trip/application/states/trip_state.dart';
import 'package:imart_delivery_app/features/trip/presentation/components/state_views/no_trip_section.dart';
import 'package:imart_delivery_app/features/trip/presentation/components/state_views/on_leave_section.dart';
import 'package:imart_delivery_app/features/trip/presentation/screen/arrange_route_screen.dart';
import 'package:imart_delivery_app/features/trip/presentation/screen/trip_complete_screen.dart';
import 'package:imart_delivery_app/features/trip/presentation/screen/trip_list_screen.dart';

/// Trip tab: shows the view for the current workflow phase.
class TripScreen extends ConsumerWidget {
  /// Creates the tab.
  const TripScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TripState trip = ref.watch(tripControllerProvider);
    if (trip.onLeave) {
      return const OnLeaveSection();
    }
    if (trip.loadStatus != TripLoadStatus.loaded) {
      return const ColoredBox(color: Colors.white);
    }
    return switch (trip.phase) {
      TripPhase.complete => const TripCompleteScreen(),
      TripPhase.arrange => const ArrangeRouteScreen(),
      TripPhase.pickup when trip.stops.isEmpty => const NoTripSection(),
      TripPhase.pickup || TripPhase.enroute => const TripListScreen(),
    };
  }
}
