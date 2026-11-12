import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/theme.dart';

/// Sticky white bar that holds a screen's single primary action, pinned
/// directly above the bottom navigation.
class AppActionBar extends StatelessWidget {
  /// Creates an action bar.
  const AppActionBar({super.key, required this.child});

  /// The action (usually a full-width [AppButton]).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: const Border(top: BorderSide(color: AppColors.line)),
        boxShadow: AppShadows.actionBar,
      ),
      child: child,
    );
  }
}
