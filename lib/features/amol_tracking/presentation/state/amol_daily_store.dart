import 'package:flutter/foundation.dart';

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
class AmolDailyStore extends ValueNotifier<AmolDailyDashboard?> {
  AmolDailyStore._() : super(null);

  static final instance = AmolDailyStore._();

  final _getDaily = GetAmolDaily(
    AmolTrackingRepositoryImpl(AmolTrackingRemoteDataSourceImpl()),
  );
  Future<void>? _inFlight;

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
  Future<void> load() =>
      _inFlight ??= _fetch().whenComplete(() => _inFlight = null);

  Future<void> _fetch() async {
    final now = DateTime.now();
    final date =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    try {
      final result = await _getDaily(date: date);
      result.fold((_) {}, (daily) => value = daily);
    } catch (_) {}
  }
}
