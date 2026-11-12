import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Sets the OS status-bar icon colour for the wrapped screen.
///
/// The design draws dark status icons on light screens (login, empty /
/// error states) and white icons on brand-green screens.
class AppStatusBarStyle extends StatelessWidget {
  /// Creates the wrapper.
  const AppStatusBarStyle({super.key, required this.dark, required this.child});

  /// Dark icons (for light backgrounds) when true.
  final bool dark;

  /// Screen content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final SystemUiOverlayStyle base = dark
        ? SystemUiOverlayStyle.dark
        : SystemUiOverlayStyle.light;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: base.copyWith(statusBarColor: Colors.transparent),
      child: child,
    );
  }
}
