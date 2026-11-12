/// Summary of one past trip day.
class TripHistoryEntry {
  /// Creates an entry.
  const TripHistoryEntry({
    required this.date,
    required this.stops,
    required this.failed,
    required this.distanceKm,
    required this.earned,
  });

  /// Trip date.
  final DateTime date;

  /// Stops on the trip.
  final int stops;

  /// Failed stops.
  final int failed;

  /// Distance covered.
  final double distanceKm;

  /// Payout in rupees.
  final int earned;

  /// Successful deliveries.
  int get delivered => stops - failed;
}
