/// Clock and date helpers.
///
/// [AppClock] can be pinned (tests, design previews) so greeting and
/// relative dates render deterministically.
abstract final class AppClock {
  static DateTime? _fixed;

  /// Current time, or the pinned time when set.
  static DateTime now() => _fixed ?? DateTime.now();

  /// Pins the clock; pass `null` to release it.
  static void pin(DateTime? value) => _fixed = value;
}

/// Date formatting helpers used by the UI.
abstract final class AppDateUtils {
  static const int _noon = 12;
  static const int _evening = 17;
  static const List<String> _weekdays = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  static const List<String> _months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// "Good morning," / "Good afternoon," / "Good evening,".
  static String greeting(DateTime now) {
    if (now.hour < _noon) {
      return 'Good morning,';
    }
    if (now.hour < _evening) {
      return 'Good afternoon,';
    }
    return 'Good evening,';
  }

  /// "Yesterday, 22 Jun" when [date] is the day before [now], otherwise
  /// "Fri, 21 Jun".
  static String historyLabel(DateTime date, DateTime now) {
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime day = DateTime(date.year, date.month, date.day);
    final String dayMonth = '${date.day} ${_months[date.month - 1]}';
    if (today.difference(day).inDays == 1) {
      return 'Yesterday, $dayMonth';
    }
    return '${_weekdays[date.weekday - 1]}, $dayMonth';
  }
}
