import 'package:imart_delivery_app/core/network/api_client.dart';
import 'package:imart_delivery_app/features/profile/domain/entities/rider_profile.dart';
import 'package:imart_delivery_app/features/profile/domain/entities/trip_history_entry.dart';

/// Vehicle parsed from the profile's single free-text "Vehicle" field.
class VehicleInput {
  /// Creates the parsed vehicle.
  const VehicleInput({required this.number, this.type});

  /// API `vehicle_type` code, or `null` to keep the current one.
  final String? type;

  /// API `vehicle_number`.
  final String number;
}

/// Maps backend JSON to profile entities and back.
abstract final class ProfileMapper {
  /// Separator between vehicle type and number in the "Vehicle" field.
  static const String vehicleSeparator = ' · ';

  static const Map<String, String> _vehicleLabels = <String, String>{
    'bike': 'Bike',
    'scooter': 'Scooter',
    'electric_bike': 'E-Bike',
    'electric_scooter': 'E-Scooter',
    'cycle': 'Cycle',
  };

  /// Builds the profile from `GET /auth/v1/profile/`, `GET
  /// /delivery-profiles/me/` and the hub name taken from a delivery's
  /// pickup point.
  static RiderProfile toProfile({
    required JsonMap account,
    required JsonMap deliveryProfile,
    required String hubName,
  }) {
    final String name = <String>[
      _string(account['first_name']),
      _string(account['last_name']),
    ].where((String part) => part.isNotEmpty).join(' ');
    return RiderProfile(
      name: name.isEmpty ? _string(account['username']) : name,
      phone: _string(account['phone_number']),
      email: _string(account['email']),
      vehicle: formatVehicle(
        _string(deliveryProfile['vehicle_type']),
        _string(deliveryProfile['vehicle_number']),
      ),
      hubName: hubName,
      avatarUrl: _photoUrl(account['profile_photo']),
    );
  }

  /// `bike` + `KL07AB1234` → `Bike · KL07AB1234`.
  static String formatVehicle(String type, String number) {
    final String label = _vehicleLabels[type] ?? '';
    return <String>[
      label,
      number,
    ].where((String part) => part.isNotEmpty).join(vehicleSeparator);
  }

  /// Parses the free-text "Vehicle" field. `Bike · KL07AB1234` sets both
  /// type and number; anything else is taken as the number only.
  static VehicleInput parseVehicle(String text) {
    final String trimmed = text.trim();
    final int split = trimmed.indexOf(vehicleSeparator.trim());
    if (split > 0) {
      final String label = trimmed.substring(0, split).trim().toLowerCase();
      final String number = trimmed.substring(split + 1).trim();
      for (final MapEntry<String, String> entry in _vehicleLabels.entries) {
        if (entry.value.toLowerCase() == label) {
          return VehicleInput(type: entry.key, number: number);
        }
      }
    }
    return VehicleInput(number: trimmed);
  }

  /// `PATCH /auth/v1/profile/` body for a full [name] and [email].
  static JsonMap toAccountPatch({required String name, required String email}) {
    final List<String> parts = name.trim().split(RegExp(r'\s+'));
    return <String, dynamic>{
      'first_name': parts.first,
      'last_name': parts.skip(1).join(' '),
      'email': email.trim(),
    };
  }

  /// `GET /payouts/v1/me/earnings/summary/` → one entry per day with at
  /// least one delivered or failed stop, newest first.
  static List<TripHistoryEntry> toHistoryFromEarnings(JsonMap summary) {
    final Object? rows = summary['by_day'];
    final List<TripHistoryEntry> entries = <TripHistoryEntry>[
      if (rows is List)
        for (final JsonMap row in rows.whereType<JsonMap>())
          if (DateTime.tryParse(_string(row['date'])) case final DateTime day)
            if (_int(row['delivered']) + _int(row['failed']) > 0)
              TripHistoryEntry(
                date: DateTime(day.year, day.month, day.day),
                stops: _int(row['delivered']) + _int(row['failed']),
                failed: _int(row['failed']),
                distanceKm: _double(row['distance_km']),
                earned: _double(row['earned']).round(),
              ),
    ];
    return entries..sort(
      (TripHistoryEntry a, TripHistoryEntry b) => b.date.compareTo(a.date),
    );
  }

  /// Groups `GET /deliveries/history/` attempts into one entry per day,
  /// newest first, summing each attempt's `distance_km` and `earned`
  /// (0 where the server leaves them out).
  static List<TripHistoryEntry> toHistory(List<JsonMap> attempts) {
    final Map<DateTime, List<JsonMap>> byDay = <DateTime, List<JsonMap>>{};
    for (final JsonMap attempt in attempts) {
      final DateTime? ended = DateTime.tryParse(
        _string(attempt['ended_at']),
      )?.toLocal();
      if (ended == null) {
        continue;
      }
      final DateTime day = DateTime(ended.year, ended.month, ended.day);
      byDay.putIfAbsent(day, () => <JsonMap>[]).add(attempt);
    }
    final List<DateTime> days = byDay.keys.toList()
      ..sort((DateTime a, DateTime b) => b.compareTo(a));
    return <TripHistoryEntry>[
      for (final DateTime day in days)
        TripHistoryEntry(
          date: day,
          stops: byDay[day]!.length,
          failed: byDay[day]!
              .where((JsonMap a) => a['outcome'] == 'failed')
              .length,
          distanceKm: byDay[day]!.fold(
            0,
            (double sum, JsonMap a) => sum + _double(a['distance_km']),
          ),
          earned: byDay[day]!
              .fold(0.0, (double sum, JsonMap a) => sum + _double(a['earned']))
              .round(),
        ),
    ];
  }

  static String? _photoUrl(Object? photo) {
    if (photo is String && photo.isNotEmpty) {
      return photo;
    }
    if (photo is Map<String, dynamic>) {
      final Object? url = photo['url'] ?? photo['original'];
      return url is String && url.isNotEmpty ? url : null;
    }
    return null;
  }

  static String _string(Object? value) => value is String ? value : '';

  static int _int(Object? value) => switch (value) {
    final num n => n.toInt(),
    final String s => int.tryParse(s) ?? 0,
    _ => 0,
  };

  // Money comes as a decimal string ("106.20"), km as a number.
  static double _double(Object? value) => switch (value) {
    final num n => n.toDouble(),
    final String s => double.tryParse(s) ?? 0,
    _ => 0,
  };
}
