/// Runtime environment, resolved from `--dart-define` values.
library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Start screens mirroring the design prototype's "Start Screen" tweak.
///
/// Used for design QA / pixel comparison and demos only; ignored in release
/// builds.
enum PreviewScreen {
  /// Normal cold start.
  splash,

  /// Login form.
  login,

  /// App with trip still loading.
  loading,

  /// Pickup phase.
  trip,

  /// Arrange-route phase with every order picked.
  route,

  /// Navigating to the first stop.
  navigation,

  /// Profile tab.
  profile,

  /// No trip assigned.
  empty,

  /// Trip failed to load.
  error,
}

/// Current environment.
class Env {
  const Env._({
    required this.apiBaseUrl,
    required this.useStaticData,
    required this.previewScreen,
    required this.previewNow,
  });

  static const String _previewKey = 'PREVIEW_SCREEN';
  static const String _nowKey = 'PREVIEW_NOW';
  static const String _apiKey = 'API_BASE_URL';
  static const String _staticKey = 'USE_STATIC_DATA';

  /// iMart API used when no `API_BASE_URL` is passed.
  static const String _defaultApiBaseUrl = 'https://imartapp.store';

  static const String _resolvedApiBaseUrl = String.fromEnvironment(
    _apiKey,
    defaultValue: _defaultApiBaseUrl,
  );

  /// Environment resolved once at startup.
  static final Env current = Env._(
    apiBaseUrl: _resolvedApiBaseUrl,
    useStaticData: const bool.hasEnvironment(_staticKey)
        ? const bool.fromEnvironment(_staticKey)
        : _resolvedApiBaseUrl.isEmpty || _isFlutterTest,
    previewScreen: _parsePreview(_define(_previewKey, _previewQuery)),
    previewNow: DateTime.tryParse(_define(_nowKey, _nowQuery)),
  );

  /// `flutter test` sets this variable; tests never call the real server.
  static const String _flutterTestVariable = 'FLUTTER_TEST';

  static bool get _isFlutterTest =>
      !kIsWeb && Platform.environment.containsKey(_flutterTestVariable);

  static const String _previewQuery = 'preview';
  static const String _nowQuery = 'now';

  /// Backend base URL. Defaults to `https://imartapp.store`; override with
  /// `--dart-define=API_BASE_URL=...` (an Android emulator reaches a dev
  /// server on the host at `http://10.0.2.2:8010`).
  final String apiBaseUrl;

  /// Serve static fixtures instead of calling the API. Defaults to `false`
  /// (the API is used), and `true` under `flutter test`; pass
  /// `USE_STATIC_DATA=true|false` to override.
  final bool useStaticData;

  /// Design-preview start screen.
  final PreviewScreen previewScreen;

  /// Pinned clock for previews.
  final DateTime? previewNow;

  /// Compile-time define, falling back (debug/profile web builds only) to a
  /// URL query parameter so design QA can open any state without rebuilding.
  static String _define(String key, String query) {
    final String value = switch (key) {
      _previewKey => const String.fromEnvironment(_previewKey),
      _ => const String.fromEnvironment(_nowKey),
    };
    if (value.isNotEmpty || kReleaseMode || !kIsWeb) {
      return value;
    }
    return Uri.base.queryParameters[query] ?? '';
  }

  static PreviewScreen _parsePreview(String raw) {
    for (final PreviewScreen screen in PreviewScreen.values) {
      if (screen.name == raw) {
        return screen;
      }
    }
    return PreviewScreen.splash;
  }
}
