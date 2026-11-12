import 'package:flutter/material.dart';

import 'package:imart_delivery_app/core/widgets/app_badge.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/order_status.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/payment_mode.dart';

/// Lifecycle pill for an [OrderStatus].
class OrderStatusBadge extends StatelessWidget {
  /// Creates the badge.
  const OrderStatusBadge({super.key, required this.status});

  /// Status to show.
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    return AppBadge(
      label: status.label,
      tone: switch (status) {
        OrderStatus.assigned => AppBadgeTone.violet,
        OrderStatus.pickedUp => AppBadgeTone.blue,
        OrderStatus.outForDelivery => AppBadgeTone.amber,
        OrderStatus.delivered => AppBadgeTone.green,
        OrderStatus.failed => AppBadgeTone.red,
      },
    );
  }
}

/// Prepaid / COD pill.
class PaymentModeBadge extends StatelessWidget {
  /// Creates the badge.
  const PaymentModeBadge({super.key, required this.mode});

  /// Payment mode.
  final PaymentMode mode;

  @override
  Widget build(BuildContext context) {
    return AppBadge(
      label: mode.label,
      tone: mode == PaymentMode.cod ? AppBadgeTone.amber : AppBadgeTone.green,
    );
  }
}
