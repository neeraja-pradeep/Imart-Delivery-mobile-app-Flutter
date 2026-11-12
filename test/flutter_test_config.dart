import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// Loads the bundled brand fonts so widget tests lay text out with real
/// metrics instead of the square "Ahem" test font.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  const Map<String, List<String>> families = <String, List<String>>{
    'ImartPoppins': <String>[
      'Poppins-Regular.ttf',
      'Poppins-Medium.ttf',
      'Poppins-SemiBold.ttf',
      'Poppins-Bold.ttf',
    ],
    'ImartRoboto': <String>[
      'Roboto-Regular.ttf',
      'Roboto-Medium.ttf',
      'Roboto-Bold.ttf',
    ],
    'ImartSora': <String>['Sora-Regular.ttf', 'Sora-SemiBold.ttf'],
  };
  for (final MapEntry<String, List<String>> family in families.entries) {
    final FontLoader loader = FontLoader(family.key);
    for (final String file in family.value) {
      loader.addFont(
        Future<ByteData>.value(
          ByteData.sublistView(File('assets/fonts/$file').readAsBytesSync()),
        ),
      );
    }
    await loader.load();
  }
  await testMain();
}
