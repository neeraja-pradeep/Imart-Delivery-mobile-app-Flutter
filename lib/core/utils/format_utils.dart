/// Display formatters shared across features (currency, distance, time).
abstract final class FormatUtils {
  static const String _rupee = '₹';
  static const int _minutesPerHour = 60;
  static const int _lakhGroup = 2;
  static const int _thousandGroup = 3;

  /// Indian-grouped rupee amount, e.g. `1290` → `₹1,290`, `125000` →
  /// `₹1,25,000`.
  static String rupees(int amount) => '$_rupee${_indianGroup(amount)}';

  static const double _wholeKmFrom = 10;

  /// Aggregate distance with at most one decimal, e.g. `23.5 km`, `55 km`.
  static String km(double value) => '${_trimDecimal(value)} km';

  /// Distance to a single stop: one decimal below 10 km (`6.0 km`,
  /// `2.4 km`), whole kilometres from 10 km (`11 km`).
  static String stopKm(double value) => value < _wholeKmFrom
      ? '${value.toStringAsFixed(1)} km'
      : '${value.round()} km';

  /// Duration as `8 min`.
  static String minutes(int value) => '$value min';

  /// Compact total, e.g. `72` → `1h 12m`, `41` → `41m`.
  static String compactDuration(int totalMinutes) {
    if (totalMinutes >= _minutesPerHour) {
      final int h = totalMinutes ~/ _minutesPerHour;
      final int m = totalMinutes % _minutesPerHour;
      return '${h}h ${m}m';
    }
    return '${totalMinutes}m';
  }

  /// Rounds to one decimal and drops a trailing `.0`.
  static String _trimDecimal(double value) {
    final double rounded = (value * 10).round() / 10;
    if (rounded == rounded.roundToDouble()) {
      return rounded.toInt().toString();
    }
    return rounded.toString();
  }

  static String _indianGroup(int amount) {
    final String digits = amount.abs().toString();
    if (digits.length <= _thousandGroup) {
      return amount < 0 ? '-$digits' : digits;
    }
    final String last = digits.substring(digits.length - _thousandGroup);
    String rest = digits.substring(0, digits.length - _thousandGroup);
    final List<String> groups = <String>[];
    while (rest.length > _lakhGroup) {
      groups.insert(0, rest.substring(rest.length - _lakhGroup));
      rest = rest.substring(0, rest.length - _lakhGroup);
    }
    if (rest.isNotEmpty) {
      groups.insert(0, rest);
    }
    final String grouped = '${groups.join(',')},$last';
    return amount < 0 ? '-$grouped' : grouped;
  }
}
