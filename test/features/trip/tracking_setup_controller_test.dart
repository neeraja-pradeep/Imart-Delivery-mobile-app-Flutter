import 'package:flutter_test/flutter_test.dart';

import 'package:imart_delivery_app/features/trip/application/providers/tracking_setup_providers.dart';
import 'package:imart_delivery_app/features/trip/domain/entities/location_access.dart';
import 'package:imart_delivery_app/features/trip/infrastructure/data_sources/local/location_local_ds.dart';
import 'package:imart_delivery_app/features/trip/infrastructure/data_sources/local/tracking_permissions_local_ds.dart';

class _FakeLocation implements LocationLocalDs {
  _FakeLocation(this.access);

  LocationAccess access;
  int settingsOpened = 0;

  @override
  Future<LocationAccess> checkAccessAsync() async => access;

  @override
  Future<LocationAccess> requestAccessAsync() async => access;

  @override
  Future<void> openLocationSettingsAsync() async => settingsOpened++;

  @override
  Stream<GeoPosition> watchPositions() => const Stream<GeoPosition>.empty();
}

class _FakePermissions implements TrackingPermissionsLocalDs {
  _FakePermissions({required this.unrestricted, this.grantOnRequest = true});

  bool unrestricted;
  final bool grantOnRequest;
  int notificationRequests = 0;
  int settingsOpened = 0;

  @override
  Future<bool> isBatteryUnrestrictedAsync() async => unrestricted;

  @override
  Future<bool> requestBatteryUnrestrictedAsync() async =>
      unrestricted = grantOnRequest;

  @override
  Future<void> requestNotificationsAsync() async => notificationRequests++;

  @override
  Future<void> openAppSettingsAsync() async => settingsOpened++;
}

TrackingSetupController _controller(
  _FakeLocation location,
  _FakePermissions permissions, {
  bool enabled = true,
}) => TrackingSetupController(
  location: location,
  permissions: permissions,
  enabled: enabled,
);

void main() {
  test('ready only with location and the battery exemption', () async {
    final _FakePermissions permissions = _FakePermissions(unrestricted: false);
    final TrackingSetupController setup = _controller(
      _FakeLocation(LocationAccess.granted),
      permissions,
    );
    expect(await setup.prepareAsync(), isFalse);
    expect(permissions.notificationRequests, 1);

    await setup.allowUnrestrictedAsync();
    expect(setup.state.isReady, isTrue);
  });

  test('refusing the battery dialog keeps the trip blocked', () async {
    final TrackingSetupController setup = _controller(
      _FakeLocation(LocationAccess.granted),
      _FakePermissions(unrestricted: false, grantOnRequest: false),
    );
    await setup.prepareAsync();
    await setup.allowUnrestrictedAsync();
    expect(setup.state.isReady, isFalse);
  });

  test('a change made in Settings is picked up on re-check', () async {
    final _FakePermissions permissions = _FakePermissions(unrestricted: false);
    final TrackingSetupController setup = _controller(
      _FakeLocation(LocationAccess.granted),
      permissions,
    );
    await setup.prepareAsync();
    await setup.openPhoneSettingsAsync();
    expect(permissions.settingsOpened, 1);
    expect(setup.state.isReady, isFalse);

    permissions.unrestricted = true; // rider chose "Unrestricted"
    expect(await setup.recheckAsync(), isTrue);
  });

  test('location denied blocks the trip until allowed', () async {
    final _FakePermissions permissions = _FakePermissions(unrestricted: true);
    final _FakeLocation location = _FakeLocation(LocationAccess.denied);
    final TrackingSetupController setup = _controller(location, permissions);
    expect(await setup.prepareAsync(), isFalse);
    expect(setup.state.locationReady, isFalse);
    expect(permissions.notificationRequests, 0);

    location.access = LocationAccess.granted;
    expect(await setup.recheckAsync(), isTrue);
  });

  test('blocked location opens app settings; GPS off opens location '
      'settings', () async {
    final _FakePermissions permissions = _FakePermissions(unrestricted: true);
    final TrackingSetupController blocked = _controller(
      _FakeLocation(LocationAccess.deniedForever),
      permissions,
    );
    await blocked.prepareAsync();
    await blocked.fixLocationAsync();
    expect(permissions.settingsOpened, 1);

    final _FakeLocation off = _FakeLocation(LocationAccess.serviceOff);
    final TrackingSetupController gpsOff = _controller(off, permissions);
    await gpsOff.prepareAsync();
    await gpsOff.fixLocationAsync();
    expect(off.settingsOpened, 1);
  });

  test('static data: always ready, nothing requested', () async {
    final _FakePermissions permissions = _FakePermissions(unrestricted: false);
    final TrackingSetupController setup = _controller(
      _FakeLocation(LocationAccess.denied),
      permissions,
      enabled: false,
    );
    expect(await setup.prepareAsync(), isTrue);
    expect(permissions.notificationRequests, 0);
  });
}
