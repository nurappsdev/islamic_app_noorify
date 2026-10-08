import 'package:flutter/foundation.dart';

import 'package:tuhfatul_muslim/core/storage/hive_service.dart';
import 'package:tuhfatul_muslim/features/zikr/data/custom_zikr_model.dart';

/// Hive-backed store for the Home Screen's "My Created Zikr" list.
///
/// A singleton [ValueNotifier], the same pattern [ZikrProgressStore] uses for
/// Prayer Zikr 1 & 2: every listener (the dashboard's "My Created Zikr" card,
/// the tap-to-count screen) shares one in-memory copy and rebuilds
/// immediately on every create / count / reset. [HiveService.customZikr] is
/// the single source of truth, so the list and every zikr's progress survive
/// an app restart without any backend call.
class CustomZikrStore extends ValueNotifier<List<CustomZikrModel>> {
  CustomZikrStore._() : super(const []) {
    _ensureSeeded();
    value = _readAll();
  }

  static final instance = CustomZikrStore._();

  static const _seedSubhanAllah = 'seed-subhanAllah';
  static const _seedAlhamdulillah = 'seed-alhamdulillah';
  static const _seedAllahuAkbar = 'seed-allahuAkbar';

  /// Inserts the three default zikr (design mock: 33 / 33 / 34) the first
  /// time the box is ever opened. A no-op on every later launch.
  void _ensureSeeded() {
    final box = HiveService.customZikr;
    if (box.isNotEmpty) return;
    final now = DateTime.now();
    for (final seed in [
      (
        id: _seedSubhanAllah,
        nameKey: 'subhanAllah',
        name: 'Subhan Allah',
        arabic: 'سُبْحَانَ اللّٰه',
        transliteration: 'Subhāna-llāh',
        target: 33,
      ),
      (
        id: _seedAlhamdulillah,
        nameKey: 'alhamdulillah',
        name: 'Alhamdulillah',
        arabic: 'اَلْحَمْدُ لِلّٰه',
        transliteration: 'Al-ḥamdu li-llāh',
        target: 33,
      ),
      (
        id: _seedAllahuAkbar,
        nameKey: 'allahuAkbar',
        name: 'Allahu Akbar',
        arabic: 'اَللّٰهُ أَكْبَر',
        transliteration: 'Allāhu akbar',
        target: 34,
      ),
    ]) {
      box.put(
        seed.id,
        CustomZikrModel(
          id: seed.id,
          name: seed.name,
          arabic: seed.arabic,
          transliteration: seed.transliteration,
          target: seed.target,
          currentCount: 0,
          nameKey: seed.nameKey,
          createdAt: now,
        ).toMap(),
      );
    }
  }

  List<CustomZikrModel> _readAll() {
    final box = HiveService.customZikr;
    final items = [
      for (final key in box.keys)
        CustomZikrModel.fromMap(box.get(key) as Map<dynamic, dynamic>),
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return List.unmodifiable(items);
  }

  CustomZikrModel? byId(String id) {
    for (final item in value) {
      if (item.id == id) return item;
    }
    return null;
  }

  int countOf(String id) => byId(id)?.currentCount ?? 0;

  /// Creates a new custom zikr and persists it immediately. Returns the
  /// created model so the caller can open it (e.g. in `ZikrCounterScreen`)
  /// without waiting for the next [value] notification.
  CustomZikrModel create({
    required String name,
    String? nameKey,
    String arabic = '',
    String transliteration = '',
    required int target,
  }) {
    final model = CustomZikrModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      arabic: arabic,
      transliteration: transliteration,
      target: target < 1 ? 1 : target,
      currentCount: 0,
      nameKey: nameKey,
      createdAt: DateTime.now(),
    );
    HiveService.customZikr.put(model.id, model.toMap());
    value = _readAll();
    return model;
  }

  /// Taps [id] once, clamped at its target. No-op once already reached.
  void increment(String id) {
    final current = byId(id);
    if (current == null || current.currentCount >= current.target) return;
    final next = current.copyWith(
      currentCount: current.currentCount + 1,
      completed: current.currentCount + 1 >= current.target,
      lastPerformedAt: DateTime.now(),
    );
    HiveService.customZikr.put(id, next.toMap());
    value = _readAll();
  }

  /// Resets [id]'s progress back to 0.
  void reset(String id) {
    final current = byId(id);
    if (current == null) return;
    final next = current.copyWith(currentCount: 0, completed: false);
    HiveService.customZikr.put(id, next.toMap());
    value = _readAll();
  }
}
