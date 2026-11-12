import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/features/common/feedback/application/states/app_feedback_state.dart';

/// App-wide loader / toast state.
final StateNotifierProvider<AppFeedbackController, AppFeedbackState>
appFeedbackProvider =
    StateNotifierProvider<AppFeedbackController, AppFeedbackState>(
      (Ref ref) => AppFeedbackController(),
    );

/// `true` while the device has no network.
final StreamProvider<bool> isOfflineProvider = StreamProvider<bool>((
  Ref ref,
) async* {
  final Connectivity connectivity = Connectivity();
  bool offline(List<ConnectivityResult> results) =>
      results.every((ConnectivityResult r) => r == ConnectivityResult.none);
  yield offline(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(offline);
});

/// Owns the blocking loader and toast lifecycle.
class AppFeedbackController extends StateNotifier<AppFeedbackState> {
  /// Creates the controller.
  AppFeedbackController() : super(const AppFeedbackState());

  Timer? _toastTimer;

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  /// Shows the loader with [message] while [task] runs.
  Future<T> runWithLoadingAsync<T>(
    String message,
    Future<T> Function() task,
  ) async {
    state = AppFeedbackState(loadingMessage: message, toast: state.toast);
    try {
      return await task();
    } finally {
      if (mounted) {
        state = AppFeedbackState(toast: state.toast);
      }
    }
  }

  /// Shows a toast that hides itself after [AppTimings.toast].
  void showToast(String message, {FeedbackTone tone = FeedbackTone.success}) {
    _toastTimer?.cancel();
    state = AppFeedbackState(
      loadingMessage: state.loadingMessage,
      toast: FeedbackToast(message: message, tone: tone),
    );
    _toastTimer = Timer(AppTimings.toast, () {
      if (mounted) {
        state = AppFeedbackState(loadingMessage: state.loadingMessage);
      }
    });
  }
}
