import 'package:hive/hive.dart';

import 'package:islami_app_noorify/core/storage/hive_service.dart';
import 'package:islami_app_noorify/features/asma_husna/data/models/asma_name_model.dart';

/// Hive-backed cache of the full 99-name list — one entry per name, each
/// carrying its full explanation. Populated once from `GET /asma-ul-husna`
/// and read back on every later visit so the feature never needs the
/// network again (see `AsmaHusnaRepositoryImpl`).
abstract interface class AsmaHusnaLocalDataSource {
  /// The cached names sorted by `displayOrder`, or `null` if nothing
  /// complete is cached yet — never synced, only partially written (e.g.
  /// the app was killed mid-write), or corrupted. Never throws.
  Future<List<AsmaNameModel>?> getCachedNames();

  /// Replaces the entire cache with [names]. Best-effort: a write failure
  /// is swallowed so it never turns an otherwise-successful API fetch into
  /// an error — the next visit just falls back to the API again.
  Future<void> cacheNames(List<AsmaNameModel> names);
}

class AsmaHusnaLocalDataSourceImpl implements AsmaHusnaLocalDataSource {
  AsmaHusnaLocalDataSourceImpl({Box<dynamic>? box})
    : _box = box ?? HiveService.asmaHusna;

  final Box<dynamic> _box;

  /// The catalog is a fixed 99 entries (see `AsmaHusnaRemoteDataSource`) —
  /// fewer than that means the cache was never finished and should be
  /// treated as absent so [getCachedNames] triggers a fresh fetch.
  static const _expectedCount = 99;

  @override
  Future<List<AsmaNameModel>?> getCachedNames() async {
    try {
      final names = _box.values
          .whereType<Map>()
          .map((raw) => AsmaNameModel.fromJson(Map<String, dynamic>.from(raw)))
          .toList();
      final isComplete =
          names.length >= _expectedCount &&
          names.every(
            (n) =>
                n.id.isNotEmpty &&
                n.nameArabic.isNotEmpty &&
                n.nameTransliteration.isNotEmpty,
          );
      if (!isComplete) return null;
      names.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      return names;
    } catch (_) {
      // Corrupted cache (unreadable entry, unexpected shape, ...) — treat
      // as absent rather than surfacing an error the user can't act on.
      return null;
    }
  }

  @override
  Future<void> cacheNames(List<AsmaNameModel> names) async {
    try {
      await _box.clear();
      await _box.putAll({for (final n in names) n.id: n.toJson()});
    } catch (_) {
      // Best-effort — see the class doc.
    }
  }
}
