/// Builders for map / dialer deep links.
abstract final class MapLinks {
  static const String _maps = 'https://www.google.com/maps';
  static const int _stopZoom = 15;
  static const int _overviewZoom = 12;

  /// Embedded map centred on a point.
  // TODO(api-team): switch to the Maps Embed API with a restricted key once
  // the Google Maps credentials are provisioned. 2026-11-12
  static String embed(double lat, double lng, {int zoom = _stopZoom}) =>
      '$_maps?q=$lat,$lng&z=$zoom&output=embed';

  /// Route-overview embed.
  static String overview(double lat, double lng) =>
      embed(lat, lng, zoom: _overviewZoom);

  /// Turn-by-turn directions hand-off to Google Maps.
  static Uri directions(double lat, double lng) =>
      Uri.parse('$_maps/dir/?api=1&destination=$lat,$lng');

  /// Native dialer.
  static Uri dial(String phone) => Uri(scheme: 'tel', path: phone);
}
