import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:imart_delivery_app/app/router/app_router.dart';
import 'package:imart_delivery_app/app/theme/theme.dart';
import 'package:imart_delivery_app/core/update/app_update_gate.dart';
import 'package:imart_delivery_app/features/common/feedback/presentation/components/app_feedback_host.dart';

/// Root widget: ScreenUtil scaling, theme, router, feedback host and the
/// Play Store in-app update check.
class ImartApp extends ConsumerWidget {
  /// Creates the app.
  const ImartApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(appRouterProvider);
    return ScreenUtilInit(
      designSize: AppDesign.frame,
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (BuildContext context, Widget? _) {
        return MaterialApp.router(
          title: 'iMart Delivery',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: router,
          builder: (BuildContext context, Widget? child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.noScaling),
              child: AppFeedbackHost(
                child: AppUpdateGate(
                  navigatorKey: router.routerDelegate.navigatorKey,
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
