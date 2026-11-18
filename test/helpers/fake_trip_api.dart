import 'package:imart_delivery_app/features/trip/domain/entities/delivery_stop.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/fail_reason.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/geo_position.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/trip_wrap_up.dart';
import 'package:imart_delivery_app/features/trip/infrastructure/data_sources/remote/trip_api.dart';
import 'package:imart_delivery_app/features/trip/infrastructure/data_sources/remote/trip_static_api.dart';

/// Zero-latency [TripApi] for tests, seeded from the static fixtures and
/// recording every write.
class FakeTripApi implements TripApi {
  FakeTripApi({this.failFetch = false});

  final TripStaticApi _fixtures = TripStaticApi();
  bool failFetch;
  List<String>? startedWith;
  final List<String> delivered = <String>[];
  final Map<String, String> failed = <String, String>{};
  final List<bool> leaveCalls = <bool>[];
  final List<String> sentOut = <String>[];
  final List<GeoPosition> positions = <GeoPosition>[];
  TripWrapUp wrapUp = TripWrapUp.none;

  @override
  Future<List<DeliveryStop>> fetchAssignedStopsAsync() async {
    if (failFetch) {
      throw Exception('offline');
    }
    return servedStops ?? _stops;
  }

  /// Stops to serve instead of the fixtures (e.g. a trip mid-way).
  List<DeliveryStop>? servedStops;

  static List<DeliveryStop>? _cache;

  List<DeliveryStop> get _stops => _cache ?? const <DeliveryStop>[];

  /// Loads fixtures once (the static API simulates latency).
  static Future<void> warmUpAsync() async {
    _cache ??= await TripStaticApi().fetchAssignedStopsAsync();
  }

  @override
  Future<List<FailReason>> fetchFailReasonsAsync() =>
      _fixtures.fetchFailReasonsAsync();

  @override
  Future<bool> fetchIsOnLeaveAsync() async =>
      leaveCalls.isNotEmpty && leaveCalls.last;

  @override
  Future<void> startTripAsync(List<DeliveryStop> route) async =>
      startedWith = route.map((DeliveryStop s) => s.orderId).toList();

  @override
  Future<void> markOutForDeliveryAsync(DeliveryStop stop) async =>
      sentOut.add(stop.orderId);

  @override
  Future<void> markArrivedAsync(DeliveryStop stop) async {}

  @override
  Future<void> markDeliveredAsync(
    DeliveryStop stop, {
    required bool cashCollected,
  }) async => delivered.add(stop.orderId);

  @override
  Future<void> markFailedAsync(DeliveryStop stop, String reasonId) async =>
      failed[stop.orderId] = reasonId;

  @override
  Future<void> setOnLeaveAsync({required bool onLeave}) async =>
      leaveCalls.add(onLeave);

  @override
  Future<void> pushLocationAsync(GeoPosition position) async =>
      positions.add(position);

  @override
  Future<TripWrapUp> fetchTripWrapUpAsync() async => wrapUp;
}
