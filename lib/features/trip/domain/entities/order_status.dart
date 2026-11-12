/// Lifecycle of a single order inside a trip.
enum OrderStatus {
  /// Packed and assigned to the rider; not yet collected.
  assigned,

  /// Collected at the warehouse; waiting for its turn.
  pickedUp,

  /// The rider is heading to this stop now.
  outForDelivery,

  /// Handed over to the customer.
  delivered,

  /// Could not be delivered; returns to the warehouse.
  failed,
}

/// Display helpers for [OrderStatus].
extension OrderStatusX on OrderStatus {
  /// Human label.
  String get label => switch (this) {
    OrderStatus.assigned => 'Assigned',
    OrderStatus.pickedUp => 'Picked Up',
    OrderStatus.outForDelivery => 'Out for Delivery',
    OrderStatus.delivered => 'Delivered',
    OrderStatus.failed => 'Failed',
  };

  /// Whether the order has reached a final state.
  bool get isTerminal =>
      this == OrderStatus.delivered || this == OrderStatus.failed;
}
