import 'package:flutter_test/flutter_test.dart';

import 'package:imart_delivery_app/core/network/api_client.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/delivery_stop.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/order_status.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/payment_mode.dart';
import 'package:imart_delivery_app/features/trip/infrastructure/mappers/delivery_mapper.dart';

JsonMap _delivery({
  required int id,
  required String status,
  String? pickedUpAt,
  String? deliveredAt,
  String paymentMode = 'prepaid',
  String total = '120.00',
  String amountToCollect = '0.00',
  int? tripId,
  int? stopNumber,
  String? locality,
}) => <String, dynamic>{
  'id': id,
  'trip_id': tripId,
  'stop_number': stopNumber,
  'order': id + 100,
  'status': status,
  'picked_up_at': pickedUpAt,
  'delivered_at': deliveredAt,
  'item_count': 3,
  'order_details': <String, dynamic>{
    'id': id + 100,
    'user': <String, dynamic>{
      'first_name': 'Anita',
      'last_name': 'M',
      'phone_number': '9000000001',
    },
    'shipping_address': <String, dynamic>{
      'first_name': 'Anita',
      'last_name': 'M',
      'street_address1': '12 MG Road',
      'street_address2': null,
      'landmark': 'Near metro',
      'city': 'Kochi',
      'postal_code': '682001',
      'locality': locality,
      'latitude': '9.93',
      'longitude': '76.26',
    },
    'total': total,
    'payment_mode': paymentMode,
    'amount_to_collect': amountToCollect,
  },
  'items': <JsonMap>[
    <String, dynamic>{
      'product_name': 'Tomato',
      'variant_name': '1 kg',
      'quantity': 2,
      'fulfilled_quantity': 2,
      'is_available': true,
    },
    <String, dynamic>{
      'product_name': 'Curd',
      'variant_name': '',
      'quantity': 1,
      'fulfilled_quantity': 0,
      'is_available': false,
    },
  ],
  'trip': <String, dynamic>{'distance_km': 4.7, 'eta_minutes': 15},
};

void main() {
  group('DeliveryMapper.toStop', () {
    test('maps a COD delivery with the exact cash due', () {
      final DeliveryStop stop = DeliveryMapper.toStop(
        _delivery(
          id: 16,
          status: 'out_for_delivery',
          paymentMode: 'cod',
          total: '500.00',
          amountToCollect: '480.50',
        ),
      );
      expect(stop.deliveryId, '16');
      expect(stop.orderId, '#116');
      expect(stop.customerName, 'Anita M');
      expect(stop.customerPhone, '9000000001');
      expect(stop.address, '12 MG Road, Near metro, Kochi 682001');
      expect(stop.status, OrderStatus.outForDelivery);
      expect(stop.paymentMode, PaymentMode.cod);
      expect(stop.cashDue, '480.50');
      expect(stop.amount, 481);
      expect(stop.distanceKm, 4.7);
      expect(stop.etaMinutes, 15);
      expect(stop.latitude, 9.93);
    });

    test('lists only packed items', () {
      final DeliveryStop stop = DeliveryMapper.toStop(
        _delivery(id: 1, status: 'assigned'),
      );
      expect(stop.contents, <String>['2 × Tomato (1 kg)']);
    });

    test('prepaid shows the order total and no cash due', () {
      final DeliveryStop stop = DeliveryMapper.toStop(
        _delivery(id: 1, status: 'assigned'),
      );
      expect(stop.paymentMode, PaymentMode.prepaid);
      expect(stop.amount, 120);
      expect(stop.cashDue, isEmpty);
    });

    test('at_pickup is still "not picked" in the app', () {
      expect(DeliveryMapper.toOrderStatus('at_pickup'), OrderStatus.assigned);
      expect(DeliveryMapper.toOrderStatus('picked_up'), OrderStatus.pickedUp);
    });
  });

  group('DeliveryMapper with trips', () {
    test('the open trip is picked by trip_id, in stop_number order', () {
      final List<JsonMap> trip = DeliveryMapper.selectCurrentTrip(<JsonMap>[
        _delivery(id: 1, status: 'delivered', tripId: 8, stopNumber: 1),
        _delivery(id: 4, status: 'picked_up', tripId: 9, stopNumber: 3),
        _delivery(id: 2, status: 'delivered', tripId: 9, stopNumber: 1),
        _delivery(id: 3, status: 'out_for_delivery', tripId: 9, stopNumber: 2),
      ]);
      expect(trip.map((JsonMap d) => d['id']), <int>[2, 3, 4]);
      expect(DeliveryMapper.tripIdOf(trip), '9');
    });

    test('locality is the area, falling back to the city', () {
      expect(
        DeliveryMapper.toStop(
          _delivery(id: 1, status: 'assigned', locality: 'Panampilly Nagar'),
        ).area,
        'Panampilly Nagar',
      );
      expect(
        DeliveryMapper.toStop(_delivery(id: 1, status: 'assigned')).area,
        'Kochi',
      );
    });

    test('wrap-up reads trip km and cash in hand, null when missing', () {
      final wrap = DeliveryMapper.toWrapUp(
        trip: <String, dynamic>{'total_km': 9.6},
        cash: <String, dynamic>{'cash_in_hand': '1000.40'},
      );
      expect(wrap.distanceKm, 9.6);
      expect(wrap.cashToDeposit, 1000);
      final empty = DeliveryMapper.toWrapUp(
        trip: const <String, dynamic>{},
        cash: const <String, dynamic>{},
      );
      expect(empty.distanceKm, isNull);
      expect(empty.cashToDeposit, isNull);
    });
  });

  group('DeliveryMapper.selectCurrentTrip', () {
    test('no active delivery means no trip', () {
      final List<JsonMap> trip = DeliveryMapper.selectCurrentTrip(<JsonMap>[
        _delivery(
          id: 1,
          status: 'delivered',
          deliveredAt: '2026-11-13T10:00:00+05:30',
        ),
      ]);
      expect(trip, isEmpty);
    });

    test('a new, unstarted trip excludes older finished jobs', () {
      final List<JsonMap> trip = DeliveryMapper.selectCurrentTrip(<JsonMap>[
        _delivery(
          id: 1,
          status: 'delivered',
          deliveredAt: '2026-11-13T10:00:00+05:30',
        ),
        _delivery(id: 2, status: 'assigned'),
      ]);
      expect(trip.map((JsonMap d) => d['id']), <int>[2]);
    });

    test('a started trip keeps stops finished since its pickup, in order', () {
      final List<JsonMap> trip = DeliveryMapper.selectCurrentTrip(<JsonMap>[
        _delivery(
          id: 1,
          status: 'delivered',
          deliveredAt: '2026-11-13T09:00:00+05:30',
        ),
        _delivery(
          id: 2,
          status: 'picked_up',
          pickedUpAt: '2026-11-13T10:00:00+05:30',
        ),
        _delivery(
          id: 3,
          status: 'delivered',
          pickedUpAt: '2026-11-13T10:00:00+05:30',
          deliveredAt: '2026-11-13T10:30:00+05:30',
        ),
        _delivery(
          id: 4,
          status: 'out_for_delivery',
          pickedUpAt: '2026-11-13T10:00:00+05:30',
        ),
      ]);
      expect(trip.map((JsonMap d) => d['id']), <int>[3, 4, 2]);
    });
  });

  test('fail reasons keep the requires-notes flag', () {
    expect(
      DeliveryMapper.toFailReason(<String, dynamic>{
        'code': 'other',
        'label': 'Other',
        'requires_notes': true,
      }).requiresNotes,
      isTrue,
    );
  });
}
