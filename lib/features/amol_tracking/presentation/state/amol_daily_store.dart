import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart' show BoxEvent;

import 'package:tuhfatul_muslim/core/storage/hive_service.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/data/datasources/amol_tracking_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/data/repositories/amol_tracking_repository_impl.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/amol_tracking_day.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_daily_dashboard.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_pillar.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/usecases/get_amol_daily.dart';
import 'package:tuhfatul_muslim/features/home/data/services/prayer_time_service.dart';

/// Today's tracker checklist (`GET /amol/tracker/daily`), shared so the Home
/// cards read one copy instead of each fetching their own.
///
/// The Amol Tracking screen calls [load] after the user ticks or unticks
/// something, and every listening Home card updates from the new value.
///
/// The checklist belongs to whoever is signed in, so the store follows the
/// stored auth token: when it changes (sign-in, sign-out, another account) the
/// old checklist is dropped and, if a user is now signed in, today's is
/// fetched again. Without this the cards keep showing what was loaded as a
/// guest (or for the previous account) until the app is restarted.
class AmolDailyStore extends ValueNotifier<AmolDailyDashboard?> {
  AmolDailyStore._() : super(null) {
    _token = _currentToken();
    _activeDate = isoDate(DateTime.now());
    unawaited(_refreshTrackingDay());
    try {
      _tokenWatch = HiveService.auth.watch().listen((_) => _onAuthBoxChanged());
    } catch (_) {
      // Box not open (e.g. in a test): the store just doesn't follow sign-in.
    }
  }

  static final instance = AmolDailyStore._();

  final _getDaily = GetAmolDaily(
    AmolTrackingRepositoryImpl(AmolTrackingRemoteDataSourceImpl()),
  );
  Future<void>? _inFlight;

  /// The token the current [value] (or in-flight fetch) belongs to.
  String? _token;

  /// Bumped on every token change so a fetch started for the previous session
  /// can't land its result in the new one.
  int _session = 0;

  /// Bumped whenever the Fajr-to-Fajr tracking date changes. It prevents a
  /// slow response for the prior cycle from restoring its checklist.
  int _dayGeneration = 0;
  late String _activeDate;
  Timer? _boundaryTimer;
  // Held for the app's lifetime: the store is a singleton and is never disposed.
  // ignore: unused_field
  StreamSubscription<BoxEvent>? _tokenWatch;

  static String? _currentToken() {
    try {
      return AuthLocalDataSourceImpl().getToken();
    } catch (_) {
      return null;
    }
  }

  /// The auth box also holds the cached profile, so only a real token change
  /// counts.
  void _onAuthBoxChanged() {
    final token = _currentToken();
    if (token == _token) return;
    _token = token;
    _session++;
    _inFlight = null;
    // Nothing to show for a guest / signed-out user, and the old checklist must
    // not be shown to the next one while the fresh one loads.
    value = null;
    if (token != null) load();
  }

  /// The active API date, based on today's location-aware Fajr. When prayer
  /// times cannot be read, the civil date is used only as a temporary fallback
  /// until the next boundary check succeeds.
  Future<String> _resolveTrackingDate() async {
    final now = DateTime.now();
    try {
      final service = await AladhanPrayerTimeService.create();
      // Offline past the day the times were cached for, the last known Fajr
      // is still a far better answer than the civil date, which would move
      // the pre-Fajr hours onto the wrong record.
      final times =
          service.cachedPrayerTimes(now) ??
          await service.loadPrayerTimes(now) ??
          service.lastCachedPrayerTimes();
      if (times != null) return amolTrackingDateIso(now, times);
    } catch (_) {}
    return isoDate(now);
  }

  /// Clears only the active in-memory Fajr cycle. Server records for earlier
  /// dates are never changed or deleted.
  bool _activateDate(String date) {
    if (date == _activeDate) return false;
    _activeDate = date;
    _dayGeneration++;
    _inFlight = null;
    value = null;
    return true;
  }

  Future<void> _refreshTrackingDay() async {
    final date = await _resolveTrackingDate();
    final changed = _activateDate(date);
    if (changed) await _loadActiveDate();
    await _scheduleNextBoundary();
  }

  /// Re-evaluates exactly at Fajr. After a day's Fajr has passed, a midnight
  /// check obtains the following civil date's dynamic Fajr before scheduling
  /// that next Fajr boundary.
  Future<void> _scheduleNextBoundary() async {
    _boundaryTimer?.cancel();
    final now = DateTime.now();
    var next = now.add(const Duration(minutes: 1));
    try {
      final service = await AladhanPrayerTimeService.create();
      final times =
          service.cachedPrayerTimes(now) ??
          await service.loadPrayerTimes(now) ??
          service.lastCachedPrayerTimes();
      if (times != null) next = nextAmolTrackingCheck(now, times);
    } catch (_) {}
    _boundaryTimer = Timer(next.difference(now), () {
      unawaited(_refreshTrackingDay());
    });
  }

  /// The pillar with [pillarKey] in the latest load, or `null`.
  AmolPillar? pillar(String pillarKey) {
    for (final p in value?.pillars ?? const <AmolPillar>[]) {
      if (p.pillarKey == pillarKey) return p;
    }
    return null;
  }

  /// Loads once if nothing has been loaded yet.
  Future<void> ensureLoaded() async {
    await _refreshTrackingDay();
    if (value == null) await load();
  }

  /// Fetches today's checklist. A failed fetch keeps the previous value.
  Future<void> load() async {
    _activateDate(await _resolveTrackingDate());
    return _loadActiveDate();
  }

  Future<void> _loadActiveDate() {
    final existing = _inFlight;
    if (existing != null) return existing;
    late final Future<void> request;
    request = _fetch().whenComplete(() {
      // A newer session may already have started its own request.
      if (identical(_inFlight, request)) _inFlight = null;
    });
    return _inFlight = request;
  }

  Future<void> _fetch() async {
    final session = _session;
    final dayGeneration = _dayGeneration;
    final date = _activeDate;
    try {
      final result = await _getDaily(date: date);
      // Dropped if the user signed in/out while this was on the wire.
      if (session != _session || dayGeneration != _dayGeneration) return;
      result.fold((_) {}, (daily) {
        // Never show a response for another day (including an old offline
        // cache) as today's checklist.
        if (daily.dateIso == date) value = daily;
      });
    } catch (_) {}
  }
}
