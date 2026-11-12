/// Operational (non-monetary) KPIs for the profile's "Last 7 days" row.
class RecentStatsState {
  /// Creates the stats.
  const RecentStatsState({
    required this.delivered,
    required this.distanceKm,
    required this.trips,
  });

  /// Successful deliveries.
  final int delivered;

  /// Distance covered.
  final double distanceKm;

  /// Trips completed.
  final int trips;
}
