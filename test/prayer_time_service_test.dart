import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:islami_app_noorify/features/home/data/services/prayer_time_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('loads and caches the complete Karachi Hanafi schedule', () async {
    late Uri requestedUri;
    final client = MockClient((request) async {
      requestedUri = request.url;
      return http.Response(jsonEncode(_validResponse), 200);
    });
    final preferences = await SharedPreferences.getInstance();
    final service = AladhanPrayerTimeService(
      client: client,
      preferences: preferences,
    );

    final times = await service.loadPrayerTimes(DateTime(2026, 8, 20));

    expect(times, isNotNull);
    expect(times!.dateKey, '2026-08-20');
    expect(times.readableDate, '20 Aug 2026');
    expect(times.hijriDate, '7 Safar 1448 Hijri');
    expect(times.fajr.totalMinutes, 263);
    expect(times.sunrise.totalMinutes, 340);
    expect(times.dhuhr.totalMinutes, 728);
    expect(times.asr.totalMinutes, 992);
    expect(times.maghrib.totalMinutes, 1115);
    expect(times.sunset.totalMinutes, 1115);
    expect(times.isha.totalMinutes, 1195);
    expect(requestedUri.path, '/v1/timingsByCity/20-08-2026');
    expect(requestedUri.queryParameters['city'], 'Mymensingh');
    expect(requestedUri.queryParameters['country'], 'Bangladesh');
    expect(requestedUri.queryParameters['method'], '1');
    expect(requestedUri.queryParameters['school'], '1');
    expect(preferences.getString('prayer_times_date'), '2026-08-20');
    expect(preferences.getString('prayer_times_json'), isNotEmpty);
  });

  test('round-trips a complete same-day cached schedule', () async {
    final preferences = await SharedPreferences.getInstance();
    final online = AladhanPrayerTimeService(
      client: MockClient(
        (_) async => http.Response(jsonEncode(_validResponse), 200),
      ),
      preferences: preferences,
    );
    await online.loadPrayerTimes(DateTime(2026, 8, 20));
    final offline = AladhanPrayerTimeService(
      client: MockClient((_) async => http.Response('unavailable', 503)),
      preferences: preferences,
    );

    final cached = offline.cachedPrayerTimes(DateTime(2026, 8, 20));
    final loaded = await offline.loadPrayerTimes(DateTime(2026, 8, 20));

    expect(cached?.hijriDate, '7 Safar 1448 Hijri');
    expect(cached?.isha.totalMinutes, 1195);
    expect(loaded?.dhuhr.totalMinutes, 728);
  });

  test('rejects stale cached schedules', () async {
    SharedPreferences.setMockInitialValues({
      'prayer_times_date': '2026-08-19',
      'prayer_times_json': '{}',
    });
    final preferences = await SharedPreferences.getInstance();
    final service = AladhanPrayerTimeService(
      client: MockClient((_) async => http.Response('unavailable', 503)),
      preferences: preferences,
    );

    expect(service.cachedPrayerTimes(DateTime(2026, 8, 20)), isNull);
    expect(await service.loadPrayerTimes(DateTime(2026, 8, 20)), isNull);
  });

  test('rejects a response missing a required prayer time', () async {
    final malformed =
        jsonDecode(jsonEncode(_validResponse)) as Map<String, dynamic>;
    final data = malformed['data'] as Map<String, dynamic>;
    final timings = data['timings'] as Map<String, dynamic>;
    timings.remove('Isha');
    final preferences = await SharedPreferences.getInstance();
    final service = AladhanPrayerTimeService(
      client: MockClient(
        (_) async => http.Response(jsonEncode(malformed), 200),
      ),
      preferences: preferences,
    );

    expect(await service.loadPrayerTimes(DateTime(2026, 8, 20)), isNull);
  });
}

const _validResponse = {
  'code': 200,
  'data': {
    'timings': {
      'Fajr': '04:23 (+06)',
      'Sunrise': '05:40 (+06)',
      'Dhuhr': '12:08 (+06)',
      'Asr': '16:32 (+06)',
      'Maghrib': '18:35 (+06)',
      'Sunset': '18:35 (+06)',
      'Isha': '19:55 (+06)',
    },
    'date': {
      'readable': '20 Aug 2026',
      'gregorian': {'date': '20-08-2026'},
      'hijri': {
        'day': '07',
        'year': '1448',
        'month': {'en': 'Safar'},
      },
    },
  },
};
