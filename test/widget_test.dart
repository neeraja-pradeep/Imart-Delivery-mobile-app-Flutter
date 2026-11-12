import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:imart_delivery_app/app/app.dart';

void main() {
  testWidgets('boots to the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ImartApp()));
    await tester.pumpAndSettle();
    expect(find.text('Get Started'), findsOneWidget);
  });
}
