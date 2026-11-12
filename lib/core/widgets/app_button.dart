import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/theme.dart';
import 'package:imart_delivery_app/app/theme/typography.dart';

/// Visual variants of [AppButton], one per button style in the design.
enum AppButtonVariant {
  /// Solid action-green pill (Login, Save, Start, Delivered).
  primary,

  /// Solid deep-green pill (splash "Get Started").
  brand,

  /// Green outline, 10px radius (Call, Navigate).
  secondary,

  /// Green tint fill + green outline pill (Mark Picked Up, Optimize).
  tinted,

  /// Coral outline pill (Failed Delivery).
  dangerOutline,

  /// Solid coral pill (Confirm Failed Delivery).
  danger,

  /// Text-only muted pill (Cancel).
  ghost,
}

/// Size presets taken from the design-system `Button`.
enum AppButtonSize {
  /// 54px tall, 16px label, 15/24 padding.
  lg,

  /// 48px tall, 15px label, 12/22 padding.
  md,
}

/// The iMart action button.
///
/// Covers every button in the design: the design-system variants plus the
/// custom gated buttons (Start Trip, Yes Delivered, Confirm Failed) whose
/// disabled look is a flat grey fill rather than reduced opacity — pass
/// `enabled: false` for that state.
class AppButton extends StatefulWidget {
  /// Creates a button.
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.lg,
    this.leading,
    this.expand = true,
    this.enabled = true,
    this.height,
    this.fontSize,
  });

  /// Button text.
  final String label;

  /// Tap handler. Ignored while [enabled] is false.
  final VoidCallback? onPressed;

  /// Visual style.
  final AppButtonVariant variant;

  /// Size preset.
  final AppButtonSize size;

  /// Optional leading icon.
  final Widget? leading;

  /// Whether the button stretches to the available width.
  final bool expand;

  /// Gated state — renders the flat grey disabled style.
  final bool enabled;

  /// Explicit height override (design px) for custom buttons.
  final double? height;

  /// Explicit label size override (design px).
  final double? fontSize;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  static const double _pressedScale = 0.97;

  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final _ButtonPalette palette = _paletteFor(widget.variant, widget.enabled);
    final bool isLg = widget.size == AppButtonSize.lg;
    final double height =
        widget.height ?? (isLg ? AppSizes.buttonLg : AppSizes.buttonMd);
    final double fontSize = widget.fontSize ?? (isLg ? 16 : 15);
    final double hPad = isLg ? 24 : 22;
    final double radius = widget.variant == AppButtonVariant.secondary
        ? AppRadii.md
        : AppRadii.pill;
    final bool canTap = widget.enabled && widget.onPressed != null;

    final Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (widget.leading != null) ...<Widget>[
          widget.leading!,
          SizedBox(width: 8.w),
        ],
        Flexible(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.display(
              fontSize,
              weight: FontWeight.w600,
              color: palette.foreground,
              height: 1,
            ),
          ),
        ),
      ],
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: canTap ? (_) => setState(() => _pressed = true) : null,
      onTapUp: canTap ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: canTap ? () => setState(() => _pressed = false) : null,
      onTap: canTap ? widget.onPressed : null,
      child: Semantics(
        button: true,
        enabled: canTap,
        label: widget.label,
        excludeSemantics: true,
        child: AnimatedScale(
          scale: _pressed ? _pressedScale : 1,
          duration: AppDurations.fast,
          child: Container(
            height: height.h,
            width: widget.expand ? double.infinity : null,
            padding: EdgeInsets.symmetric(horizontal: hPad.w),
            // An aligned Container grows to its parent; hug the label for
            // auto-width buttons (Refresh, Retry, End Leave).
            alignment: widget.expand ? Alignment.center : null,
            decoration: BoxDecoration(
              color: palette.background,
              borderRadius: BorderRadius.circular(radius.r),
              border: palette.border == null
                  ? null
                  : Border.all(color: palette.border!, width: 1.5),
            ),
            child: content,
          ),
        ),
      ),
    );
  }

  static _ButtonPalette _paletteFor(AppButtonVariant variant, bool enabled) {
    if (!enabled) {
      return const _ButtonPalette(
        background: AppColors.field,
        foreground: AppColors.textSecondary,
      );
    }
    switch (variant) {
      case AppButtonVariant.primary:
        return const _ButtonPalette(
          background: AppColors.action,
          foreground: AppColors.white,
        );
      case AppButtonVariant.brand:
        return const _ButtonPalette(
          background: AppColors.brandDeep,
          foreground: AppColors.white,
        );
      case AppButtonVariant.secondary:
        return const _ButtonPalette(
          background: Colors.transparent,
          foreground: AppColors.action,
          border: AppColors.action,
        );
      case AppButtonVariant.tinted:
        return const _ButtonPalette(
          background: AppColors.surfaceTint,
          foreground: AppColors.action,
          border: AppColors.action,
        );
      case AppButtonVariant.dangerOutline:
        return const _ButtonPalette(
          background: Colors.transparent,
          foreground: AppColors.coral,
          border: AppColors.coral,
        );
      case AppButtonVariant.danger:
        return const _ButtonPalette(
          background: AppColors.coral,
          foreground: AppColors.white,
        );
      case AppButtonVariant.ghost:
        return const _ButtonPalette(
          background: Colors.transparent,
          foreground: AppColors.textMuted,
        );
    }
  }
}

class _ButtonPalette {
  const _ButtonPalette({
    required this.background,
    required this.foreground,
    this.border,
  });

  final Color background;
  final Color foreground;
  final Color? border;
}
