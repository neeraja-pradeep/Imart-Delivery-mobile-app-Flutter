import 'package:flutter_test/flutter_test.dart';

import 'package:imart_delivery_app/core/network/api_client.dart';
import 'package:imart_delivery_app/features/profile/domain/entities/rider_profile.dart';
import 'package:imart_delivery_app/features/profile/domain/entities/trip_history_entry.dart';
import 'package:imart_delivery_app/features/profile/infrastructure/mappers/profile_mapper.dart';

void main() {
  test('builds the profile from both profile endpoints', () {
    final RiderProfile profile = ProfileMapper.toProfile(
      account: <String, dynamic>{
        'first_name': 'Ravi',
        'last_name': 'Kumar',
        'email': 'ravi.k@example.com',
        'phone_number': '+919876500001',
        'profile_photo': null,
      },
      deliveryProfile: <String, dynamic>{
        'vehicle_type': 'bike',
        'vehicle_number': 'KL07AB1234',
      },
      hubName: 'Kochi Central',
    );
    expect(profile.name, 'Ravi Kumar');
    expect(profile.vehicle, 'Bike · KL07AB1234');
    expect(profile.hubName, 'Kochi Central');
    expect(profile.avatarUrl, isNull);
  });

  group('parseVehicle', () {
    test('type label and number', () {
      final VehicleInput v = ProfileMapper.parseVehicle('Scooter · KL01X1');
      expect(v.type, 'scooter');
      expect(v.number, 'KL01X1');
    });

    test('free text is the number only', () {
      final VehicleInput v = ProfileMapper.parseVehicle(' KL07AB1234 ');
      expect(v.type, isNull);
      expect(v.number, 'KL07AB1234');
    });
  });

  test('account patch splits the full name', () {
    expect(
      ProfileMapper.toAccountPatch(name: 'Ravi  Kumar Nair', email: 'a@b.in'),
      <String, dynamic>{
        'first_name': 'Ravi',
        'last_name': 'Kumar Nair',
        'email': 'a@b.in',
      },
    );
  });

  test('history attempts group into one entry per day, newest first', () {
    final List<TripHistoryEntry> days = ProfileMapper.toHistory(<JsonMap>[
      <String, dynamic>{
        'outcome': 'delivered',
        'ended_at': '2026-11-12T06:00:00+00:00',
      },
      <String, dynamic>{
        'outcome': 'failed',
        'ended_at': '2026-11-13T06:00:00+00:00',
      },
      <String, dynamic>{
        'outcome': 'delivered',
        'ended_at': '2026-11-13T07:00:00+00:00',
      },
    ]);
    expect(days, hasLength(2));
    expect(days.first.stops, 2);
    expect(days.first.failed, 1);
    expect(days.first.delivered, 1);
    expect(days.last.stops, 1);
  });

  test('earnings summary days become history entries, newest first', () {
    final List<TripHistoryEntry> entries = ProfileMapper.toHistoryFromEarnings(
      <String, dynamic>{
        'by_day': <JsonMap>[
          <String, dynamic>{
            'date': '2026-11-08',
            'earned': '0.00',
            'delivered': 0,
            'failed': 0,
            'distance_km': 0.0,
          },
          <String, dynamic>{
            'date': '2026-11-13',
            'earned': '55.60',
            'delivered': 1,
            'failed': 0,
            'distance_km': 4.7,
          },
          <String, dynamic>{
            'date': '2026-11-14',
            'earned': '106.20',
            'delivered': 2,
            'failed': 1,
            'distance_km': 9.6,
          },
        ],
      },
    );
    expect(entries.length, 2);
    expect(entries.first.date, DateTime(2026, 11, 14));
    expect(entries.first.stops, 3);
    expect(entries.first.failed, 1);
    expect(entries.first.distanceKm, 9.6);
    expect(entries.first.earned, 106);
    expect(entries.last.earned, 56);
  });

  test('history attempts sum distance and earnings per day', () {
    final List<TripHistoryEntry> entries = ProfileMapper.toHistory(<JsonMap>[
      <String, dynamic>{
        'outcome': 'delivered',
        'ended_at': '2026-11-13T07:10:02+00:00',
        'distance_km': 4.7,
        'earned': '55.20',
      },
      <String, dynamic>{
        'outcome': 'failed',
        'ended_at': '2026-11-13T08:10:02+00:00',
        'distance_km': 3.1,
      },
    ]);
    expect(entries.single.distanceKm, closeTo(7.8, 0.001));
    expect(entries.single.earned, 55);
  });
}
