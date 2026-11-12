import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/theme.dart';
import 'package:imart_delivery_app/app/theme/typography.dart';
import 'package:imart_delivery_app/core/widgets/app_button.dart';
import 'package:imart_delivery_app/features/trip/application/providers/trip_providers.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/fail_reason.dart';

/// "Mark as Failed" reason picker. Pops the chosen reason id.
class FailDeliverySheet extends ConsumerWidget {
  /// Creates the sheet body.
  const FailDeliverySheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<FailReason> reasons =
        ref.watch(failReasonsProvider).valueOrNull ?? const <FailReason>[];
    final String? selected = ref.watch(selectedFailReasonProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(height: 4.h),
        Text(
          AppStrings.markAsFailed,
          textAlign: TextAlign.center,
          style: AppTypography.display(20),
        ),
        SizedBox(height: 6.h),
        Text(
          AppStrings.returnedToWarehouse,
          textAlign: TextAlign.center,
          style: AppTypography.body(13, color: AppColors.textMuted),
        ),
        SizedBox(height: 18.h),
        for (int i = 0; i < reasons.length; i++) ...<Widget>[
          if (i > 0) SizedBox(height: 10.h),
          FailReasonTile(
            label: reasons[i].label,
            selected: reasons[i].id == selected,
            onTap: () => ref.read(selectedFailReasonProvider.notifier).state =
                reasons[i].id,
          ),
        ],
        SizedBox(height: 18.h),
        AppButton(
          label: AppStrings.confirmFailedDelivery,
          variant: AppButtonVariant.danger,
          enabled: selected != null,
          height: 50,
          onPressed: () => Navigator.of(context).pop(selected),
        ),
        SizedBox(height: 10.h),
        AppButton(
          label: AppStrings.cancel,
          variant: AppButtonVariant.ghost,
          height: 46,
          fontSize: 14,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

/// Radio row for a fail reason.
class FailReasonTile extends StatelessWidget {
  /// Creates the row.
  const FailReasonTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  /// Reason label.
  final String label;

  /// Selected.
  final bool selected;

  /// Tap handler.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          constraints: BoxConstraints(minHeight: AppSizes.tapMin.h),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: selected ? AppColors.coralTint8 : AppColors.surfaceInset,
            borderRadius: BorderRadius.circular(AppRadii.lg.r),
            border: Border.all(
              color: selected ? AppColors.coral : AppColors.borderHairline,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 20.r,
                height: 20.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.coral : AppColors.field,
                    width: 2,
                  ),
                ),
                child: selected
                    ? Container(
                        width: 10.r,
                        height: 10.r,
                        decoration: const BoxDecoration(
                          color: AppColors.coral,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.body(15, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
