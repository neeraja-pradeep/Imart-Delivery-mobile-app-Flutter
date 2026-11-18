import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:imart_delivery_app/app/app.dart';
import 'package:imart_delivery_app/app/config/env.dart';
import 'package:imart_delivery_app/core/error/failure.dart';
import 'package:imart_delivery_app/core/utils/date_utils.dart';
import 'package:imart_delivery_app/core/utils/logger.dart';

/// Starts the app inside a [ProviderScope] with global error hooks.
abstract final class AppBootstrap {
  /// Boots the app.
  static void run() {
    WidgetsFlutterBinding.ensureInitialized();
    if (!kReleaseMode) {
      AppClock.pin(Env.current.previewNow);
    }
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      AppLogger.log(
        'Flutter error',
        error: details.exception,
        stackTrace: details.stack,
      );
    };
    // Failed actions (e.g. a rejected status update) already show a toast;
    // log them here instead of letting them surface as uncaught errors.
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      AppLogger.log('Uncaught error', error: error, stackTrace: stack);
      return error is Failure;
    };
    runApp(const ProviderScope(child: ImartApp()));
  }
}
