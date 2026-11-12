import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/theme.dart';
import 'package:imart_delivery_app/app/theme/typography.dart';
import 'package:imart_delivery_app/core/widgets/app_avatar.dart';
import 'package:imart_delivery_app/core/widgets/app_icon.dart';
import 'package:imart_delivery_app/features/profile/domain/entities/rider_profile.dart';

/// Deep-curved brand header with avatar, name, phone and email.
class ProfileHeaderSection extends StatelessWidget {
  /// Creates the header.
  const ProfileHeaderSection({super.key, required this.profile});

  /// Rider shown.
  final RiderProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        24.w,
        AppSizes.topInset(context, AppSizes.headerTop),
        24.w,
        34.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.brand,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadii.profileHeader.r),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            AppStrings.profile,
            style: AppTypography.display(24, color: AppColors.white),
          ),
          SizedBox(height: 16.h),
          Row(
            children: <Widget>[
              AppAvatar(
                name: profile.name,
                imageUrl: profile.avatarUrl,
                size: 64,
                ring: true,
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      profile.name,
                      style: AppTypography.display(18, color: AppColors.white),
                    ),
                    SizedBox(height: 6.h),
                    _ContactLine(
                      glyph: AppIconGlyph.phone,
                      text: profile.phone,
                    ),
                    SizedBox(height: 6.h),
                    _ContactLine(glyph: AppIconGlyph.mail, text: profile.email),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({required this.glyph, required this.text});

  final AppIconGlyph glyph;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        AppIcon(glyph, size: 14, color: AppColors.coral, strokeWidth: 1.8),
        SizedBox(width: 8.w),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body(13, color: AppColors.white85),
          ),
        ),
      ],
    );
  }
}
