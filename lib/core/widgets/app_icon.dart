import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Every glyph used by the iMart Delivery design.
///
/// The SVG bodies are copied verbatim from the design file (24 × 24 grid,
/// round caps/joins) so strokes render identically to the prototype.
enum AppIconGlyph {
  /// Back arrow.
  arrowLeft('<path d="M19 12H5m6-7-7 7 7 7"/>'),

  /// Shopping bag — pickup, history, empty state.
  bag(
    '<path d="M5 8h14l-1 12a1 1 0 0 1-1 1H7a1 1 0 0 1-1-1L5 8Z"/>'
    '<path d="M9 8V6a3 3 0 0 1 6 0v2"/>',
  ),

  /// Filled map pin (distance meta).
  pinFilled(
    '<path d="M12 2a7 7 0 0 0-7 7c0 5 7 13 7 13s7-8 7-13a7 7 0 0 0-7-7Zm0 '
    '9.5A2.5 2.5 0 1 1 12 6.5a2.5 2.5 0 0 1 0 5Z"/>',
    filled: true,
  ),

  /// Outline map pin — "I've Arrived".
  pin(
    '<path d="M12 2a7 7 0 0 0-7 7c0 5 7 13 7 13s7-8 7-13a7 7 0 0 0-7-7Z"/>'
    '<circle cx="12" cy="9" r="2.5"/>',
  ),

  /// Caret up.
  caretUp('<path d="m6 15 6-6 6 6"/>'),

  /// Caret down.
  caretDown('<path d="m6 9 6 6 6-6"/>'),

  /// Payment card.
  card('<rect x="2" y="6" width="20" height="13" rx="2"/><path d="M2 10h20"/>'),

  /// Check mark.
  check('<path d="m5 12 5 5L20 6"/>'),

  /// Navigation arrow.
  navigation('<path d="M21 3 3 10.5l7 2.5 2.5 7L21 3Z"/>'),

  /// Phone handset.
  phone(
    '<path d="M5 4h3l1.5 5-2 1.5a11 11 0 0 0 5 5l1.5-2 5 1.5V19a2 2 0 0 '
    '1-2 2A16 16 0 0 1 4 6a2 2 0 0 1 1-2Z"/>',
  ),

  /// Envelope.
  mail(
    '<rect x="3" y="5" width="18" height="14" rx="2"/>'
    '<path d="m4 7 8 6 8-6"/>',
  ),

  /// Clock — availability / leave.
  clock('<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>'),

  /// User silhouette.
  user('<circle cx="12" cy="8" r="4"/><path d="M4 21c0-4 3.6-6 8-6s8 2 8 6"/>'),

  /// Sign out.
  signOut(
    '<path d="M14 4h4a1 1 0 0 1 1 1v14a1 1 0 0 1-1 1h-4"/>'
    '<path d="M9 8l-4 4 4 4M5 12h10"/>',
  ),

  /// Home — "Trip" nav tab.
  home(
    '<path d="M3 10.5 12 3l9 7.5M5 9.5V20a1 1 0 0 0 1 1h12a1 1 0 0 0 '
    '1-1V9.5"/>',
  ),

  /// Alert circle — inline field error.
  alertCircle('<circle cx="12" cy="12" r="9"/><path d="M12 8v5M12 16.5v.5"/>'),

  /// Sort lines — "Optimize by Distance".
  sort('<path d="M3 6h18M7 12h10M11 18h2"/>'),

  /// Eye with slash — "Connection Lost".
  connectionLost(
    '<path d="M1 1l22 22M16.7 16.7A11 11 0 0 1 12 18c-6.5 0-10-6-10-6a18 18 '
    '0 0 1 4-4.5m3-1.7A11 11 0 0 1 12 5c6.5 0 10 6 10 6a18 18 0 0 1-2.3 3"/>',
  ),

  /// Wifi off — offline banner.
  wifiOff(
    '<path d="M1 1l22 22M16.7 16.7A11 11 0 0 1 12 18M5 12.5a9 9 0 0 1 '
    '4-2.3M8.5 8.6A14 14 0 0 1 21 11"/>',
  );

  const AppIconGlyph(this.body, {this.filled = false});

  /// Inner SVG markup.
  final String body;

  /// Whether the glyph is a filled shape rather than a stroke.
  final bool filled;
}

/// Renders an [AppIconGlyph] at [size] design px in [color].
class AppIcon extends StatelessWidget {
  /// Creates an icon.
  const AppIcon(
    this.glyph, {
    super.key,
    this.size = 24,
    this.color = const Color(0xFF171717),
    this.strokeWidth = 2,
  });

  /// Glyph to draw.
  final AppIconGlyph glyph;

  /// Square size in design px.
  final double size;

  /// Stroke (or fill) colour.
  final Color color;

  /// Stroke width on the 24px grid.
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final String paint = glyph.filled
        ? 'fill="currentColor" stroke="none"'
        : 'fill="none" stroke="currentColor" stroke-width="$strokeWidth" '
              'stroke-linecap="round" stroke-linejoin="round"';
    final String svg =
        '<svg xmlns="http://www.w3.org/2000/svg" '
        'viewBox="0 0 24 24" $paint>${glyph.body}</svg>';
    return SvgPicture.string(
      svg,
      width: size.r,
      height: size.r,
      theme: SvgTheme(currentColor: color),
    );
  }
}
