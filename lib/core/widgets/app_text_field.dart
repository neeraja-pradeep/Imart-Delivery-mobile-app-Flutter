import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/theme.dart';
import 'package:imart_delivery_app/app/theme/typography.dart';

/// Field styles from the design-system `Input`.
enum AppTextFieldVariant {
  /// White field, hairline border, xs shadow.
  outline,

  /// Grey filled field without border (Edit Profile).
  filled,
}

/// The iMart text input with optional label above the field.
class AppTextField extends StatefulWidget {
  /// Creates a text field.
  const AppTextField({
    super.key,
    this.label,
    this.placeholder,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.keyboardType,
    this.maxLength,
    this.digitsOnly = false,
    this.variant = AppTextFieldVariant.outline,
  });

  /// Optional label shown above the field.
  final String? label;

  /// Placeholder text.
  final String? placeholder;

  /// External controller; when null an internal one seeded with
  /// [initialValue] is used.
  final TextEditingController? controller;

  /// Initial value for the internal controller.
  final String? initialValue;

  /// Change callback.
  final ValueChanged<String>? onChanged;

  /// Keyboard type.
  final TextInputType? keyboardType;

  /// Maximum characters.
  final int? maxLength;

  /// Restricts input to digits (numeric inputmode).
  final bool digitsOnly;

  /// Field style.
  final AppTextFieldVariant variant;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  static const Color _placeholderColor = Color(0xFF757575);
  static const double _fontSize = 14;
  static const double _verticalPadding = 13;

  /// CSS box: 13px padding top/bottom + Roboto's normal line (16.4px).
  static double get _fieldHeight =>
      _verticalPadding * 2 + _fontSize * 2400 / 2048;

  late final TextEditingController _ownController;
  final FocusNode _focusNode = FocusNode();

  TextEditingController get _controller => widget.controller ?? _ownController;

  @override
  void initState() {
    super.initState();
    _ownController = TextEditingController(text: widget.initialValue);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    _ownController.dispose();
    super.dispose();
  }

  void _onFocusChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final bool filled = widget.variant == AppTextFieldVariant.filled;
    final Color idleBorder = filled
        ? Colors.transparent
        : AppColors.borderHairline;
    final Color border = _focusNode.hasFocus ? AppColors.action : idleBorder;

    final Widget field = AnimatedContainer(
      duration: AppDurations.base,
      decoration: BoxDecoration(
        color: filled ? AppColors.field : AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.sm.r),
        border: Border.all(color: border),
        boxShadow: filled ? null : AppShadows.xs,
      ),
      child: SizedBox(
        height: _fieldHeight.h,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: widget.onChanged,
          keyboardType: widget.keyboardType,
          inputFormatters: <TextInputFormatter>[
            if (widget.digitsOnly) FilteringTextInputFormatter.digitsOnly,
            if (widget.maxLength != null)
              LengthLimitingTextInputFormatter(widget.maxLength),
          ],
          cursorColor: AppColors.action,
          textAlignVertical: TextAlignVertical.center,
          style: AppTypography.body(_fontSize),
          decoration: InputDecoration(
            isCollapsed: true,
            border: InputBorder.none,
            hintText: widget.placeholder,
            hintStyle: AppTypography.body(_fontSize, color: _placeholderColor),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
          ),
        ),
      ),
    );

    if (widget.label == null) {
      return field;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          widget.label!,
          style: AppTypography.body(14, weight: FontWeight.w500),
        ),
        SizedBox(height: 8.h),
        field,
      ],
    );
  }
}
