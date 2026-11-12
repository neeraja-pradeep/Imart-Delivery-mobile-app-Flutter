/// A selectable reason for a failed delivery.
class FailReason {
  /// Creates a reason.
  const FailReason({required this.id, required this.label});

  /// Stable id sent to the server.
  final String id;

  /// Display label.
  final String label;
}
