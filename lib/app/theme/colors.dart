import 'package:flutter/material.dart';

/// iMart brand palette.
///
/// Mirrors `tokens/colors.css` from the iMart design system plus the
/// one-off tints used by the Delivery app design (payment chips, toasts,
/// status badges). Widgets must reference these tokens, never raw hexes.
abstract final class AppColors {
  // ---- Core greens ----
  /// Deepest green — splash "Get Started" button.
  static const Color green900 = Color(0xFF0A3F27);

  /// Deep green — badge text, prepaid chip text.
  static const Color green800 = Color(0xFF0B6139);

  /// Brand green — headers, logo, app chrome.
  static const Color green700 = Color(0xFF165016);

  /// Secondary action / success surface.
  static const Color green600 = Color(0xFF1F9D60);

  /// Primary action green — every primary tap target.
  static const Color green500 = Color(0xFF25A63E);

  /// Soft green fill / picked-card border.
  static const Color green200 = Color(0xFFB9EECC);

  /// Tint surface.
  static const Color green100 = Color(0xFFE4FAEB);

  // ---- Accents ----
  /// Warm coral — contact icons, alerts, failures.
  static const Color coral = Color(0xFFFF595C);

  /// Amber — leave, celebration, COD.
  static const Color amber = Color(0xFFFE8C00);

  /// Link blue — "Resend OTP", "Edit number".
  static const Color link = Color(0xFF008CFF);

  // ---- Neutrals ----
  /// Pure white.
  static const Color white = Color(0xFFFFFFFF);

  /// Primary text.
  static const Color ink900 = Color(0xFF171717);

  /// Headings on light / muted toast.
  static const Color ink800 = Color(0xFF333333);

  /// Secondary text.
  static const Color ink600 = Color(0xFF575757);

  /// Tertiary / muted text.
  static const Color ink500 = Color(0xFF7C7C7C);

  /// Muted labels, chevrons, disabled text.
  static const Color ink400 = Color(0xFF979797);

  /// Hairline borders.
  static const Color line = Color(0xFFEDEDED);

  /// Field grey / disabled button fill.
  static const Color field = Color(0xFFCACACA);

  /// Inset / muted surface.
  static const Color surface2 = Color(0xFFF3F3F3);

  // ---- Semantic aliases ----
  /// Brand chrome colour.
  static const Color brand = green700;

  /// Deep brand colour.
  static const Color brandDeep = green900;

  /// Primary action colour.
  static const Color action = green500;

  /// Primary text colour.
  static const Color textPrimary = ink900;

  /// Secondary text colour.
  static const Color textSecondary = ink600;

  /// Muted text colour.
  static const Color textMuted = ink500;

  /// Link text colour.
  static const Color textLink = link;

  /// Page background.
  static const Color surfacePage = white;

  /// Inset surface (progress track, item list box).
  static const Color surfaceInset = surface2;

  /// Green tint surface.
  static const Color surfaceTint = green100;

  /// Hairline border colour.
  static const Color borderHairline = line;

  /// Field border colour.
  static const Color borderField = field;

  // ---- Delivery-app specific tints ----
  /// Amber tint — COD chip, leave icon, failed-return note.
  static const Color amberTint = Color(0xFFFFF7D3);

  /// Text on amber tint.
  static const Color amberOnTint = Color(0xFF9A6A00);

  /// "On Duty" live dot.
  static const Color onlineDot = Color(0xFF5FE08A);

  /// Map loading background.
  static const Color mapBackground = Color(0xFFE9EEF0);

  /// Bottom-sheet scrim (rgba(10,40,20,.55)).
  static const Color sheetScrim = Color(0x8C0A2814);

  /// Loading overlay (rgba(255,255,255,.96)).
  static const Color loadingScrim = Color(0xF5FFFFFF);

  /// Selected fail reason tint (coral @ 8%).
  static const Color coralTint8 = Color(0x14FF595C);

  /// Unchecked cash-confirm tint (coral @ 7%).
  static const Color coralTint7 = Color(0x12FF595C);

  /// Error icon circle (coral @ 12%).
  static const Color coralTint12 = Color(0x1FFF595C);

  /// Success toast background.
  static const Color toastSuccessBg = Color(0xFF0C3B22);

  /// Success toast foreground.
  static const Color toastSuccessFg = Color(0xFF7FF0A8);

  /// Warning toast background.
  static const Color toastWarningBg = Color(0xFF3A2C00);

  /// Warning toast foreground.
  static const Color toastWarningFg = Color(0xFFFFD54A);

  // ---- White overlays on brand green ----
  /// White @ 92%.
  static const Color white92 = Color(0xEBFFFFFF);

  /// White @ 85%.
  static const Color white85 = Color(0xD9FFFFFF);

  /// White @ 80%.
  static const Color white80 = Color(0xCCFFFFFF);

  /// White @ 78%.
  static const Color white78 = Color(0xC7FFFFFF);

  /// White @ 72%.
  static const Color white72 = Color(0xB8FFFFFF);

  /// White @ 16%.
  static const Color white16 = Color(0x29FFFFFF);

  // ---- Badge tones (design-system Badge TONES) ----
  /// Violet badge foreground.
  static const Color violetFg = Color(0xFF4A4AD8);

  /// Violet badge tint.
  static const Color violetTint = Color(0xFFECECFF);

  /// Blue badge foreground.
  static const Color blueFg = Color(0xFF007BE0);

  /// Blue badge tint.
  static const Color blueTint = Color(0xFFE6F4FF);

  /// Amber badge foreground.
  static const Color amberFg = Color(0xFFDB7706);

  /// Red badge foreground.
  static const Color redFg = Color(0xFFCC2929);

  /// Red badge tint.
  static const Color redTint = Color(0xFFFFE7E7);
}
