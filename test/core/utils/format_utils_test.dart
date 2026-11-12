import 'package:flutter_test/flutter_test.dart';

import 'package:imart_delivery_app/core/utils/date_utils.dart';
import 'package:imart_delivery_app/core/utils/format_utils.dart';

void main() {
  group('FormatUtils', () {
    test('rupees use Indian grouping', () {
      expect(FormatUtils.rupees(845), '₹845');
      expect(FormatUtils.rupees(1290), '₹1,290');
      expect(FormatUtils.rupees(125000), '₹1,25,000');
    });

    test('stop distances match the design strings', () {
      expect(FormatUtils.stopKm(2.4), '2.4 km');
      expect(FormatUtils.stopKm(6), '6.0 km');
      expect(FormatUtils.stopKm(11), '11 km');
    });

    test('aggregate distances drop a trailing .0', () {
      expect(FormatUtils.km(23.5), '23.5 km');
      expect(FormatUtils.km(55), '55 km');
      expect(FormatUtils.km(6.5), '6.5 km');
    });

    test('compact duration', () {
      expect(FormatUtils.compactDuration(72), '1h 12m');
      expect(FormatUtils.compactDuration(41), '41m');
      expect(FormatUtils.compactDuration(60), '1h 0m');
    });
  });

  group('AppDateUtils', () {
    test('greeting by hour', () {
      expect(AppDateUtils.greeting(DateTime(2024, 6, 23, 9)), 'Good morning,');
      expect(
        AppDateUtils.greeting(DateTime(2024, 6, 23, 13)),
        'Good afternoon,',
      );
      expect(AppDateUtils.greeting(DateTime(2024, 6, 23, 19)), 'Good evening,');
    });

    test('history labels', () {
      final DateTime now = DateTime(2024, 6, 23, 9, 41);
      expect(
        AppDateUtils.historyLabel(DateTime(2024, 6, 22), now),
        'Yesterday, 22 Jun',
      );
      expect(
        AppDateUtils.historyLabel(DateTime(2024, 6, 21), now),
        'Fri, 21 Jun',
      );
    });
  });
}
