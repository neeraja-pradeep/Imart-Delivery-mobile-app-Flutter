/// A selectable reason for a failed delivery.
class FailReason {
  /// Creates a reason.
  const FailReason({
    required this.id,
    required this.label,
    this.requiresNotes = false,
  });

  /// Stable id sent to the server.
  final String id;

  /// Display label.
  final String label;

  /// Whether the server needs a note with this reason (`other`).
  final bool requiresNotes;
}
