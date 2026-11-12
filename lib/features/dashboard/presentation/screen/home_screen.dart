import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/app/router/app_routes.dart';
import 'package:imart_delivery_app/core/widgets/app_icon.dart';
import 'package:imart_delivery_app/core/widgets/navbar.dart';
import 'package:imart_delivery_app/features/common/feedback/application/providers/app_feedback_provider.dart';
import 'package:imart_delivery_app/features/dashboard/presentation/components/trip_load_error_section.dart';
import 'package:imart_delivery_app/features/trip/application/providers/trip_providers.dart';
import 'package:imart_delivery_app/features/trip/application/states/trip_state.dart';

/// Signed-in shell: active tab content, fixed bottom nav, and the
/// full-screen "Connection Lost" state when the trip fails to load.
class HomeScreen extends ConsumerStatefulWidget {
  /// Creates the shell.
  const HomeScreen({super.key, required this.location, required this.child});

  /// Current matched route.
  final String location;

  /// Active tab content.
  final Widget child;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const List<AppNavItem> _items = <AppNavItem>[
    AppNavItem(label: AppStrings.tabTrip, glyph: AppIconGlyph.home),
    AppNavItem(label: AppStrings.tabMap, glyph: AppIconGlyph.navigation),
    AppNavItem(label: AppStrings.tabProfile, glyph: AppIconGlyph.user),
  ];
  static const List<String> _tabRoutes = <String>[
    AppRoutes.trip,
    AppRoutes.map,
    AppRoutes.profile,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadIfIdleAsync());
  }

  Future<void> _loadIfIdleAsync() async {
    if (!mounted) {
      return;
    }
    final TripLoadStatus status = ref.read(
      tripControllerProvider.select((TripState s) => s.loadStatus),
    );
    if (status != TripLoadStatus.idle) {
      return;
    }
    await ref
        .read(appFeedbackProvider.notifier)
        .runWithLoadingAsync(
          AppStrings.loadingTrip,
          ref.read(tripControllerProvider.notifier).loadTripAsync,
        );
  }

  int get _currentIndex {
    final int index = _tabRoutes.lastIndexWhere(widget.location.startsWith);
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final bool loadFailed = ref.watch(
      tripControllerProvider.select(
        (TripState s) => s.loadStatus == TripLoadStatus.error,
      ),
    );
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: <Widget>[
          Positioned.fill(child: widget.child),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AppNavBar(
              items: _items,
              currentIndex: _currentIndex,
              onSelected: (int i) => context.go(_tabRoutes[i]),
            ),
          ),
          if (loadFailed) const Positioned.fill(child: TripLoadErrorSection()),
        ],
      ),
    );
  }
}
