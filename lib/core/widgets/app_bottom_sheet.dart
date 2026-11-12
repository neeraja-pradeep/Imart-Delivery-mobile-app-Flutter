import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/theme.dart';

/// Modal bottom sheet over a dimmed, lightly blurred backdrop.
///
/// Matches the design's confirm / fail sheets: rounded 26px top corners,
/// upward sheet shadow, tap-outside-to-dismiss.
abstract final class AppBottomSheet {
  static const double _blurSigma = 2;
  static const double _maxHeightFactor = 0.9;

  /// Presents [builder]'s content as a sheet and resolves with its result.
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    EdgeInsets padding = const EdgeInsets.fromLTRB(22, 26, 22, 28),
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: AppDurations.base,
      pageBuilder: (BuildContext dialogContext, _, _) {
        // Intercept pointers so web platform views (map iframe) underneath
        // never steal taps from the sheet.
        return PointerInterceptor(
          child: _SheetFrame(padding: padding, child: builder(dialogContext)),
        );
      },
      transitionBuilder: (_, Animation<double> animation, _, Widget child) {
        final Animation<double> curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(opacity: curved, child: child);
      },
    );
  }

  /// Max sheet height as a fraction of the screen.
  static double get maxHeightFactor => _maxHeightFactor;

  /// Backdrop blur sigma.
  static double get blurSigma => _blurSigma;
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.padding, required this.child});

  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(
                sigmaX: AppBottomSheet.blurSigma,
                sigmaY: AppBottomSheet.blurSigma,
              ),
              child: const ColoredBox(color: AppColors.sheetScrim),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: AppBottomSheet.maxHeightFactor.sh,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppRadii.sheet.r),
                  ),
                  boxShadow: AppShadows.sheet,
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    padding.left.w,
                    padding.top.h,
                    padding.right.w,
                    padding.bottom.h + bottomInset,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
