/// How the customer pays for an order.
enum PaymentMode {
  /// Paid online — nothing to collect.
  prepaid,

  /// Cash on delivery — rider collects cash.
  cod,
}

/// Display helpers for [PaymentMode].
extension PaymentModeX on PaymentMode {
  /// Short badge label.
  String get label => switch (this) {
    PaymentMode.prepaid => 'Prepaid',
    PaymentMode.cod => 'COD',
  };
}
