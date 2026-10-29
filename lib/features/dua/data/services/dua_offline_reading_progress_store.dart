import 'package:flutter/foundation.dart';

import 'package:tuhfatul_muslim/features/dua/data/datasources/dua_reading_local_data_source.dart';

/// Dua reading currently represented in the local Amol projection, so the
/// Dua point shows up the moment it is earned — offline included — instead
/// of only after the server has answered.
///
/// A delivered report stays visible until the next daily Amol response is
/// received, which keeps stale server data from briefly resetting the card.
class DuaOfflineReadingProgressStore extends ChangeNotifier {
  DuaOfflineReadingProgressStore(this._local);

  static final shared = DuaOfflineReadingProgressStore(
    DuaReadingLocalDataSourceImpl(),
  );

  final DuaReadingLocalDataSource _local;
  final _readings = <String, _VisibleReading>{};
  Future<void>? _restore;

  /// Loads what the previous launch left behind. Runs once.
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
      // A temporary storage failure must not block dua reading.
    }
  }

  void upsert(PendingDuaReading reading) {
    _readings[reading.id] = _VisibleReading(reading: reading);
    notifyListeners();
  }

  void markAcknowledged(PendingDuaReading reading) {
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

  /// The reports of [date] the server has already accepted. A caller holding
  /// a fresh daily response passes these back as [acknowledgedInBaseline],
  /// since that response already counts them.
  Set<String> acknowledgedIdsFor(String date) => {
    for (final entry in _readings.entries)
      if (entry.value.acknowledged && entry.value.reading.date == date)
        entry.key,
  };

  /// The seconds read on [date] that this device still holds on top of the
  /// server's own record.
  int secondsFor(String date, {Set<String> acknowledgedInBaseline = const {}}) {
    var seconds = 0;
    for (final entry in _readings.values) {
      if (entry.reading.date != date) continue;
      if (entry.acknowledged &&
          acknowledgedInBaseline.contains(entry.reading.id)) {
        continue;
      }
      seconds += entry.reading.seconds;
    }
    return seconds;
  }
}

class _VisibleReading {
  const _VisibleReading({required this.reading, this.acknowledged = false});

  final PendingDuaReading reading;
  final bool acknowledged;
}
