import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:tuhfatul_muslim/core/storage/hive_service.dart';

/// The user's own order for the Home Screen feature grid tiles (Quran,
/// Hadith, Dua, Quiz, Zikr, Asma-ul-Husna), set by dragging one tile onto
/// another.
///
/// Device-local only: the order lives in Hive and is never sent to the
/// backend, so it survives a restart but does not follow the account to
/// another device. A singleton [ValueNotifier] (the same pattern
/// `ZikrProgressStore` uses) so every mounted grid rebuilds the moment a
/// drop lands.
///
/// Only ids are stored. An id that is no longer offered is ignored on read
/// and a newly added feature appears at the end, so shipping a different set
/// of tiles can never leave a saved order stale or crash on it.
class HomeFeatureOrderStore extends ValueNotifier<List<String>> {
  HomeFeatureOrderStore._() : super(_read());

  static final HomeFeatureOrderStore instance = HomeFeatureOrderStore._();

  static const _orderField = 'feature_grid_order';

  /// `null` before [HiveService.init] has run (widget tests, early frames):
  /// the store then simply keeps the default order in memory instead of
  /// throwing.
  static Box<dynamic>? get _box =>
      Hive.isBoxOpen(HiveService.homeLayoutBox) ? HiveService.homeLayout : null;

  static List<String> _read() {
    final raw = _box?.get(_orderField);
    if (raw is! List) return const <String>[];
    return raw.whereType<String>().toList();
  }

  /// True once the user has arranged the tiles themselves.
  bool get isCustomized => value.isNotEmpty;

  /// [defaultIds] rearranged into the saved order: saved ids first (in the
  /// order they were saved, minus any the app no longer offers), then every
  /// remaining default id in its declared order.
  List<String> ordered(List<String> defaultIds) {
    if (value.isEmpty) return List<String>.of(defaultIds);
    final result = [
      for (final id in value)
        if (defaultIds.contains(id)) id,
    ];
    for (final id in defaultIds) {
      if (!result.contains(id)) result.add(id);
    }
    return result;
  }

  /// Moves [id] into [targetId]'s slot — dropping Zikr on the 2nd tile makes
  /// Zikr the 2nd tile and pushes the rest down. Persists immediately.
  void moveTo({
    required String id,
    required String targetId,
    required List<String> defaultIds,
  }) {
    if (id == targetId) return;
    final next = ordered(defaultIds);
    final from = next.indexOf(id);
    final to = next.indexOf(targetId);
    if (from < 0 || to < 0) return;
    next.removeAt(from);
    next.insert(to, id);
    _box?.put(_orderField, next);
    value = next;
  }

  /// Back to the order the app ships with.
  void reset() {
    _box?.delete(_orderField);
    value = const <String>[];
  }
}
