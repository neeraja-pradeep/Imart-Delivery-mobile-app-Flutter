import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:imart_delivery_app/app/config/env.dart';
import 'package:imart_delivery_app/app/router/app_routes.dart';
import 'package:imart_delivery_app/app/router/guards/auth_guard.dart';
import 'package:imart_delivery_app/features/auth/application/providers/auth_providers.dart';
import 'package:imart_delivery_app/features/auth/presentation/screen/login_screen.dart';
import 'package:imart_delivery_app/features/auth/presentation/screen/splash_screen.dart';
import 'package:imart_delivery_app/features/dashboard/presentation/screen/home_screen.dart';
import 'package:imart_delivery_app/features/profile/presentation/screen/edit_profile_screen.dart';
import 'package:imart_delivery_app/features/profile/presentation/screen/profile_screen.dart';
import 'package:imart_delivery_app/features/profile/presentation/screen/trip_history_screen.dart';
import 'package:imart_delivery_app/features/trip/presentation/screen/map_screen.dart';
import 'package:imart_delivery_app/features/trip/presentation/screen/trip_screen.dart';

/// App router with the auth guard wired to [isAuthenticatedProvider].
final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((Ref ref) {
  final ValueNotifier<bool> signedIn = ValueNotifier<bool>(
    ref.read(isAuthenticatedProvider),
  );
  ref
    ..listen<bool>(
      isAuthenticatedProvider,
      (bool? _, bool next) => signedIn.value = next,
    )
    ..onDispose(signedIn.dispose);

  return GoRouter(
    initialLocation: AppRoutes.initialFor(Env.current.previewScreen),
    refreshListenable: signedIn,
    redirect: (BuildContext context, GoRouterState state) =>
        authGuard(signedIn: signedIn.value, location: state.matchedLocation),
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (_, _) =>
            const NoTransitionPage<void>(child: SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (_, _) =>
            const NoTransitionPage<void>(child: LoginScreen()),
      ),
      ShellRoute(
        builder: (_, GoRouterState state, Widget child) =>
            HomeScreen(location: state.matchedLocation, child: child),
        routes: <RouteBase>[
          GoRoute(
            path: AppRoutes.trip,
            pageBuilder: (_, _) =>
                const NoTransitionPage<void>(child: TripScreen()),
          ),
          GoRoute(
            path: AppRoutes.map,
            pageBuilder: (_, _) =>
                const NoTransitionPage<void>(child: MapScreen()),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (_, _) =>
                const NoTransitionPage<void>(child: ProfileScreen()),
            routes: <RouteBase>[
              GoRoute(
                path: 'edit',
                pageBuilder: (_, _) =>
                    const NoTransitionPage<void>(child: EditProfileScreen()),
              ),
              GoRoute(
                path: 'history',
                pageBuilder: (_, _) =>
                    const NoTransitionPage<void>(child: TripHistoryScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
