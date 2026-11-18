import 'package:imart_delivery_app/core/network/api_client.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/delivery_stop.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/fail_reason.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/order_status.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/payment_mode.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/trip_wrap_up.dart';

/// Server delivery statuses (`Delivery.status`).
abstract final class DeliveryStatus {
  /// Assigned to the rider, not yet accepted.
  static const String assigned = 'assigned';

  /// Accepted / rider at the warehouse.
  static const String atPickup = 'at_pickup';

  /// Collected from the warehouse.
  static const String pickedUp = 'picked_up';

  /// On the way to the customer.
  static const String outForDelivery = 'out_for_delivery';

  /// Handed over.
  static const String delivered = 'delivered';

  /// Attempt failed.
  static const String failed = 'failed';

  /// Statuses of a job the rider still has to finish.
  static const Set<String> active = <String>{
    assigned,
    atPickup,
    pickedUp,
    outForDelivery,
  };

  /// Statuses of a finished job.
  static const Set<String> finished = <String>{delivered, failed};
}

/// Maps backend delivery JSON to trip entities.
abstract final class DeliveryMapper {
  static const String _cod = 'cod';
  static const String _times = ' × ';
  static const String _addressJoin = ', ';

  /// Picks the stops of the current trip out of the rider's deliveries.
  ///
  /// The list holds every delivery ever assigned to the rider, finished ones
  /// included. With no active delivery there is no trip. Otherwise the trip
  /// is every delivery sharing the active ones' `trip_id`, in `stop_number`
  /// order (the order the rider saved; finished stops keep the first
  /// numbers). Servers without trips fall back to [_selectByTimestamps].
  static List<JsonMap> selectCurrentTrip(List<JsonMap> deliveries) {
    final List<JsonMap> active = deliveries
        .where((JsonMap d) => DeliveryStatus.active.contains(d['status']))
        .toList();
    if (active.isEmpty) {
      return const <JsonMap>[];
    }
    final String tripId = active
        .map((JsonMap d) => _string(d['trip_id']))
        .firstWhere((String id) => id.isNotEmpty, orElse: () => '');
    if (tripId.isEmpty) {
      return _selectByTimestamps(deliveries, active);
    }
    final List<JsonMap> trip = deliveries
        .where((JsonMap d) => _string(d['trip_id']) == tripId)
        .toList();
    _stableSort(trip, (JsonMap a, JsonMap b) {
      final int? x = _intOrNull(a['stop_number']);
      final int? y = _intOrNull(b['stop_number']);
      if (x == null || y == null) {
        return (x == null ? 1 : 0) - (y == null ? 1 : 0);
      }
      return x - y;
    });
    return trip;
  }

  /// `trip_id` of the selected trip's deliveries, or `''` without trips.
  static String tripIdOf(List<JsonMap> trip) => trip
      .map((JsonMap d) => _string(d['trip_id']))
      .firstWhere((String id) => id.isNotEmpty, orElse: () => '');

  /// `GET /delivery-trips/{id}/` and `GET /deliveries/cash-summary/` →
  /// Trip Complete figures. Either body may be empty (request failed).
  static TripWrapUp toWrapUp({required JsonMap trip, required JsonMap cash}) {
    final double? cashInHand = _double(cash['cash_in_hand']);
    return TripWrapUp(
      distanceKm: _double(trip['total_km']),
      cashToDeposit: cashInHand?.round(),
    );
  }

  /// Older servers without `trip_id`: every active delivery plus, once the
  /// trip has started, the stops finished since its first pickup. Finished
  /// stops come first (in the order they ended), then the stop being
  /// delivered, then the rest.
  static List<JsonMap> _selectByTimestamps(
    List<JsonMap> deliveries,
    List<JsonMap> active,
  ) {
    final List<DateTime> pickups = active
        .map((JsonMap d) => _date(d['picked_up_at']))
        .whereType<DateTime>()
        .toList();
    final DateTime? tripStart = pickups.isEmpty
        ? null
        : pickups.reduce((DateTime a, DateTime b) => a.isBefore(b) ? a : b);
    final List<JsonMap> finished = tripStart == null
        ? <JsonMap>[]
        : deliveries.where((JsonMap d) {
            final DateTime? ended = _endedAt(d);
            return DeliveryStatus.finished.contains(d['status']) &&
                ended != null &&
                !ended.isBefore(tripStart);
          }).toList();
    finished.sort(
      (JsonMap a, JsonMap b) => _endedAt(a)!.compareTo(_endedAt(b)!),
    );
    int rank(JsonMap d) => switch (d['status']) {
      DeliveryStatus.outForDelivery => 0,
      DeliveryStatus.pickedUp => 1,
      _ => 2,
    };
    final List<JsonMap> ordered = List<JsonMap>.of(active);
    _stableSort(ordered, (JsonMap a, JsonMap b) => rank(a) - rank(b));
    return <JsonMap>[...finished, ...ordered];
  }

  /// One delivery as a trip stop.
  static DeliveryStop toStop(JsonMap delivery) {
    final JsonMap order = _map(delivery['order_details']);
    final JsonMap customer = _map(order['user']);
    final JsonMap address = _map(order['shipping_address']);
    final JsonMap trip = _map(delivery['trip']);
    final bool cod = order['payment_mode'] == _cod;
    final String cashDue = cod ? _string(order['amount_to_collect']) : '';
    final String orderNumber = _string(order['id']).isNotEmpty
        ? _string(order['id'])
        : _string(delivery['order']);
    return DeliveryStop(
      deliveryId: _string(delivery['id']),
      orderId: '#$orderNumber',
      customerName: _personName(address).isNotEmpty
          ? _personName(address)
          : _personName(customer),
      customerPhone: _string(customer['phone_number']),
      area: _string(address['locality']).isNotEmpty
          ? _string(address['locality'])
          : _string(address['city']),
      address: _address(address),
      landmark: _string(address['landmark']),
      itemCount: _int(delivery['item_count']),
      distanceKm: _double(trip['distance_km']) ?? 0,
      etaMinutes: _int(trip['eta_minutes']),
      status: toOrderStatus(_string(delivery['status'])),
      paymentMode: cod ? PaymentMode.cod : PaymentMode.prepaid,
      amount: (_double(cod ? cashDue : order['total']) ?? 0).round(),
      cashDue: cashDue,
      contents: _contents(delivery['items']),
      latitude: _double(address['latitude']) ?? _double(order['latitude']) ?? 0,
      longitude:
          _double(address['longitude']) ?? _double(order['longitude']) ?? 0,
      turnInstruction: '',
    );
  }

  /// Server status → app status. `assigned` and `at_pickup` are both
  /// "not picked yet" in the app's pickup screen.
  static OrderStatus toOrderStatus(String status) => switch (status) {
    DeliveryStatus.pickedUp => OrderStatus.pickedUp,
    DeliveryStatus.outForDelivery => OrderStatus.outForDelivery,
    DeliveryStatus.delivered => OrderStatus.delivered,
    DeliveryStatus.failed => OrderStatus.failed,
    _ => OrderStatus.assigned,
  };

  /// One row of `GET /deliveries/fail-reasons/`.
  static FailReason toFailReason(JsonMap row) => FailReason(
    id: _string(row['code']),
    label: _string(row['label']),
    requiresNotes: row['requires_notes'] == true,
  );

  // Only what was actually packed: unavailable lines are not carried and
  // are already deducted from the cash to collect.
  static List<String> _contents(Object? items) {
    if (items is! List) {
      return const <String>[];
    }
    return <String>[
      for (final JsonMap item in items.whereType<JsonMap>())
        if (item['is_available'] != false &&
            _int(item['fulfilled_quantity'] ?? item['quantity']) > 0)
          '${_int(item['fulfilled_quantity'] ?? item['quantity'])}$_times'
              '${_itemName(item)}',
    ];
  }

  static String _itemName(JsonMap item) {
    final String name = _string(item['product_name']);
    final String variant = _string(item['variant_name']);
    return variant.isEmpty ? name : '$name ($variant)';
  }

  static String _address(JsonMap a) {
    final String cityLine = <String>[
      _string(a['city']),
      _string(a['postal_code']),
    ].where((String s) => s.isNotEmpty).join(' ');
    return <String>[
      _string(a['street_address1']),
      _string(a['street_address2']),
      cityLine,
    ].where((String s) => s.isNotEmpty).join(_addressJoin);
  }

  static String _personName(JsonMap person) => <String>[
    _string(person['first_name']),
    _string(person['last_name']),
  ].where((String s) => s.isNotEmpty).join(' ');

  static DateTime? _endedAt(JsonMap d) =>
      _date(d['delivered_at']) ??
      _date(d['status_changed_at']) ??
      _date(d['updated_at']);

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  static JsonMap _map(Object? value) =>
      value is JsonMap ? value : const <String, dynamic>{};

  static String _string(Object? value) => switch (value) {
    final String s => s,
    final num n => n.toString(),
    _ => '',
  };

  static int _int(Object? value) => _intOrNull(value) ?? 0;

  static int? _intOrNull(Object? value) => switch (value) {
    final num n => n.toInt(),
    final String s => int.tryParse(s),
    _ => null,
  };

  static double? _double(Object? value) => switch (value) {
    final num n => n.toDouble(),
    final String s => double.tryParse(s),
    _ => null,
  };

  // Stable insertion sort: keeps the server's order within a rank.
  static void _stableSort<T>(List<T> list, int Function(T a, T b) compare) {
    for (int i = 1; i < list.length; i++) {
      final T item = list[i];
      int j = i - 1;
      while (j >= 0 && compare(list[j], item) > 0) {
        list[j + 1] = list[j];
        j--;
      }
      list[j + 1] = item;
    }
  }
}
