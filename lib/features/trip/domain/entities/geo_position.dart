/// One GPS fix of the rider.
///
/// [accuracyM], [speedMps] and [heading] are `null` when the phone didn't
/// report them; [recordedAt] is when the phone took the fix.
typedef GeoPosition = ({
  double latitude,
  double longitude,
  double? accuracyM,
  double? speedMps,
  double? heading,
  DateTime? recordedAt,
});
