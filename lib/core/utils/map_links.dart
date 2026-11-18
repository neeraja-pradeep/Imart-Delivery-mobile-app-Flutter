/// Builders for map / dialer deep links.
///
/// The in-app map itself is `TripMapView`; these only hand off to other apps.
abstract final class MapLinks {
  static const String _maps = 'https://www.google.com/maps';

  /// Turn-by-turn directions hand-off to Google Maps.
  static Uri directions(double lat, double lng) =>
      Uri.parse('$_maps/dir/?api=1&destination=$lat,$lng');

  /// Native dialer.
  static Uri dial(String phone) => Uri(scheme: 'tel', path: phone);
}
