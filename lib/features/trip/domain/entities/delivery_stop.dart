import 'package:imart_delivery_app/features/trip/domain/entities/order_status.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/payment_mode.dart';

/// One customer order the rider delivers, i.e. one stop on the route.
class DeliveryStop {
  /// Creates a stop.
  const DeliveryStop({
    required this.orderId,
    required this.customerName,
    required this.customerPhone,
    required this.area,
    required this.address,
    required this.itemCount,
    required this.distanceKm,
    required this.etaMinutes,
    required this.status,
    required this.paymentMode,
    required this.amount,
    required this.contents,
    required this.latitude,
    required this.longitude,
    required this.turnInstruction,
    this.deliveryId = '',
    this.cashDue = '',
    this.landmark = '',
  });

  /// Order id, e.g. `#IM-4821`.
  final String orderId;

  /// Customer full name.
  final String customerName;

  /// Customer phone in E.164, e.g. `+919880011223`.
  final String customerPhone;

  /// Short locality.
  final String area;

  /// Full address (without the landmark).
  final String address;

  /// Customer's landmark, e.g. "Opposite SBI ATM"; empty when not given.
  final String landmark;

  /// Number of line items.
  final int itemCount;

  /// Distance from the hub.
  final double distanceKm;

  /// Estimated minutes to reach.
  final int etaMinutes;

  /// Lifecycle status.
  final OrderStatus status;

  /// Payment mode.
  final PaymentMode paymentMode;

  /// Order value in rupees.
  final int amount;

  /// Line items, e.g. `1kg × Onion`.
  final List<String> contents;

  /// Drop latitude.
  final double latitude;

  /// Drop longitude.
  final double longitude;

  /// Next manoeuvre shown in the navigation banner.
  final String turnInstruction;

  /// Server delivery id used for status updates; empty for fixtures.
  final String deliveryId;

  /// Exact cash to collect as the server formats it (e.g. `"500.00"`);
  /// empty for prepaid orders and fixtures.
  final String cashDue;

  /// Copy with a new [status].
  DeliveryStop copyWith({OrderStatus? status}) {
    return DeliveryStop(
      orderId: orderId,
      customerName: customerName,
      customerPhone: customerPhone,
      area: area,
      address: address,
      itemCount: itemCount,
      distanceKm: distanceKm,
      etaMinutes: etaMinutes,
      status: status ?? this.status,
      paymentMode: paymentMode,
      amount: amount,
      contents: contents,
      latitude: latitude,
      longitude: longitude,
      turnInstruction: turnInstruction,
      deliveryId: deliveryId,
      cashDue: cashDue,
      landmark: landmark,
    );
  }
}
