import 'package:flutter/foundation.dart';

import 'package:tuhfatul_muslim/core/storage/hive_service.dart';
import 'package:tuhfatul_muslim/features/zikr/data/zikr_catalog.dart';

/// Hive-backed progress for the Home Screen's Zikr section (Prayer Zikr 1 &
/// 2 only — see [ZikrCatalog.trackedKeys]).
///
/// A singleton [ValueNotifier] so the Zikr dashboard and the tap-to-count
/// screen share one in-memory copy and rebuild immediately on every change
/// (the same pattern the Amol tracker's daily store uses). [HiveService] is
/// the single source of truth: counts, the latest zikr performed, and resets
/// all persist there, so they survive an app restart without any backend
/// call.
class ZikrProgressStore extends ValueNotifier<Map<String, int>> {
  ZikrProgressStore._() : super(_readAll());

  static final instance = ZikrProgressStore._();

  static const _latestKeyField = 'latestKey';
  static const _latestAtField = 'latestAt';

  static Map<String, int> _readAll() {
    final box = HiveService.zikr;
    return {
      for (final key in ZikrCatalog.trackedKeys)
        key: (box.get(key) as int?) ?? 0,
    };
  }

  /// Current count for [trackingKey], 0 if never counted.
  int countOf(String trackingKey) => value[trackingKey] ?? 0;

  /// Sum of every tracked counter (Prayer Zikr 1 + Prayer Zikr 2).
  int get totalCount => value.values.fold(0, (sum, c) => sum + c);

  /// The [ZikrItem.trackingKey] of the most recently performed zikr, or
  /// `null` if none has been counted yet.
  String? get latestKey => HiveService.zikr.get(_latestKeyField) as String?;

  /// When the latest zikr was performed, or `null`.
  DateTime? get latestAt {
    final millis = HiveService.zikr.get(_latestAtField) as int?;
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  /// Taps [trackingKey] once, clamped at [target]. No-op once the target is
  /// already reached. Persists to Hive and notifies every listener.
  void increment(String trackingKey, int target) {
    final current = countOf(trackingKey);
    if (current >= target) return;
    final next = current + 1;
    final box = HiveService.zikr;
    box.put(trackingKey, next);
    box.put(_latestKeyField, trackingKey);
    box.put(_latestAtField, DateTime.now().millisecondsSinceEpoch);
    value = {...value, trackingKey: next};
  }

  /// Resets every key in [trackingKeys] back to 0 (a Prayer Zikr's "Reset").
  void resetAll(Iterable<String> trackingKeys) {
    final box = HiveService.zikr;
    final next = {...value};
    for (final key in trackingKeys) {
      box.put(key, 0);
      next[key] = 0;
    }
    value = next;
  }
}
