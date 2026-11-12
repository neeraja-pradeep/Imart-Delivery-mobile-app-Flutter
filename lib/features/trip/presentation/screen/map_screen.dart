import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:imart_delivery_app/features/trip/application/providers/trip_providers.dart';
import 'package:imart_delivery_app/features/trip/application/states/trip_state.dart';
import 'package:imart_delivery_app/features/trip/presentation/components/state_views/navigation_locked_section.dart';
import 'package:imart_delivery_app/features/trip/presentation/components/state_views/on_leave_section.dart';
import 'package:imart_delivery_app/features/trip/presentation/screen/navigation_screen.dart';
import 'package:imart_delivery_app/features/trip/presentation/screen/trip_complete_screen.dart';

/// Map tab: live navigation while delivering, otherwise the matching
/// locked / complete / leave state.
class MapScreen extends ConsumerWidget {
  /// Creates the tab.
  const MapScreen({super.key});

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
      TripPhase.enroute => const NavigationScreen(),
      TripPhase.complete => const TripCompleteScreen(),
      TripPhase.pickup || TripPhase.arrange => const NavigationLockedSection(),
    };
  }
}
