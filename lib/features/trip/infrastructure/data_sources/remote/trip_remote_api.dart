import 'package:imart_delivery_app/core/error/failure.dart';
import 'package:imart_delivery_app/core/network/api_client.dart';
import 'package:imart_delivery_app/core/network/endpoints.dart';
import 'package:imart_delivery_app/core/utils/logger.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/delivery_stop.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/fail_reason.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/geo_position.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/payment_mode.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/trip_wrap_up.dart';
import 'package:imart_delivery_app/features/trip/infrastructure/data_sources/remote/trip_api.dart';
import 'package:imart_delivery_app/features/trip/infrastructure/mappers/delivery_mapper.dart';

/// [TripApi] backed by the iMart delivery-partner API.
///
/// The server moves a delivery one step per call
/// (`assigned → at_pickup → picked_up → out_for_delivery → delivered|failed`)
/// and keeps the order in sync. The app's pickup screen has no separate
/// "accept" step, so picking an order sends `at_pickup` then `picked_up`.
class TripRemoteApi implements TripApi {
  /// Creates the API over [client].
  TripRemoteApi(this._client);

  static const String _statusField = 'status';
  static const String _tripIdField = 'trip_id';
  static const String _offline = 'offline';
  static const String _online = 'online';

  // Server limits for the optional fields of a location point (2.6).
  static const double _maxAccuracyM = 100000;
  static const double _maxSpeedMps = 100;
  static const double _maxHeading = 360;

  final ApiClient _client;

  /// Open trip of the loaded stops (`''` before a load or without trips).
  /// Kept after the last stop finishes, for the Trip Complete screen.
  String _tripId = '';

  /// Turned off if the server rejects the phone's fix times (e.g. a phone
  /// clock running ahead); the server then stamps each point itself.
  bool _sendRecordedAt = true;

  /// Last known server status per delivery id, so each call sends only the
  /// steps still missing (e.g. after an app restart mid-pickup).
  final Map<String, String> _serverStatus = <String, String>{};

  List<FailReason> _failReasons = const <FailReason>[];

  @override
  Future<List<DeliveryStop>> fetchAssignedStopsAsync() async {
    final List<JsonMap> deliveries = await _client.getAllPagesAsync(
      ApiEndpoints.deliveries,
    );
    final List<JsonMap> trip = DeliveryMapper.selectCurrentTrip(deliveries);
    final String tripId = DeliveryMapper.tripIdOf(trip);
    if (tripId.isNotEmpty) {
      _tripId = tripId;
    }
    _serverStatus
      ..clear()
      ..addEntries(
        trip.map(
          (JsonMap d) => MapEntry<String, String>(
            d['id'].toString(),
            d[_statusField].toString(),
          ),
        ),
      );
    return trip.map(DeliveryMapper.toStop).toList();
  }

  @override
  Future<List<FailReason>> fetchFailReasonsAsync() async {
    final JsonMap body = await _client.getAsync(ApiEndpoints.failReasons);
    final Object? rows = body['results'];
    _failReasons = rows is List
        ? rows.whereType<JsonMap>().map(DeliveryMapper.toFailReason).toList()
        : const <FailReason>[];
    return _failReasons;
  }

  @override
  Future<bool> fetchIsOnLeaveAsync() async {
    final JsonMap profile = await _client.getAsync(
      ApiEndpoints.myDeliveryProfile,
    );
    return profile['availability_status'] == _offline;
  }

  @override
  Future<void> startTripAsync(List<DeliveryStop> route) async {
    await _arrangeAsync(route);
    for (final DeliveryStop stop in route) {
      if (_statusOf(stop) == DeliveryStatus.assigned) {
        await _moveAsync(stop, DeliveryStatus.atPickup);
      }
      if (_statusOf(stop) == DeliveryStatus.atPickup) {
        await _moveAsync(stop, DeliveryStatus.pickedUp);
      }
    }
    if (route.isNotEmpty) {
      await markOutForDeliveryAsync(route.first);
    }
  }

  @override
  Future<void> markOutForDeliveryAsync(DeliveryStop stop) async {
    if (_statusOf(stop) != DeliveryStatus.outForDelivery) {
      await _moveAsync(stop, DeliveryStatus.outForDelivery);
    }
  }

  @override
  Future<void> markArrivedAsync(DeliveryStop stop) async {}

  @override
  Future<void> markDeliveredAsync(
    DeliveryStop stop, {
    required bool cashCollected,
  }) => _moveAsync(
    stop,
    DeliveryStatus.delivered,
    extra: <String, dynamic>{
      if (stop.paymentMode == PaymentMode.cod && cashCollected)
        'cash_collected': stop.cashDue,
    },
  );

  @override
  Future<void> markFailedAsync(DeliveryStop stop, String reasonId) {
    FailReason? reason;
    for (final FailReason r in _failReasons) {
      if (r.id == reasonId) {
        reason = r;
      }
    }
    return _moveAsync(
      stop,
      DeliveryStatus.failed,
      extra: <String, dynamic>{
        'fail_reason': reasonId,
        // The fail sheet has no text box; `other` needs a note, so the
        // reason's label is sent as the note.
        if (reason?.requiresNotes ?? false) 'notes': reason?.label,
      },
    );
  }

  @override
  Future<void> setOnLeaveAsync({required bool onLeave}) => _client.patchAsync(
    ApiEndpoints.myDeliveryProfile,
    data: <String, dynamic>{
      'availability_status': onLeave ? _offline : _online,
    },
  );

  @override
  Future<void> pushLocationAsync(GeoPosition position) async {
    try {
      await _client.postAsync(
        ApiEndpoints.myLocation,
        data: _locationBody(position, withTime: _sendRecordedAt),
      );
    } on ServerFailure catch (failure) {
      if (!_sendRecordedAt || failure.statusCode != _badRequest) {
        rethrow;
      }
      AppLogger.log('Fix time rejected; sending points without it');
      _sendRecordedAt = false;
      await _client.postAsync(
        ApiEndpoints.myLocation,
        data: _locationBody(position, withTime: false),
      );
    }
  }

  @override
  Future<TripWrapUp> fetchTripWrapUpAsync() async {
    final String tripId = _tripId;
    final List<JsonMap> parts = await Future.wait<JsonMap>(<Future<JsonMap>>[
      if (tripId.isEmpty)
        Future<JsonMap>.value(const <String, dynamic>{})
      else
        _getOrEmptyAsync(ApiEndpoints.trip(tripId)),
      _getOrEmptyAsync(ApiEndpoints.cashSummary),
    ]);
    return DeliveryMapper.toWrapUp(trip: parts[0], cash: parts[1]);
  }

  static const int _badRequest = 400;

  static JsonMap _locationBody(GeoPosition p, {required bool withTime}) {
    final DateTime? at = p.recordedAt;
    final double? accuracy = p.accuracyM;
    final double? speed = p.speedMps;
    final double? heading = p.heading;
    return <String, dynamic>{
      'latitude': p.latitude,
      'longitude': p.longitude,
      if (withTime && at != null) 'recorded_at': _isoWithOffset(at),
      if (accuracy != null && accuracy <= _maxAccuracyM) 'accuracy_m': accuracy,
      if (speed != null && speed <= _maxSpeedMps) 'speed_mps': speed,
      if (heading != null && heading <= _maxHeading) 'heading': heading,
    };
  }

  /// ISO-8601 in UTC with an explicit `+00:00` offset, as the API requires.
  static String _isoWithOffset(DateTime time) {
    final String utc = time.toUtc().toIso8601String();
    return utc.endsWith('Z')
        ? '${utc.substring(0, utc.length - 1)}+00:00'
        : utc;
  }

  // Trip Complete still shows the app's own figures when a part fails.
  Future<JsonMap> _getOrEmptyAsync(String path) async {
    try {
      return await _client.getAsync(path);
    } on Failure catch (failure) {
      AppLogger.log('Trip wrap-up part unavailable', error: failure);
      return const <String, dynamic>{};
    }
  }

  /// Saves the stop order. The server needs every active stop of the open
  /// trip exactly once, so stops left at the warehouse go last. A failure
  /// is logged, not thrown: the order only matters after a restart, and
  /// must never block the trip.
  Future<void> _arrangeAsync(List<DeliveryStop> route) async {
    final List<String> ids = <String>[
      for (final DeliveryStop stop in route) stop.deliveryId,
      for (final MapEntry<String, String> entry in _serverStatus.entries)
        if (DeliveryStatus.active.contains(entry.value) &&
            !route.any((DeliveryStop s) => s.deliveryId == entry.key))
          entry.key,
    ];
    final List<int> numeric = ids.map(int.tryParse).whereType<int>().toList();
    if (_tripId.isEmpty || numeric.length != ids.length || ids.length < 2) {
      return;
    }
    try {
      await _client.postAsync(
        ApiEndpoints.arrange,
        data: <String, dynamic>{'delivery_ids': numeric},
      );
    } on Failure catch (failure) {
      AppLogger.log('Stop order not saved', error: failure);
    }
  }

  String? _statusOf(DeliveryStop stop) => _serverStatus[stop.deliveryId];

  Future<void> _moveAsync(
    DeliveryStop stop,
    String status, {
    JsonMap extra = const <String, dynamic>{},
  }) async {
    final JsonMap updated = await _client.patchAsync(
      ApiEndpoints.delivery(stop.deliveryId),
      data: <String, dynamic>{_statusField: status, ...extra},
    );
    _serverStatus[stop.deliveryId] =
        updated[_statusField]?.toString() ?? status;
    final Object? tripId = updated[_tripIdField];
    if (tripId != null) {
      _tripId = tripId.toString();
    }
  }
}
