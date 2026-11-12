import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/app/theme/colors.dart';
import 'package:imart_delivery_app/app/theme/typography.dart';
import 'package:imart_delivery_app/core/utils/format_utils.dart';
import 'package:imart_delivery_app/core/widgets/app_bullet_list.dart';
import 'package:imart_delivery_app/core/widgets/app_button.dart';
import 'package:imart_delivery_app/core/widgets/app_card.dart';
import 'package:imart_delivery_app/core/widgets/app_dashed_divider.dart';
import 'package:imart_delivery_app/core/widgets/app_icon.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/delivery_stop.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/order_status.dart';
import 'package:imart_delivery_app/features/trip/presentation/components/order_status_badge.dart';
import 'package:imart_delivery_app/features/trip/presentation/components/pay_chip.dart';
import 'package:imart_delivery_app/features/trip/presentation/components/stop_number_badge.dart';

/// Expandable order card on the Trip tab.
///
/// Collapsed: sequence disc, name, area, distance · items · payment.
/// Expanded: contents list and payment strip. During pickup it carries
/// "Mark Picked Up" or the "Added to this trip · Remove" footer.
class StopCard extends StatelessWidget {
  /// Creates the card.
  const StopCard({
    super.key,
    required this.stop,
    required this.sequence,
    required this.pickupPhase,
    required this.isCurrent,
    required this.expanded,
    required this.onToggleExpand,
    required this.onPick,
    required this.onRemove,
  });

  /// Order shown.
  final DeliveryStop stop;

  /// 1-based position.
  final int sequence;

  /// Pickup phase (else enroute).
  final bool pickupPhase;

  /// This is the stop being delivered.
  final bool isCurrent;

  /// Expanded state.
  final bool expanded;

  /// Header tap.
  final VoidCallback onToggleExpand;

  /// "Mark Picked Up".
  final VoidCallback onPick;

  /// "Remove".
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final bool picked = stop.status == OrderStatus.pickedUp;
    Color borderColor = AppColors.borderHairline;
    double borderWidth = 1;
    if (isCurrent) {
      borderColor = AppColors.action;
      borderWidth = 2;
    } else if (pickupPhase && picked) {
      borderColor = AppColors.green200;
    }
    return AppCard(
      padding: const EdgeInsets.all(14),
      borderColor: borderColor,
      borderWidth: borderWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggleExpand,
            child: _StopSummaryRow(
              stop: stop,
              sequence: sequence,
              isCurrent: isCurrent,
              showStatus: !pickupPhase,
              expanded: expanded,
            ),
          ),
          if (expanded) _StopDetails(stop: stop),
          if (pickupPhase && stop.status == OrderStatus.assigned) ...<Widget>[
            SizedBox(height: 12.h),
            AppButton(
              label: AppStrings.markPickedUp,
              variant: AppButtonVariant.tinted,
              height: 46,
              fontSize: 14,
              leading: const AppIcon(
                AppIconGlyph.bag,
                size: 17,
                color: AppColors.action,
              ),
              onPressed: onPick,
            ),
          ],
          if (pickupPhase && picked) _PickedFooter(onRemove: onRemove),
        ],
      ),
    );
  }
}

class _StopSummaryRow extends StatelessWidget {
  const _StopSummaryRow({
    required this.stop,
    required this.sequence,
    required this.isCurrent,
    required this.showStatus,
    required this.expanded,
  });

  final DeliveryStop stop;
  final int sequence;
  final bool isCurrent;
  final bool showStatus;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final TextStyle meta = AppTypography.body(12, color: AppColors.textMuted);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        StopNumberBadge(
          sequence: sequence,
          status: stop.status,
          isCurrent: isCurrent,
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      stop.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.display(15),
                    ),
                  ),
                  if (showStatus) ...<Widget>[
                    SizedBox(width: 8.w),
                    OrderStatusBadge(status: stop.status),
                  ],
                ],
              ),
              SizedBox(height: 3.h),
              Text(
                stop.area,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body(
                  12.5,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              SizedBox(height: 9.h),
              Row(
                children: <Widget>[
                  const AppIcon(
                    AppIconGlyph.pinFilled,
                    size: 13,
                    color: AppColors.ink400,
                  ),
                  SizedBox(width: 5.w),
                  Text(FormatUtils.stopKm(stop.distanceKm), style: meta),
                  SizedBox(width: 8.w),
                  Text(
                    '·',
                    style: AppTypography.body(12, color: AppColors.ink400),
                  ),
                  SizedBox(width: 8.w),
                  Text(AppStrings.itemCount(stop.itemCount), style: meta),
                  SizedBox(width: 8.w),
                  PaymentModeBadge(mode: stop.paymentMode),
                  const Spacer(),
                  AppIcon(
                    expanded ? AppIconGlyph.caretUp : AppIconGlyph.caretDown,
                    size: 18,
                    color: AppColors.ink400,
                    strokeWidth: 2.2,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StopDetails extends StatelessWidget {
  const _StopDetails({required this.stop});

  final DeliveryStop stop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const AppDashedDivider(),
          SizedBox(height: 12.h),
          Text(
            AppStrings.orderContents(stop.orderId),
            style: AppTypography.caption(),
          ),
          SizedBox(height: 8.h),
          AppBulletList(items: stop.contents),
          SizedBox(height: 12.h + 8.h),
          PayChip(mode: stop.paymentMode, amount: stop.amount),
        ],
      ),
    );
  }
}

class _PickedFooter extends StatelessWidget {
  const _PickedFooter({required this.onRemove});

  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 12.h),
      padding: EdgeInsets.only(top: 10.h),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            children: <Widget>[
              const AppIcon(
                AppIconGlyph.check,
                size: 17,
                color: AppColors.action,
                strokeWidth: 2.6,
              ),
              SizedBox(width: 7.w),
              Text(
                AppStrings.addedToTrip,
                style: AppTypography.display(
                  13,
                  weight: FontWeight.w600,
                  color: AppColors.action,
                ),
              ),
            ],
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onRemove,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
              child: Text(
                AppStrings.remove,
                style: AppTypography.body(
                  13,
                  weight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
