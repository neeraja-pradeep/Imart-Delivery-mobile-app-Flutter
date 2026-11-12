import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:imart_delivery_app/app/theme/colors.dart';

/// iMart type system.
///
/// Families are registered under `Imart*` names so Flutter web's built-in
/// Roboto fallback can never shadow the bundled faces.
///
/// Poppins carries brand/headings/buttons, Roboto carries body copy and
/// meta, Sora is reserved for the marketing tagline — exactly as defined in
/// `tokens/typography.css`. Sizes are design pixels and are scaled with
/// `.sp` so text tracks the 390-wide design frame.
abstract final class AppTypography {
  /// Display / heading family.
  static const String fontDisplay = 'ImartPoppins';

  /// Body / UI family.
  static const String fontBody = 'ImartRoboto';

  /// Marketing accent family.
  static const String fontAccent = 'ImartSora';

  // CSS `line-height: normal` for each face ((ascent + descent + lineGap) /
  // unitsPerEm). Set explicitly so Material's inherited `height: 1.43` and
  // `letterSpacing: 0.25` never leak into the design's text.
  static const double _displayNormal = 1.5;
  static const double _bodyNormal = 2400 / 2048;
  static const double _accentNormal = 1.26;

  static TextStyle _style({
    required String family,
    required double size,
    required FontWeight weight,
    required Color color,
    required double height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: family,
      fontSize: size.sp,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing ?? 0,
      leadingDistribution: TextLeadingDistribution.even,
      decoration: TextDecoration.none,
    );
  }

  /// Poppins text style at [size] design px.
  static TextStyle display(
    double size, {
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.textPrimary,
    double? height,
    double? letterSpacing,
  }) {
    return _style(
      family: fontDisplay,
      size: size,
      weight: weight,
      color: color,
      height: height ?? _displayNormal,
      letterSpacing: letterSpacing,
    );
  }

  /// Roboto text style at [size] design px.
  static TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.textPrimary,
    double? height,
    double? letterSpacing,
  }) {
    return _style(
      family: fontBody,
      size: size,
      weight: weight,
      color: color,
      height: height ?? _bodyNormal,
      letterSpacing: letterSpacing,
    );
  }

  /// Sora text style at [size] design px.
  static TextStyle accent(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.textPrimary,
    double? height,
  }) {
    return _style(
      family: fontAccent,
      size: size,
      weight: weight,
      color: color,
      height: height ?? _accentNormal,
    );
  }

  /// Small upper-case section caption ("ORDER CONTENTS · #IM-4821").
  static TextStyle caption() {
    return body(
      11,
      weight: FontWeight.w600,
      color: AppColors.textMuted,
      letterSpacing: 0.44,
    );
  }
}
