import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/theme.dart';
import 'package:imart_delivery_app/app/theme/typography.dart';
import 'package:imart_delivery_app/core/widgets/app_icon.dart';

/// One destination in [AppNavBar].
class AppNavItem {
  /// Creates a nav destination.
  const AppNavItem({required this.label, required this.glyph});

  /// Label under the icon.
  final String label;

  /// Icon glyph.
  final AppIconGlyph glyph;
}

/// Fixed, full-width, solid-white bottom navigation with labels.
class AppNavBar extends StatelessWidget {
  /// Creates the bottom nav.
  const AppNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelected,
  });

  /// Destinations.
  final List<AppNavItem> items;

  /// Active destination index.
  final int currentIndex;

  /// Selection callback.
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      height: AppSizes.navBar.h + bottomInset,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: const Border(top: BorderSide(color: AppColors.line)),
        boxShadow: AppShadows.navBar,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < items.length; i++)
            Expanded(
              child: _NavButton(
                item: items[i],
                active: i == currentIndex,
                onTap: () => onSelected(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final AppNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = active ? AppColors.action : AppColors.textMuted;
    return Semantics(
      button: true,
      selected: active,
      label: item.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AppIcon(item.glyph, size: 23, color: color),
            SizedBox(height: 3.h),
            Text(
              item.label,
              style: AppTypography.display(
                11,
                weight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
