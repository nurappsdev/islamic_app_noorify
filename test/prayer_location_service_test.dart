import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tuhfatul_muslim/features/home/data/services/prayer_location_service.dart';
import 'package:tuhfatul_muslim/features/home/domain/prayer_location.dart';

void main() {
  test('resolves upazila, district, division, and country from GPS', () async {
    final service = PrayerLocationService(
      isServiceEnabled: () async => true,
      checkPermission: () async => LocationPermission.whileInUse,
      currentPosition: () async => _position(),
      positionStream: (_) => const Stream.empty(),
      reverseGeocode: (_, _) async => [
        Placemark(
          locality: 'Bhaluka',
          subAdministrativeArea: 'Mymensingh',
          administrativeArea: 'Mymensingh Division',
          country: 'Bangladesh',
        ),
      ],
    );

    await service.start();

    expect(service.state.status, PrayerLocationStatus.ready);
    expect(
      service.state.location?.displayName,
      'Bhaluka, Mymensingh, Bangladesh',
    );
    expect(
      service.state.location?.districtCountryDisplayName,
      'Mymensingh, Bangladesh',
    );
  });

  test('reports denied permission without a default location', () async {
    final service = PrayerLocationService(
      isServiceEnabled: () async => true,
      checkPermission: () async => LocationPermission.denied,
      requestPermission: () async => LocationPermission.denied,
      positionStream: (_) => const Stream.empty(),
    );

    await service.start();

    expect(service.state.status, PrayerLocationStatus.permissionDenied);
    expect(service.state.location, isNull);
  });

  test('reports unavailable when a device position cannot be read', () async {
    final service = PrayerLocationService(
      isServiceEnabled: () async => true,
      checkPermission: () async => LocationPermission.whileInUse,
      currentPosition: () async => throw StateError('No GPS fix'),
      positionStream: (_) => const Stream.empty(),
    );

    await service.start();

    expect(service.state.status, PrayerLocationStatus.unavailable);
    expect(service.state.location, isNull);
  });

  test('updates the district after meaningful device movement', () async {
    final positions = StreamController<Position>();
    addTearDown(positions.close);
    final service = PrayerLocationService(
      isServiceEnabled: () async => true,
      checkPermission: () async => LocationPermission.whileInUse,
      currentPosition: () async => _position(),
      positionStream: (_) => positions.stream,
      reverseGeocode: (latitude, _) async => [
        if (latitude < 25)
          Placemark(
            locality: 'Bhaluka',
            subAdministrativeArea: 'Mymensingh',
            country: 'Bangladesh',
          )
        else
          Placemark(
            locality: 'Noakhali',
            subAdministrativeArea: 'Noakhali',
            country: 'Bangladesh',
          ),
      ],
    );

    await service.start();
    positions.add(_positionAt(latitude: 25.1, longitude: 91.0));
    await Future<void>.delayed(Duration.zero);

    expect(
      service.state.location?.districtCountryDisplayName,
      'Noakhali, Bangladesh',
    );
    await service.stopMonitoring();
  });

  test(
    're-geocodes the district and country in the selected app language',
    () async {
      var bangla = false;
      final service = PrayerLocationService(
        isServiceEnabled: () async => true,
        checkPermission: () async => LocationPermission.whileInUse,
        currentPosition: () async => _position(),
        positionStream: (_) => const Stream.empty(),
        setGeocodingLocale: (locale) async => bangla = locale == 'bn_BD',
        reverseGeocode: (_, _) async => [
          Placemark(
            locality: bangla ? 'ময়মনসিংহ' : 'Bhaluka',
            subAdministrativeArea: bangla ? 'ময়মনসিংহ' : 'Mymensingh',
            country: bangla ? 'বাংলাদেশ' : 'Bangladesh',
          ),
        ],
      );

      await service.start();
      await service.setLocaleIdentifier('bn_BD');

      expect(
        service.state.location?.districtCountryDisplayName,
        'ময়মনসিংহ, বাংলাদেশ',
      );
    },
  );
}

Position _position() => Position(
  longitude: 90.4203,
  latitude: 24.7483,
  timestamp: DateTime(2026, 10, 8),
  accuracy: 5,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
  isMocked: false,
);

Position _positionAt({required double latitude, required double longitude}) =>
    Position(
      longitude: longitude,
      latitude: latitude,
      timestamp: DateTime(2026, 10, 8),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
      isMocked: false,
    );
