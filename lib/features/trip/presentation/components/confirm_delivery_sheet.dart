import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/theme.dart';
import 'package:imart_delivery_app/app/theme/typography.dart';
import 'package:imart_delivery_app/core/utils/format_utils.dart';
import 'package:imart_delivery_app/core/widgets/app_bullet_list.dart';
import 'package:imart_delivery_app/core/widgets/app_button.dart';
import 'package:imart_delivery_app/core/widgets/app_icon.dart';
import 'package:imart_delivery_app/features/trip/application/providers/trip_providers.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/delivery_stop.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/payment_mode.dart';
import 'package:imart_delivery_app/features/trip/presentation/components/cash_confirm_tile.dart';
import 'package:imart_delivery_app/features/trip/presentation/components/pay_chip.dart';

/// "Confirm Delivery?" guard against accidental taps.
///
/// Lists the cart and, for COD, requires ticking "I have collected ₹…"
/// before "Yes, Delivered" enables. Pops `true` when confirmed.
class ConfirmDeliverySheet extends ConsumerWidget {
  /// Creates the sheet body.
  const ConfirmDeliverySheet({super.key, required this.stop});

  static const double _itemsMaxHeight = 168;

  /// Stop being confirmed.
  final DeliveryStop stop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool cod = stop.paymentMode == PaymentMode.cod;
    final bool cashCollected = ref.watch(isCashCollectedProvider);
    final bool canConfirm = !cod || cashCollected;
    final TextStyle lead = AppTypography.body(
      13.5,
      color: AppColors.textSecondary,
      height: 1.5,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Center(
          child: Container(
            width: 60.r,
            height: 60.r,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.surfaceTint,
              shape: BoxShape.circle,
            ),
            child: const AppIcon(
              AppIconGlyph.check,
              size: 30,
              color: AppColors.action,
              strokeWidth: 2.6,
            ),
          ),
        ),
        SizedBox(height: 14.h),
        Text(
          AppStrings.confirmDelivery,
          textAlign: TextAlign.center,
          style: AppTypography.display(20),
        ),
        SizedBox(height: 6.h),
        Text.rich(
          TextSpan(
            text: 'Mark order ${stop.orderId} for ',
            children: <InlineSpan>[
              TextSpan(
                text: stop.customerName,
                style: lead.copyWith(fontWeight: FontWeight.w700),
              ),
              const TextSpan(text: ' as delivered.'),
            ],
          ),
          textAlign: TextAlign.center,
          style: lead,
        ),
        SizedBox(height: 14.h),
        Container(
          constraints: BoxConstraints(maxHeight: _itemsMaxHeight.h),
          decoration: BoxDecoration(
            color: AppColors.surfaceInset,
            borderRadius: BorderRadius.circular(AppRadii.lg.r),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  AppStrings.itemsCaption(stop.itemCount, stop.orderId),
                  style: AppTypography.caption(),
                ),
                SizedBox(height: 8.h),
                AppBulletList(items: stop.contents, gap: 7),
              ],
            ),
          ),
        ),
        SizedBox(height: 12.h),
        PayChip(
          mode: stop.paymentMode,
          amount: stop.amount,
          showIcon: false,
          centered: true,
        ),
        SizedBox(height: 12.h),
        if (cod) ...<Widget>[
          CashConfirmTile(
            amount: FormatUtils.rupees(stop.amount),
            checked: cashCollected,
            onToggle: () => ref
                .read(isCashCollectedProvider.notifier)
                .update((bool v) => !v),
          ),
          SizedBox(height: 12.h),
        ],
        AppButton(
          label: AppStrings.yesDelivered,
          enabled: canConfirm,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        SizedBox(height: 10.h),
        AppButton(
          label: AppStrings.cancel,
          variant: AppButtonVariant.ghost,
          height: 46,
          fontSize: 14,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}
