import 'package:imart_delivery_app/app/config/constants.dart';
import 'package:imart_delivery_app/core/error/failure.dart';
import 'package:imart_delivery_app/core/network/api_client.dart';
import 'package:imart_delivery_app/core/network/endpoints.dart';
import 'package:imart_delivery_app/core/utils/logger.dart';
import 'package:imart_delivery_app/features/profile/domain/entities/rider_profile.dart';
import 'package:imart_delivery_app/features/profile/domain/entities/trip_history_entry.dart';
import 'package:imart_delivery_app/features/profile/infrastructure/data_sources/remote/profile_api.dart';
import 'package:imart_delivery_app/features/profile/infrastructure/mappers/profile_mapper.dart';

/// [ProfileApi] backed by the iMart delivery-partner API.
///
/// Name, email, phone and photo live on the account profile; vehicle and
/// availability on the delivery profile. Phone is read-only for partners.
class ProfileRemoteApi implements ProfileApi {
  /// Creates the API over [client].
  const ProfileRemoteApi(this._client);

  final ApiClient _client;

  @override
  Future<RiderProfile> fetchProfileAsync() async {
    final List<Object> parts = await Future.wait<Object>(<Future<Object>>[
      _client.getAsync(ApiEndpoints.accountProfile),
      _client.getAsync(ApiEndpoints.myDeliveryProfile),
      _fetchHubNameAsync(),
    ]);
    return ProfileMapper.toProfile(
      account: parts[0] as JsonMap,
      deliveryProfile: parts[1] as JsonMap,
      hubName: parts[2] as String,
    );
  }

  @override
  Future<RiderProfile> updateProfileAsync(RiderProfile profile) async {
    final RiderProfile current = await fetchProfileAsync();
    if (profile.name != current.name || profile.email != current.email) {
      await _client.patchAsync(
        ApiEndpoints.accountProfile,
        data: ProfileMapper.toAccountPatch(
          name: profile.name,
          email: profile.email,
        ),
      );
    }
    if (profile.vehicle != current.vehicle) {
      final VehicleInput vehicle = ProfileMapper.parseVehicle(profile.vehicle);
      await _client.patchAsync(
        ApiEndpoints.myDeliveryProfile,
        data: <String, dynamic>{
          'vehicle_number': vehicle.number,
          if (vehicle.type != null) 'vehicle_type': vehicle.type,
        },
      );
    }
    if (profile.phone != current.phone) {
      AppLogger.log('Phone number is admin-managed; change not sent');
    }
    return fetchProfileAsync();
  }

  /// Per-day totals come from the earnings summary (10.2), which has the
  /// pay and km per day. If it fails (e.g. pay not set up on this server),
  /// the attempt history (4.8) is grouped by day instead.
  @override
  Future<List<TripHistoryEntry>> fetchTripHistoryAsync() async {
    final JsonMap query = <String, dynamic>{
      ApiParams.days: ApiConfig.historyDays,
    };
    try {
      final JsonMap summary = await _client.getAsync(
        ApiEndpoints.earningsSummary,
        query: query,
      );
      return ProfileMapper.toHistoryFromEarnings(summary);
    } on Failure catch (failure) {
      AppLogger.log('Earnings summary unavailable', error: failure);
    }
    final List<JsonMap> attempts = await _client.getAllPagesAsync(
      ApiEndpoints.deliveryHistory,
      query: query,
    );
    return ProfileMapper.toHistory(attempts);
  }

  // The partner's warehouse name comes from a delivery's pickup point; the
  // delivery profile only carries the warehouse id.
  Future<String> _fetchHubNameAsync() async {
    try {
      final JsonMap page = await _client.getAsync(ApiEndpoints.deliveries);
      final Object? results = page['results'];
      if (results is! List) {
        return '';
      }
      for (final Object? row in results) {
        final Object? points = row is JsonMap ? row['pickup_points'] : null;
        if (points is List && points.isNotEmpty && points.first is JsonMap) {
          final Object? name = (points.first as JsonMap)['name'];
          if (name is String) {
            return name;
          }
        }
      }
    } on Failure catch (failure) {
      AppLogger.log('Hub name unavailable', error: failure);
    }
    return '';
  }
}
