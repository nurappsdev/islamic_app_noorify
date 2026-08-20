import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:islami_app_noorify/features/home/domain/daily_prayer_times.dart';
import 'package:islami_app_noorify/features/home/domain/prayer_theme_schedule.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class PrayerTimeService {
  DailyPrayerTimes? cachedPrayerTimes(DateTime date);

  Future<DailyPrayerTimes?> loadPrayerTimes(DateTime date);
}

class AladhanPrayerTimeService implements PrayerTimeService {
  factory AladhanPrayerTimeService({
    required http.Client client,
    required SharedPreferences preferences,
  }) {
    return AladhanPrayerTimeService._(client, preferences);
  }

  AladhanPrayerTimeService._(this._client, this._preferences);

  static const _cacheDateKey = 'prayer_times_date';
  static const _cacheJsonKey = 'prayer_times_json';

  final http.Client _client;
  final SharedPreferences _preferences;

  static Future<AladhanPrayerTimeService> create() async {
    return AladhanPrayerTimeService(
      client: http.Client(),
      preferences: await SharedPreferences.getInstance(),
    );
  }

  @override
  Future<DailyPrayerTimes?> loadPrayerTimes(DateTime date) async {
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
      final times = _parseResponse(body);
      await _preferences.setString(_cacheDateKey, times.dateKey);
      await _preferences.setString(_cacheJsonKey, jsonEncode(times.toJson()));
      return times;
    } catch (_) {
      return cachedPrayerTimes(date);
    }
  }

  @override
  DailyPrayerTimes? cachedPrayerTimes(DateTime date) {
    if (_preferences.getString(_cacheDateKey) != _cacheDate(date)) return null;
    final cachedJson = _preferences.getString(_cacheJsonKey);
    if (cachedJson == null) return null;
    try {
      return DailyPrayerTimes.fromJson(
        jsonDecode(cachedJson) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  static DailyPrayerTimes _parseResponse(Map<String, dynamic> body) {
    final data = body['data'] as Map<String, dynamic>;
    final timings = data['timings'] as Map<String, dynamic>;
    final date = data['date'] as Map<String, dynamic>;
    final gregorian = date['gregorian'] as Map<String, dynamic>;
    final hijri = date['hijri'] as Map<String, dynamic>;
    final hijriMonth = hijri['month'] as Map<String, dynamic>;
    final readable = date['readable'];
    final gregorianDate = gregorian['date'];
    final hijriDay = hijri['day'];
    final hijriYear = hijri['year'];
    final hijriMonthName = hijriMonth['en'];
    if (readable is! String ||
        gregorianDate is! String ||
        hijriDay is! String ||
        hijriYear is! String ||
        hijriMonthName is! String) {
      throw const FormatException('Invalid prayer date');
    }
    final dateParts = gregorianDate.split('-');
    if (dateParts.length != 3) throw const FormatException('Invalid date');
    final normalizedHijriDay = int.parse(hijriDay).toString();
    return DailyPrayerTimes(
      dateKey: '${dateParts[2]}-${dateParts[1]}-${dateParts[0]}',
      readableDate: readable,
      hijriDate: '$normalizedHijriDay $hijriMonthName $hijriYear Hijri',
      fajr: _parseTime(timings['Fajr']),
      sunrise: _parseTime(timings['Sunrise']),
      dhuhr: _parseTime(timings['Dhuhr']),
      asr: _parseTime(timings['Asr']),
      maghrib: _parseTime(timings['Maghrib']),
      sunset: _parseTime(timings['Sunset']),
      isha: _parseTime(timings['Isha']),
    );
  }

  static PrayerClockTime _parseTime(Object? value) {
    final match = RegExp(
      r'^(\d{2}):(\d{2})',
    ).firstMatch(value?.toString() ?? '');
    if (match == null) throw const FormatException('Invalid prayer time');
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour > 23 || minute > 59) {
      throw const FormatException('Invalid prayer time');
    }
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
