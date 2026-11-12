import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/typography.dart';

/// Design frame the whole UI is laid out against (iPhone 14 / 390 × 844).
abstract final class AppDesign {
  /// Design frame size used by `ScreenUtilInit`.
  static const Size frame = Size(390, 844);
}

/// Corner radii (design px — scale with `.r`).
abstract final class AppRadii {
  /// Fields, reorder buttons.
  static const double sm = 8;

  /// Secondary button, pay chips, stat tiles.
  static const double md = 10;

  /// Inset lists, fail-reason rows, cash checkbox, arrange tiles.
  static const double lg = 12;

  /// Stop cards, profile cards.
  static const double card = 14;

  /// Summary card, pickup banner.
  static const double xl = 16;

  /// Complete stats card.
  static const double xxl = 18;

  /// Map bottom sheet.
  static const double sheetMap = 22;

  /// Confirm / fail bottom sheets.
  static const double sheet = 26;

  /// Brand header curve.
  static const double header = 28;

  /// Profile header curve.
  static const double profileHeader = 60;

  /// Pills: buttons, badges, toasts.
  static const double pill = 100;
}

/// Shared fixed sizes from the design (design px).
abstract final class AppSizes {
  /// Minimum hit target.
  static const double tapMin = 44;

  /// Bottom navigation bar height (without device inset).
  static const double navBar = 62;

  /// Height reserved by the fake status bar in the design frame.
  static const double statusBar = 44;

  /// Large primary button height.
  static const double buttonLg = 54;

  /// Medium primary button height.
  static const double buttonMd = 48;

  /// Header content top padding (status bar + 8).
  static const double headerTop = 52;

  /// Converts a design-frame `top` (measured from the frame's top edge,
  /// which includes the 44px status bar) to a device offset that respects
  /// taller status bars / notches.
  static double topInset(BuildContext context, double designTop) {
    final double status = MediaQuery.paddingOf(context).top;
    final double designStatus = statusBar.h;
    final double base = status > designStatus ? status : designStatus;
    return base + (designTop - statusBar).h;
  }
}

/// Elevation tokens from `tokens/spacing.css` and the delivery design.
abstract final class AppShadows {
  /// `--shadow-card`: 0 2 12 rgba(0,0,0,.08).
  static List<BoxShadow> get card => <BoxShadow>[
    BoxShadow(
      color: const Color(0x14000000),
      offset: Offset(0, 2.r),
      blurRadius: 12.r,
    ),
  ];

  /// `--shadow-sm`: 0 2 8 rgba(0,0,0,.08).
  static List<BoxShadow> get sm => <BoxShadow>[
    BoxShadow(
      color: const Color(0x14000000),
      offset: Offset(0, 2.r),
      blurRadius: 8.r,
    ),
  ];

  /// `--shadow-md`: 0 4 16 rgba(0,0,0,.10).
  static List<BoxShadow> get md => <BoxShadow>[
    BoxShadow(
      color: const Color(0x1A000000),
      offset: Offset(0, 4.r),
      blurRadius: 16.r,
    ),
  ];

  /// `--shadow-xs`: 0 1 2 rgba(0,0,0,.06).
  static List<BoxShadow> get xs => <BoxShadow>[
    BoxShadow(
      color: const Color(0x0F000000),
      offset: Offset(0, 1.r),
      blurRadius: 2.r,
    ),
  ];

  /// `--shadow-sheet`: 0 -6 24 rgba(0,0,0,.16).
  static List<BoxShadow> get sheet => <BoxShadow>[
    BoxShadow(
      color: const Color(0x29000000),
      offset: Offset(0, -6.r),
      blurRadius: 24.r,
    ),
  ];

  /// Sticky action bar: 0 -4 16 rgba(0,0,0,.06).
  static List<BoxShadow> get actionBar => <BoxShadow>[
    BoxShadow(
      color: const Color(0x0F000000),
      offset: Offset(0, -4.r),
      blurRadius: 16.r,
    ),
  ];

  /// Bottom nav: 0 -2 12 rgba(0,0,0,.06).
  static List<BoxShadow> get navBar => <BoxShadow>[
    BoxShadow(
      color: const Color(0x0F000000),
      offset: Offset(0, -2.r),
      blurRadius: 12.r,
    ),
  ];

  /// Toast: 0 6 20 rgba(0,0,0,.18).
  static List<BoxShadow> get toast => <BoxShadow>[
    BoxShadow(
      color: const Color(0x2E000000),
      offset: Offset(0, 6.r),
      blurRadius: 20.r,
    ),
  ];

  /// Celebration badge: 0 8 24 rgba(0,0,0,.25).
  static List<BoxShadow> get celebrate => <BoxShadow>[
    BoxShadow(
      color: const Color(0x40000000),
      offset: Offset(0, 8.r),
      blurRadius: 24.r,
    ),
  ];
}

/// Motion tokens.
abstract final class AppDurations {
  /// Fast press / toggle.
  static const Duration fast = Duration(milliseconds: 150);

  /// Standard transition (card border, progress bar).
  static const Duration base = Duration(milliseconds: 200);

  /// Progress bar width animation.
  static const Duration progress = Duration(milliseconds: 300);

  /// Spinner revolution.
  static const Duration spin = Duration(milliseconds: 800);
}

/// Assembles the app-wide [ThemeData].
abstract final class AppTheme {
  /// Light theme — the design ships light only.
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTypography.fontBody,
      scaffoldBackgroundColor: AppColors.surfacePage,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brand,
        primary: AppColors.action,
        secondary: AppColors.brand,
        error: AppColors.coral,
        surface: AppColors.surfacePage,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.action,
      ),
    );
  }
}
