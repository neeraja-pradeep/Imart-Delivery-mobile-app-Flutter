import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/app/router/app_routes.dart';
import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/core/widgets/app_avatar.dart';
import 'package:imart_delivery_app/core/widgets/app_button.dart';
import 'package:imart_delivery_app/core/widgets/app_status_bar_style.dart';
import 'package:imart_delivery_app/core/widgets/app_sub_header.dart';
import 'package:imart_delivery_app/core/widgets/app_text_field.dart';
import 'package:imart_delivery_app/features/profile/application/providers/profile_providers.dart';
import 'package:imart_delivery_app/features/profile/domain/entities/rider_profile.dart';

/// Edit Profile: avatar and Name / Phone / Mail / Vehicle fields.
class EditProfileScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  static const double _avatarSize = 92;
  static const double _bottomPadding = 84;

  late final RiderProfile? _initial = ref
      .read(profileControllerProvider)
      .valueOrNull;
  late final TextEditingController _name = TextEditingController(
    text: _initial?.name,
  );
  late final TextEditingController _phone = TextEditingController(
    text: _initial?.phone,
  );
  late final TextEditingController _email = TextEditingController(
    text: _initial?.email,
  );
  late final TextEditingController _vehicle = TextEditingController(
    text: _initial?.vehicle,
  );

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _vehicle.dispose();
    super.dispose();
  }

  void _back() => context.go(AppRoutes.profile);

  Future<void> _onSaveAsync() async {
    await ref
        .read(profileControllerProvider.notifier)
        .saveAsync(
          name: _name.text.trim(),
          phone: _phone.text.trim(),
          email: _email.text.trim(),
          vehicle: _vehicle.text.trim(),
        );
    if (mounted) {
      _back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop) {
          _back();
        }
      },
      child: AppStatusBarStyle(
        dark: false,
        child: ColoredBox(
          color: AppColors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              AppSubHeader(title: AppStrings.editProfile, onBack: _back),
              SizedBox(height: 24.h),
              Center(
                child: AppAvatar(
                  name: _initial?.name ?? '',
                  imageUrl: _initial?.avatarUrl,
                  size: _avatarSize,
                ),
              ),
              SizedBox(height: 10.h),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  22.w,
                  12.h,
                  22.w,
                  _bottomPadding.h,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    AppTextField(
                      label: AppStrings.name,
                      controller: _name,
                      variant: AppTextFieldVariant.filled,
                    ),
                    SizedBox(height: 18.h),
                    AppTextField(
                      label: AppStrings.phone,
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      variant: AppTextFieldVariant.filled,
                    ),
                    SizedBox(height: 18.h),
                    AppTextField(
                      label: AppStrings.mail,
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      variant: AppTextFieldVariant.filled,
                    ),
                    SizedBox(height: 18.h),
                    AppTextField(
                      label: AppStrings.vehicle,
                      controller: _vehicle,
                      variant: AppTextFieldVariant.filled,
                    ),
                    SizedBox(height: 18.h + 10.h),
                    AppButton(label: AppStrings.save, onPressed: _onSaveAsync),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
