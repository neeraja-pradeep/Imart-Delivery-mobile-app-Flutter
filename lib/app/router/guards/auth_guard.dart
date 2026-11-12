import 'package:imart_delivery_app/app/router/app_routes.dart';

/// Keeps signed-out riders on public routes and signed-in riders out of
/// the auth flow. Returns the redirect target, or `null` to stay.
String? authGuard({required bool signedIn, required String location}) {
  final bool isPublic = AppRoutes.public.contains(location);
  if (!signedIn && !isPublic) {
    return AppRoutes.splash;
  }
  if (signedIn && isPublic) {
    return AppRoutes.trip;
  }
  return null;
}
