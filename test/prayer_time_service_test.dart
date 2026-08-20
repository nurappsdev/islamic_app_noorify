import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:islami_app_noorify/features/home/data/services/prayer_time_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('requests Karachi Hanafi timings and caches parsed Fajr', () async {
    late Uri requestedUri;
    final client = MockClient((request) async {
      requestedUri = request.url;
      return http.Response(
        jsonEncode({
          'code': 200,
          'data': {
            'timings': {'Fajr': '04:23 (+06)'},
          },
        }),
        200,
      );
    });
    final preferences = await SharedPreferences.getInstance();
    final service = AladhanPrayerTimeService(
      client: client,
      preferences: preferences,
    );

    final fajr = await service.loadFajr(DateTime(2026, 8, 20));

    expect((fajr.hour, fajr.minute), (4, 23));
    expect(requestedUri.path, '/v1/timingsByCity/20-08-2026');
    expect(requestedUri.queryParameters['city'], 'Mymensingh');
    expect(requestedUri.queryParameters['country'], 'Bangladesh');
    expect(requestedUri.queryParameters['method'], '1');
    expect(requestedUri.queryParameters['school'], '1');
    expect(preferences.getString('fajr_date'), '2026-08-20');
    expect(preferences.getInt('fajr_minutes'), 263);
  });

  test('returns same-day cache when the request fails', () async {
    SharedPreferences.setMockInitialValues({
      'fajr_date': '2026-08-20',
      'fajr_minutes': 263,
    });
    final preferences = await SharedPreferences.getInstance();
    final service = AladhanPrayerTimeService(
      client: MockClient((_) async => http.Response('unavailable', 503)),
      preferences: preferences,
    );

    expect(service.cachedFajr(DateTime(2026, 8, 20))?.totalMinutes, 263);
    final fajr = await service.loadFajr(DateTime(2026, 8, 20));

    expect((fajr.hour, fajr.minute), (4, 23));
  });

  test('ignores stale cache and falls back to 5 AM', () async {
    SharedPreferences.setMockInitialValues({
      'fajr_date': '2026-08-19',
      'fajr_minutes': 263,
    });
    final preferences = await SharedPreferences.getInstance();
    final service = AladhanPrayerTimeService(
      client: MockClient((_) async => http.Response('{"code": 500}', 200)),
      preferences: preferences,
    );

    expect(service.cachedFajr(DateTime(2026, 8, 20)), isNull);
    final fajr = await service.loadFajr(DateTime(2026, 8, 20));

    expect((fajr.hour, fajr.minute), (5, 0));
  });

  test('falls back when AlAdhan returns malformed Fajr data', () async {
    final preferences = await SharedPreferences.getInstance();
    final service = AladhanPrayerTimeService(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'code': 200,
            'data': {
              'timings': {'Fajr': 'not-a-time'},
            },
          }),
          200,
        ),
      ),
      preferences: preferences,
    );

    final fajr = await service.loadFajr(DateTime(2026, 8, 20));

    expect((fajr.hour, fajr.minute), (5, 0));
  });
}
