import 'package:flutter/foundation.dart';

import 'package:tuhfatul_muslim/features/quran/data/datasources/quran_reading_local_data_source.dart';

/// Quran reports currently represented in the local Amol projection.
///
/// A delivered report remains visible until the next daily Amol response is
/// received, preventing stale server data from briefly resetting the UI.
class QuranOfflineReadingProgressStore extends ChangeNotifier {
  QuranOfflineReadingProgressStore(this._local);

  static final shared = QuranOfflineReadingProgressStore(
    QuranReadingLocalDataSourceImpl(),
  );

  final QuranReadingLocalDataSource _local;
  final _readings = <String, _VisibleReading>{};
  Future<void>? _restore;

  Future<void> restore() => _restore ??= _restorePending();

  Future<void> _restorePending() async {
    try {
      for (final reading in await _local.pending()) {
        // A live save or sync may settle this id while storage is loading.
        // Never overwrite that newer in-memory state with this snapshot.
        _readings.putIfAbsent(
          reading.id,
          () => _VisibleReading(reading: reading),
        );
      }
      notifyListeners();
    } catch (_) {
      // A temporary storage failure must not block Quran reading.
    }
  }

  void upsert(PendingQuranReading reading) {
    _readings[reading.id] = _VisibleReading(reading: reading);
    notifyListeners();
  }

  void markAcknowledged(PendingQuranReading reading) {
    _readings[reading.id] = _VisibleReading(
      reading: reading.copyWith(draft: false),
      acknowledged: true,
    );
    notifyListeners();
  }

  void remove(String id) {
    if (_readings.remove(id) != null) notifyListeners();
  }

  void clear() {
    if (_readings.isEmpty) return;
    _readings.clear();
    notifyListeners();
  }

  Set<String> acknowledgedIdsFor(String date) => {
    for (final entry in _readings.entries)
      if (entry.value.acknowledged && entry.value.reading.date == date)
        entry.key,
  };

  QuranOfflineReadingProgress progressFor(
    String date, {
    Set<String> acknowledgedInBaseline = const {},
  }) {
    var seconds = 0;
    var points = 0;
    var hasAcknowledged = false;
    for (final entry in _readings.values) {
      if (entry.reading.date != date) continue;
      if (entry.acknowledged &&
          acknowledgedInBaseline.contains(entry.reading.id)) {
        continue;
      }
      seconds += entry.reading.seconds;
      points += entry.reading.points;
      hasAcknowledged = hasAcknowledged || entry.acknowledged;
    }
    return QuranOfflineReadingProgress(
      seconds: seconds,
      points: points,
      hasAcknowledged: hasAcknowledged,
    );
  }
}

class QuranOfflineReadingProgress {
  const QuranOfflineReadingProgress({
    required this.seconds,
    required this.points,
    required this.hasAcknowledged,
  });

  final int seconds;

  /// Persisted per report. Projection arithmetic uses [seconds] as sessions
  /// can span a five-minute boundary together.
  final int points;
  final bool hasAcknowledged;
}

class _VisibleReading {
  const _VisibleReading({required this.reading, this.acknowledged = false});

  final PendingQuranReading reading;
  final bool acknowledged;
}
