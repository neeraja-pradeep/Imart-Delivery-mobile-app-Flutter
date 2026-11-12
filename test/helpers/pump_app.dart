import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:imart_delivery_app/app/theme/theme.dart';

/// Pumps [child] inside the app's ScreenUtil + theme shell at the design
/// frame size.
Future<void> pumpInApp(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const <Override>[],
}) async {
  tester.view
    ..physicalSize = AppDesign.frame
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: ScreenUtilInit(
        designSize: AppDesign.frame,
        builder: (_, _) => MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: child),
        ),
      ),
    ),
  );
}
