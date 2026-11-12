import 'package:imart_delivery_app/features/trip/domain/entities/delivery_stop.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/fail_reason.dart';
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

  @override
  Future<List<DeliveryStop>> fetchAssignedStopsAsync() async {
    if (failFetch) {
      throw Exception('offline');
    }
    return _stops;
  }

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
  Future<void> startTripAsync(List<String> orderedStopIds) async =>
      startedWith = orderedStopIds;

  @override
  Future<void> markArrivedAsync(String stopId) async {}

  @override
  Future<void> markDeliveredAsync(
    String stopId, {
    required bool cashCollected,
  }) async => delivered.add(stopId);

  @override
  Future<void> markFailedAsync(String stopId, String reasonId) async =>
      failed[stopId] = reasonId;

  @override
  Future<void> setOnLeaveAsync({required bool onLeave}) async =>
      leaveCalls.add(onLeave);
}
