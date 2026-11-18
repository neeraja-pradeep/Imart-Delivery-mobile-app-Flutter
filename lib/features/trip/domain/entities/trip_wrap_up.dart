/// Server figures for the Trip Complete screen. A `null` field means the
/// server didn't provide it, and the app uses its own estimate instead.
class TripWrapUp {
  /// Creates the wrap-up.
  const TripWrapUp({this.distanceKm, this.cashToDeposit});

  /// Nothing from the server.
  static const TripWrapUp none = TripWrapUp();

  /// Distance of the finished trip (`total_km`, sum of its legs).
  final double? distanceKm;

  /// COD cash the rider holds and must hand over, across all trips
  /// (`cash_in_hand`), in rupees.
  final int? cashToDeposit;
}
