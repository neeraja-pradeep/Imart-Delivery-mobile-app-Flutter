import 'package:imart_delivery_app/app/config/env.dart';
import 'package:imart_delivery_app/core/error/failure.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/delivery_stop.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/fail_reason.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/geo_position.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/trip_wrap_up.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/order_status.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/payment_mode.dart';
import 'package:imart_delivery_app/features/trip/infrastructure/data_sources/remote/trip_api.dart';

/// Fixture-backed [TripApi] carrying the exact data shown in the design.
///
/// Remove once the real endpoints are live. [preview] reproduces the
/// design's start-screen states (empty / error / mid-trip) for QA.
class TripStaticApi implements TripApi {
  /// Creates the static API.
  TripStaticApi({this.preview = PreviewScreen.splash});

  static const Duration _fetchLatency = Duration(milliseconds: 900);
  static const Duration _previewLoadLatency = Duration(milliseconds: 1300);
  static const Duration _startLatency = Duration(milliseconds: 800);

  /// Design-preview scenario.
  final PreviewScreen preview;

  int _fetchCount = 0;
  bool _onLeave = false;

  @override
  Future<List<DeliveryStop>> fetchAssignedStopsAsync() async {
    final bool first = _fetchCount == 0;
    _fetchCount++;
    await Future<void>.delayed(
      first && preview == PreviewScreen.loading
          ? _previewLoadLatency
          : _fetchLatency,
    );
    if (first && preview == PreviewScreen.error) {
      throw const NetworkFailure();
    }
    if (first && preview == PreviewScreen.empty) {
      return const <DeliveryStop>[];
    }
    if (first && preview == PreviewScreen.route) {
      return _withStatuses(OrderStatus.pickedUp);
    }
    if (first && preview == PreviewScreen.navigation) {
      final List<DeliveryStop> stops = _withStatuses(OrderStatus.pickedUp);
      stops[0] = stops[0].copyWith(status: OrderStatus.outForDelivery);
      return stops;
    }
    return List<DeliveryStop>.of(_stops);
  }

  @override
  Future<List<FailReason>> fetchFailReasonsAsync() async => _failReasons;

  @override
  Future<bool> fetchIsOnLeaveAsync() async => _onLeave;

  @override
  Future<void> startTripAsync(List<DeliveryStop> route) =>
      Future<void>.delayed(_startLatency);

  @override
  Future<void> markOutForDeliveryAsync(DeliveryStop stop) async {}

  @override
  Future<void> markArrivedAsync(DeliveryStop stop) async {}

  @override
  Future<void> markDeliveredAsync(
    DeliveryStop stop, {
    required bool cashCollected,
  }) async {}

  @override
  Future<void> markFailedAsync(DeliveryStop stop, String reasonId) async {}

  @override
  Future<void> setOnLeaveAsync({required bool onLeave}) async =>
      _onLeave = onLeave;

  @override
  Future<void> pushLocationAsync(GeoPosition position) async {}

  @override
  Future<TripWrapUp> fetchTripWrapUpAsync() async => TripWrapUp.none;

  List<DeliveryStop> _withStatuses(OrderStatus status) =>
      _stops.map((DeliveryStop s) => s.copyWith(status: status)).toList();

  static const List<FailReason> _failReasons = <FailReason>[
    FailReason(id: 'customer_unavailable', label: 'Customer unavailable'),
    FailReason(id: 'bad_address', label: 'Wrong or incomplete address'),
    FailReason(id: 'customer_refused', label: 'Customer refused the order'),
    FailReason(id: 'cannot_locate', label: 'Unable to locate address'),
  ];

  static const List<DeliveryStop> _stops = <DeliveryStop>[
    DeliveryStop(
      orderId: '#IM-4821',
      customerName: 'Ananya Rao',
      customerPhone: '+919880011223',
      area: 'Koramangala 5th Block',
      address: '#42, 80 Feet Road, Koramangala 5th Block, Bengaluru 560095',
      itemCount: 5,
      distanceKm: 2.4,
      etaMinutes: 8,
      status: OrderStatus.assigned,
      paymentMode: PaymentMode.prepaid,
      amount: 845,
      contents: <String>[
        '1kg × Onion',
        '2 × Diet Coke',
        '1 × Oreo Pack',
        '500g × Paneer',
        '1 × Bread Loaf',
      ],
      latitude: 12.9352,
      longitude: 77.6245,
      turnInstruction: 'Head south on 80 Feet Road',
    ),
    DeliveryStop(
      orderId: '#IM-4822',
      customerName: 'Rohan Mehta',
      customerPhone: '+919845567812',
      area: 'HSR Layout, Sector 2',
      address: '#9, 17th Cross, HSR Layout Sector 2, Bengaluru 560102',
      itemCount: 3,
      distanceKm: 4.1,
      etaMinutes: 14,
      status: OrderStatus.assigned,
      paymentMode: PaymentMode.cod,
      amount: 312,
      contents: <String>['2 × Amul Milk', '1 × Eggs (12 pcs)', '1kg × Tomato'],
      latitude: 12.9116,
      longitude: 77.6389,
      turnInstruction: 'Continue onto Hosur Road',
    ),
    DeliveryStop(
      orderId: '#IM-4823',
      customerName: 'Priya Nair',
      customerPhone: '+919900123456',
      area: 'Indiranagar',
      address: '#221, 100 Feet Road, Indiranagar, Bengaluru 560038',
      itemCount: 6,
      distanceKm: 6,
      etaMinutes: 19,
      status: OrderStatus.assigned,
      paymentMode: PaymentMode.prepaid,
      amount: 1290,
      contents: <String>[
        '1 × Atta 5kg',
        '2 × Basmati Rice',
        '1 × Cooking Oil 1L',
        '3 × Maggi',
        '1 × Sugar 1kg',
        '2 × Curd',
      ],
      latitude: 12.9719,
      longitude: 77.6412,
      turnInstruction: 'Turn left onto CMH Road',
    ),
    DeliveryStop(
      orderId: '#IM-4824',
      customerName: 'Vikram Shetty',
      customerPhone: '+919812345678',
      area: 'Brookefield, Whitefield',
      address: '#7, Brookefield Main Road, Whitefield, Bengaluru 560037',
      itemCount: 5,
      distanceKm: 11,
      etaMinutes: 31,
      status: OrderStatus.assigned,
      paymentMode: PaymentMode.cod,
      amount: 560,
      contents: <String>[
        '1 × Detergent 1kg',
        '2 × Bath Soap',
        '1 × Shampoo',
        '1 × Toothpaste',
        '1 × Biscuits',
      ],
      latitude: 12.9698,
      longitude: 77.7499,
      turnInstruction: 'Merge onto Varthur Road',
    ),
  ];
}
