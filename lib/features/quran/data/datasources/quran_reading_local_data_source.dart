import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:tuhfatul_muslim/core/errors/exceptions.dart';

/// One reading report not yet accepted by `POST /quran/reading/track`.
///
/// A [draft] is a session still being read, saved as it goes so a closed or
/// killed app does not lose it: it is sent once its session ends, or on the
/// next launch when the app never got to end it ([launch] is not the current
/// one).
class PendingQuranReading {
  const PendingQuranReading({
    required this.id,
    required this.surahNumber,
    required this.fromAyah,
    required this.toAyah,
    required this.seconds,
    required this.date,
    this.draft = false,
    this.launch = '',
    this.attempts = 0,
  });

  /// Stable for the whole session, so saving it again replaces it.
  final String id;
  final int surahNumber, fromAyah, toAyah, seconds;

  /// The local calendar day it was read (`YYYY-MM-DD`).
  final String date;
  final bool draft;

  /// The app launch that saved it.
  final String launch;

  /// Failed sends the server answered with an error, for giving up on one
  /// it keeps refusing.
  final int attempts;

  PendingQuranReading copyWith({bool? draft, int? attempts}) =>
      PendingQuranReading(
        id: id,
        surahNumber: surahNumber,
        fromAyah: fromAyah,
        toAyah: toAyah,
        seconds: seconds,
        date: date,
        draft: draft ?? this.draft,
        launch: launch,
        attempts: attempts ?? this.attempts,
      );

  Map<String, Object> toJson() => {
    'id': id,
    'surahNumber': surahNumber,
    'fromAyah': fromAyah,
    'toAyah': toAyah,
    'seconds': seconds,
    'date': date,
    'draft': draft,
    'launch': launch,
    'attempts': attempts,
  };

  static PendingQuranReading? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'], date = raw['date'];
    final numbers = [
      raw['surahNumber'],
      raw['fromAyah'],
      raw['toAyah'],
      raw['seconds'],
    ];
    if (id is! String || date is! String || numbers.any((n) => n is! int)) {
      return null;
    }
    return PendingQuranReading(
      id: id,
      surahNumber: numbers[0] as int,
      fromAyah: numbers[1] as int,
      toAyah: numbers[2] as int,
      seconds: numbers[3] as int,
      date: date,
      draft: raw['draft'] == true,
      launch: raw['launch'] is String ? raw['launch'] as String : '',
      attempts: raw['attempts'] is int ? raw['attempts'] as int : 0,
    );
  }
}

/// The Quran reading reports waiting on this device to be sent. Throws
/// [CacheException] when the device storage fails.
abstract interface class QuranReadingLocalDataSource {
  /// Oldest first.
  Future<List<PendingQuranReading>> pending();

  /// Adds [reading], or replaces the one with its id.
  Future<void> save(PendingQuranReading reading);

  Future<void> remove(String id);
}

/// Keeps the reports in SharedPreferences under [key], which
/// `SessionCleaner` clears on sign-out so no report reaches another account.
/// Changes run one at a time, so none is lost to another.
class QuranReadingLocalDataSourceImpl implements QuranReadingLocalDataSource {
  QuranReadingLocalDataSourceImpl({this.maxEntries = 1000});

  static const key = 'quran_reading_pending';

  /// Beyond this, the oldest reports are dropped (months of offline reading).
  final int maxEntries;

  Future<void> _queue = Future.value();

  Future<T> _locked<T>(Future<T> Function() run) {
    final result = _queue.then((_) => run());
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  @override
  Future<List<PendingQuranReading>> pending() => _locked(_read);

  @override
  Future<void> save(PendingQuranReading reading) => _locked(() async {
    final all = await _read();
    final at = all.indexWhere((r) => r.id == reading.id);
    if (at < 0) {
      all.add(reading);
    } else {
      all[at] = reading;
    }
    await _write(
      all.length > maxEntries ? all.sublist(all.length - maxEntries) : all,
    );
  });

  @override
  Future<void> remove(String id) => _locked(() async {
    final all = await _read();
    final before = all.length;
    all.removeWhere((r) => r.id == id);
    if (all.length != before) await _write(all);
  });

  Future<List<PendingQuranReading>> _read() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(key);
      if (raw == null) return [];
      final list = jsonDecode(raw);
      return [
        if (list is List)
          for (final entry in list) ?PendingQuranReading.tryParse(entry),
      ];
    } on FormatException {
      // Unreadable: start over rather than block every later report.
      return [];
    } catch (e) {
      throw CacheException('Could not read pending Quran reading: $e');
    }
  }

  Future<void> _write(List<PendingQuranReading> all) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ok = all.isEmpty
          ? await prefs.remove(key)
          : await prefs.setString(
              key,
              jsonEncode([for (final r in all) r.toJson()]),
            );
      if (!ok) throw CacheException('Pending Quran reading not saved.');
    } on CacheException {
      rethrow;
    } catch (e) {
      throw CacheException('Could not save pending Quran reading: $e');
    }
  }
}
