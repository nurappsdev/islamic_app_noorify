import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart' show BoxEvent;

import 'package:islami_app_noorify/core/storage/hive_service.dart';
import 'package:islami_app_noorify/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:islami_app_noorify/features/amol_tracking/data/datasources/amol_tracking_remote_data_source.dart';
import 'package:islami_app_noorify/features/amol_tracking/data/repositories/amol_tracking_repository_impl.dart';
import 'package:islami_app_noorify/features/amol_tracking/domain/entities/amol_daily_dashboard.dart';
import 'package:islami_app_noorify/features/amol_tracking/domain/entities/amol_pillar.dart';
import 'package:islami_app_noorify/features/amol_tracking/domain/usecases/get_amol_daily.dart';

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
    try {
      _tokenWatch = HiveService.auth.watch().listen(
        (_) => _onAuthBoxChanged(),
      );
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

  /// The pillar with [pillarKey] in the latest load, or `null`.
  AmolPillar? pillar(String pillarKey) {
    for (final p in value?.pillars ?? const <AmolPillar>[]) {
      if (p.pillarKey == pillarKey) return p;
    }
    return null;
  }

  /// Loads once if nothing has been loaded yet.
  Future<void> ensureLoaded() => value == null ? load() : Future.value();

  /// Fetches today's checklist. A failed fetch keeps the previous value.
  Future<void> load() {
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
    final now = DateTime.now();
    final date =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    try {
      final result = await _getDaily(date: date);
      // Dropped if the user signed in/out while this was on the wire.
      if (session != _session) return;
      result.fold((_) {}, (daily) => value = daily);
    } catch (_) {}
  }
}
