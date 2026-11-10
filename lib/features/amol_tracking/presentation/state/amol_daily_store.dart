import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart' show BoxEvent;

import 'package:tuhfatul_muslim/core/storage/hive_service.dart';
import 'package:tuhfatul_muslim/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/data/datasources/amol_tracking_remote_data_source.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/data/repositories/amol_tracking_repository_impl.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/amol_local_projection.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_daily_dashboard.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_pillar.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/usecases/get_amol_daily.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/state/amol_day_clock.dart';
import 'package:tuhfatul_muslim/features/dua/data/services/dua_offline_reading_progress_store.dart';
import 'package:tuhfatul_muslim/features/quran/data/services/quran_offline_reading_progress_store.dart';

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
///
/// It belongs to one day just as strictly. The day is [AmolDayClock]'s, so
/// at midnight — app running or not — the previous day's checklist, its
/// progress and its points are dropped on the spot and the new day is
/// fetched from zero. Yesterday's numbers are never shown as today's, and
/// yesterday's own record is left untouched wherever it is kept.
class AmolDailyStore extends ValueNotifier<AmolDailyDashboard?> {
  AmolDailyStore._() : super(null) {
    _token = _currentToken();
    _activeDate = _dayClock.date;
    _dayClock.addListener(_onDayChanged);
    unawaited(_refreshTrackingDay());
    QuranOfflineReadingProgressStore.shared.addListener(_onOfflineQuranChanged);
    unawaited(QuranOfflineReadingProgressStore.shared.restore());
    DuaOfflineReadingProgressStore.shared.addListener(_onOfflineDuaChanged);
    unawaited(DuaOfflineReadingProgressStore.shared.restore());
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

  /// The last server snapshot. [value] may have pending Quran and dua
  /// reading projected over it, so future local updates must always start
  /// here.
  AmolDailyDashboard? _serverValue;
  final _quranAcknowledgedInServer = <String>{};
  final _duaAcknowledgedInServer = <String>{};

  /// The token the current [value] (or in-flight fetch) belongs to.
  String? _token;

  /// Bumped on every token change so a fetch started for the previous session
  /// can't land its result in the new one.
  int _session = 0;

  /// Bumped whenever the tracking date changes at midnight. It prevents a
  /// slow response for the prior cycle from restoring its checklist.
  int _dayGeneration = 0;
  late String _activeDate;

  /// The one clock the whole app rolls over by. Held for the app's lifetime:
  /// this store is a singleton and is never disposed.
  final AmolDayClock _dayClock = AmolDayClock.instance;
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
    _serverValue = null;
    _quranAcknowledgedInServer.clear();
    _duaAcknowledgedInServer.clear();
    QuranOfflineReadingProgressStore.shared.clear();
    DuaOfflineReadingProgressStore.shared.clear();
    value = null;
    if (token != null) load();
  }

  /// Clears only the active in-memory day. Server records for earlier dates,
  /// and this device's own stored days, are never changed or deleted.
  bool _activateDate(String date) {
    if (date == _activeDate) return false;
    _activeDate = date;
    _dayGeneration++;
    _inFlight = null;
    _serverValue = null;
    _quranAcknowledgedInServer.clear();
    _duaAcknowledgedInServer.clear();
    value = null;
    return true;
  }

  /// Midnight, while the app is running: the day on screen is closed and the
  /// new one is fetched from zero.
  void _onDayChanged() => unawaited(_refreshTrackingDay());

  Future<void> _refreshTrackingDay() async {
    if (_activateDate(_dayClock.date)) await _loadActiveDate();
  }

  /// The pillar with [pillarKey] in the latest load, or `null`.
  AmolPillar? pillar(String pillarKey) {
    for (final p in value?.pillars ?? const <AmolPillar>[]) {
      if (p.pillarKey == pillarKey) return p;
    }
    return null;
  }

  /// The day everything here belongs to, as `YYYY-MM-DD`.
  String get activeDate => _activeDate;

  /// Loads once if nothing has been loaded yet.
  Future<void> ensureLoaded() async {
    await _refreshTrackingDay();
    if (value == null) await load();
  }

  /// Fetches today's checklist. A failed fetch keeps the previous value —
  /// unless the day itself has changed, which drops it first.
  Future<void> load() {
    // Read the clock rather than trusting the last timer: a device that was
    // asleep at midnight asks for the day the user is actually living.
    _dayClock.refresh();
    _activateDate(_dayClock.date);
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
        if (daily.dateIso != date) return;
        _serverValue = daily;
        // This response is the authoritative baseline for reports the server
        // already accepted. Keep those reports in memory for other screens,
        // but no longer add them over this fresh daily value.
        _quranAcknowledgedInServer.addAll(
          QuranOfflineReadingProgressStore.shared.acknowledgedIdsFor(date),
        );
        _duaAcknowledgedInServer.addAll(
          DuaOfflineReadingProgressStore.shared.acknowledgedIdsFor(date),
        );
        _applyOfflineReadingProjection();
      });
    } catch (_) {}
  }

  void _onOfflineQuranChanged() {
    _applyOfflineReadingProjection();
    final acknowledged = QuranOfflineReadingProgressStore.shared
        .acknowledgedIdsFor(_activeDate);
    if (acknowledged.any((id) => !_quranAcknowledgedInServer.contains(id))) {
      unawaited(load());
    }
  }

  void _onOfflineDuaChanged() {
    _applyOfflineReadingProjection();
    final acknowledged = DuaOfflineReadingProgressStore.shared
        .acknowledgedIdsFor(_activeDate);
    if (acknowledged.any((id) => !_duaAcknowledgedInServer.contains(id))) {
      // The server has taken a dua report this baseline does not contain:
      // fetch the day again so its own arithmetic replaces this projection.
      unawaited(load());
    }
  }

  /// Both reading projections over the last server snapshot, never over an
  /// already projected value, so no minute is ever counted twice.
  void _applyOfflineReadingProjection() {
    final server = _serverValue;
    if (server == null || server.dateIso != _activeDate) return;
    final quran = QuranOfflineReadingProgressStore.shared.progressFor(
      _activeDate,
      acknowledgedInBaseline: _quranAcknowledgedInServer,
    );
    value = projectOfflineDuaReading(
      projectOfflineQuranReading(server, additionalSeconds: quran.seconds),
      additionalSeconds: DuaOfflineReadingProgressStore.shared.secondsFor(
        _activeDate,
        acknowledgedInBaseline: _duaAcknowledgedInServer,
      ),
    );
  }
}
