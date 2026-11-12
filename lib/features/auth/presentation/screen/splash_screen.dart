import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:imart_delivery_app/app/router/app_routes.dart';
import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/core/widgets/app_logo.dart';
import 'package:imart_delivery_app/core/widgets/app_pattern_background.dart';
import 'package:imart_delivery_app/core/widgets/app_status_bar_style.dart';
import 'package:imart_delivery_app/features/auth/presentation/components/splash_footer_section.dart';

/// Brand splash: green field, vegetable texture, white lockup, CTA.
class SplashScreen extends StatelessWidget {
  /// Creates the splash.
  const SplashScreen({super.key});

  static const double _patternOpacity = 0.16;
  static const double _logoSize = 96;

  @override
  Widget build(BuildContext context) {
    return AppStatusBarStyle(
      dark: false,
      child: Scaffold(
        backgroundColor: AppColors.brand,
        body: Stack(
          children: <Widget>[
            const Positioned.fill(
              child: AppPatternBackground(
                opacity: _patternOpacity,
                screenBlend: true,
              ),
            ),
            const Positioned.fill(
              child: Center(
                child: AppLogo(
                  tone: AppLogoTone.white,
                  size: _logoSize,
                  tagline: true,
                ),
              ),
            ),
            SplashFooterSection(
              onGetStarted: () => context.go(AppRoutes.login),
            ),
          ],
        ),
      ),
    );
  }
}
