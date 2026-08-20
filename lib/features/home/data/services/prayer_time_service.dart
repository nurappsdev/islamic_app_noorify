import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:islami_app_noorify/features/home/domain/prayer_theme_schedule.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class PrayerTimeService {
  PrayerClockTime? cachedFajr(DateTime date);

  Future<PrayerClockTime> loadFajr(DateTime date);
}

class AladhanPrayerTimeService implements PrayerTimeService {
  factory AladhanPrayerTimeService({
    required http.Client client,
    required SharedPreferences preferences,
  }) {
    return AladhanPrayerTimeService._(client, preferences);
  }

  AladhanPrayerTimeService._(this._client, this._preferences);

  static const _fallbackFajr = PrayerClockTime(hour: 5, minute: 0);
  static const _cacheDateKey = 'fajr_date';
  static const _cacheMinutesKey = 'fajr_minutes';

  final http.Client _client;
  final SharedPreferences _preferences;

  static Future<AladhanPrayerTimeService> create() async {
    return AladhanPrayerTimeService(
      client: http.Client(),
      preferences: await SharedPreferences.getInstance(),
    );
  }

  @override
  Future<PrayerClockTime> loadFajr(DateTime date) async {
    try {
      final uri = Uri.https(
        'api.aladhan.com',
        '/v1/timingsByCity/${_apiDate(date)}',
        const {
          'city': 'Mymensingh',
          'country': 'Bangladesh',
          'method': '1',
          'school': '1',
        },
      );
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) throw const FormatException();

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['code'] != 200) throw const FormatException();
      final data = body['data'] as Map<String, dynamic>;
      final timings = data['timings'] as Map<String, dynamic>;
      final fajr = _parseFajr(timings['Fajr']);

      await _preferences.setString(_cacheDateKey, _cacheDate(date));
      await _preferences.setInt(_cacheMinutesKey, fajr.totalMinutes);
      return fajr;
    } catch (_) {
      return cachedFajr(date) ?? _fallbackFajr;
    }
  }

  @override
  PrayerClockTime? cachedFajr(DateTime date) {
    if (_preferences.getString(_cacheDateKey) != _cacheDate(date)) {
      return null;
    }
    final minutes = _preferences.getInt(_cacheMinutesKey);
    if (minutes == null || minutes < 0 || minutes >= 24 * 60) return null;
    return PrayerClockTime(hour: minutes ~/ 60, minute: minutes % 60);
  }

  static PrayerClockTime _parseFajr(Object? value) {
    final match = RegExp(
      r'^(\d{2}):(\d{2})',
    ).firstMatch(value?.toString() ?? '');
    if (match == null) throw const FormatException();
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour > 23 || minute > 59) throw const FormatException();
    return PrayerClockTime(hour: hour, minute: minute);
  }

  static String _apiDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  static String _cacheDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

DateTime bangladeshNow() {
  return DateTime.now().toUtc().add(const Duration(hours: 6));
}
