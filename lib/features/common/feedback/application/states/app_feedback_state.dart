/// Tone of a transient confirmation.
enum FeedbackTone {
  /// Success (green).
  success,

  /// Warning (amber).
  warning,

  /// Neutral (charcoal).
  muted,
}

/// A transient confirmation message.
class FeedbackToast {
  /// Creates a toast.
  const FeedbackToast({required this.message, required this.tone});

  /// Text.
  final String message;

  /// Tone.
  final FeedbackTone tone;
}

/// App-wide transient UI feedback: blocking loader + toast.
class AppFeedbackState {
  /// Creates the state.
  const AppFeedbackState({this.loadingMessage, this.toast});

  /// Loader message; `null` hides the loader.
  final String? loadingMessage;

  /// Visible toast, if any.
  final FeedbackToast? toast;

  /// Whether the blocking loader is visible.
  bool get isLoading => loadingMessage != null;
}
