/// Runtime environment, resolved from `--dart-define` values.
library;

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

  /// Environment resolved once at startup.
  static final Env current = Env._(
    apiBaseUrl: const String.fromEnvironment(_apiKey),
    useStaticData: const bool.fromEnvironment(_staticKey, defaultValue: true),
    previewScreen: _parsePreview(_define(_previewKey, _previewQuery)),
    previewNow: DateTime.tryParse(_define(_nowKey, _nowQuery)),
  );

  static const String _previewQuery = 'preview';
  static const String _nowQuery = 'now';

  /// Backend base URL (empty until the API layer lands).
  final String apiBaseUrl;

  /// Serve static fixtures instead of calling the API.
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
