import 'package:imart_delivery_app/app/config/env.dart';

/// Route paths.
abstract final class AppRoutes {
  /// Splash.
  static const String splash = '/splash';

  /// Login.
  static const String login = '/login';

  /// Trip tab.
  static const String trip = '/trip';

  /// Map tab.
  static const String map = '/map';

  /// Profile tab.
  static const String profile = '/profile';

  /// Edit profile.
  static const String profileEdit = '/profile/edit';

  /// Trip history.
  static const String profileHistory = '/profile/history';

  /// Routes reachable without a session.
  static const Set<String> public = <String>{splash, login};

  /// Initial route for a design-preview start screen.
  static String initialFor(PreviewScreen screen) => switch (screen) {
    PreviewScreen.splash => splash,
    PreviewScreen.login => login,
    PreviewScreen.navigation => map,
    PreviewScreen.profile => profile,
    PreviewScreen.loading ||
    PreviewScreen.trip ||
    PreviewScreen.route ||
    PreviewScreen.empty ||
    PreviewScreen.error => trip,
  };
}
