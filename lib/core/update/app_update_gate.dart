import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:imart_delivery_app/core/update/app_update_service.dart';
import 'package:imart_delivery_app/features/trip/application/providers/trip_providers.dart';
import 'package:imart_delivery_app/features/trip/application/states/trip_state.dart';

/// Checks the Play Store for a newer app version when the app starts and when
/// it comes back to the foreground (at most every [_interval]; riders keep the
/// app open all day), and asks before restarting into a downloaded update.
///
/// A must-have update only takes over the screen when no delivery is under
/// way; mid-trip it downloads in the background and waits for the rider.
class AppUpdateGate extends ConsumerStatefulWidget {
  /// Creates the gate around [child]; dialogs use [navigatorKey].
  const AppUpdateGate({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  /// The router's navigator (this widget sits above it).
  final GlobalKey<NavigatorState> navigatorKey;

  /// The app.
  final Widget child;

  @override
  ConsumerState<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends ConsumerState<AppUpdateGate>
    with WidgetsBindingObserver {
  static const Duration _interval = Duration(hours: 6);
  static const Duration _snooze = Duration(hours: 1);

  DateTime? _lastCheck;
  bool _checking = false;
  bool _promptOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAsync());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAsync();
    }
  }

  Future<void> _checkAsync() async {
    final DateTime now = DateTime.now();
    final DateTime? last = _lastCheck;
    if (_checking || (last != null && now.difference(last) < _interval)) {
      return;
    }
    _checking = true;
    _lastCheck = now;
    try {
      final bool onTrip =
          ref.read(tripControllerProvider).phase == TripPhase.enroute;
      final AppUpdateOutcome outcome = await AppUpdateService.checkAsync(
        allowBlocking: !onTrip,
      );
      if (outcome == AppUpdateOutcome.readyToInstall) {
        await _promptInstallAsync();
      }
    } finally {
      _checking = false;
    }
  }

  Future<void> _promptInstallAsync() async {
    final BuildContext? context = widget.navigatorKey.currentContext;
    if (context == null || _promptOpen) {
      return;
    }
    final bool onTrip =
        ref.read(tripControllerProvider).phase == TripPhase.enroute;
    _promptOpen = true;
    final bool? restart = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Update ready'),
        content: Text(
          onTrip
              ? 'A new version of iMart Delivery has been downloaded. The app '
                    'restarts to install it; your trip is kept. You can also '
                    'install it after this trip.'
              : 'A new version of iMart Delivery has been downloaded. Restart '
                    'the app to install it.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Restart now'),
          ),
        ],
      ),
    );
    _promptOpen = false;
    if (restart ?? false) {
      await AppUpdateService.installAsync();
    } else {
      // "Later": ask again in about an hour rather than on every return to
      // the app (riders switch to the maps app constantly) or in 6 hours.
      _lastCheck = DateTime.now().subtract(_interval - _snooze);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
