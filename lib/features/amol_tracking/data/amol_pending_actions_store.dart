import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_pending_action.dart';

export 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_pending_action.dart';

/// The ticks and unticks waiting on this device to reach the server.
///
/// Survives the app being closed, so nothing the user did offline is lost.
/// Cleared on sign-out by `SessionCleaner`, so one account's unsent ticks can
/// never be credited to the next one.
///
/// Two guarantees the queue relies on:
///
/// * **One action per item per day.** A later action for the same
///   `logDate|pillarKey|itemKey` replaces the earlier one — only the user's
///   latest intent for that item on that day matters. The day is part of the
///   key: ticking Fajr tonight and again after tomorrow's Fajr are two
///   separate records, and collapsing them would silently drop a day.
/// * **One writer at a time.** Every change is a read-modify-write of a
///   single preferences entry, so they are serialized; two overlapping
///   changes can't lose one another.
class AmolPendingActionsStore {
  /// The one every repository uses unless a test injects its own, so the
  /// serialized writes below are serialized across the whole app.
  static final shared = AmolPendingActionsStore();

  static const key = 'offline_cache_amol_pending_actions';

  /// Beyond this many, the oldest are dropped (a very long offline stretch).
  static const _maxActions = 500;

  /// Older than this, an action is given up on: the day it belongs to is long
  /// past and it would otherwise sit in the queue forever.
  static const _maxAge = Duration(days: 60);

  /// How many server rejections an action survives before being dropped, so
  /// one the server keeps refusing can't block everything behind it.
  static const maxRejections = 3;

  Future<void> _lock = Future.value();

  /// Runs [action] after every change already queued, so writes never
  /// interleave.
  Future<T> _locked<T>(Future<T> Function() action) {
    final result = _lock.then((_) => action());
    _lock = result.then((_) {}, onError: (_) {});
    return result;
  }

  /// Everything waiting, oldest first.
  Future<List<PendingAmolAction>> load() => _locked(_read);

  /// Adds [action], or replaces the one already queued for the same item and
  /// day.
  Future<void> save(PendingAmolAction action) => _locked(() async {
    final all = await _read()
      ..removeWhere((a) => a.id == action.id)
      ..add(action);
    await _write(all);
  });

  Future<void> remove(String id) => removeAll([id]);

  Future<void> removeAll(Iterable<String> ids) => _locked(() async {
    final gone = ids.toSet();
    if (gone.isEmpty) return;
    final all = await _read()
      ..removeWhere((a) => gone.contains(a.id));
    await _write(all);
  });

  /// Replaces [action] with a version carrying one more rejection, or drops
  /// it once it has been refused [maxRejections] times. Returns whether it is
  /// still queued.
  Future<bool> recordRejection(PendingAmolAction action) => _locked(() async {
    final all = await _read();
    final index = all.indexWhere((a) => a.id == action.id);
    if (index < 0) return false;
    final rejected = all[index].withRejection();
    if (rejected.rejections >= maxRejections) {
      all.removeAt(index);
      await _write(all);
      return false;
    }
    all[index] = rejected;
    await _write(all);
    return true;
  });

  /// The `itemKey`s still waiting for [logDate].
  Future<Set<String>> pendingItemKeys(String logDate) async => {
    for (final action in await load())
      if (action.logDate == logDate) action.itemKey,
  };

  /// The days with something waiting, oldest first.
  Future<List<String>> pendingDates() async {
    final dates = <String>{for (final action in await load()) action.logDate};
    return dates.toList()..sort();
  }

  Future<bool> get hasPending async => (await load()).isNotEmpty;

  Future<List<PendingAmolAction>> _read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(key);
      if (raw == null) return [];
      final cutoff = DateTime.now().subtract(_maxAge);
      final actions = <PendingAmolAction>[];
      for (final entry in raw) {
        final action = _decode(entry);
        if (action != null && action.at.isAfter(cutoff)) actions.add(action);
      }
      actions.sort((a, b) => a.at.compareTo(b.at));
      return actions;
    } catch (_) {
      return [];
    }
  }

  Future<void> _write(List<PendingAmolAction> actions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      actions.sort((a, b) => a.at.compareTo(b.at));
      final kept = actions.length > _maxActions
          ? actions.sublist(actions.length - _maxActions)
          : actions;
      await prefs.setStringList(key, kept.map(_encode).toList());
    } catch (_) {
      // Best-effort: a storage failure must not break the tick the user just
      // made, which is already applied on screen.
    }
  }

  static String _encode(PendingAmolAction action) => jsonEncode({
    'isLog': action.isLog,
    'logDate': action.logDate,
    'pillarKey': action.pillarKey,
    'itemKey': action.itemKey,
    'at': action.at.toIso8601String(),
    'rejections': action.rejections,
  });

  /// Tolerates an entry written by an older build (no `at`, no `rejections`).
  static PendingAmolAction? _decode(String raw) {
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final logDate = json['logDate']?.toString() ?? '';
      final pillarKey = json['pillarKey']?.toString() ?? '';
      final itemKey = json['itemKey']?.toString() ?? '';
      if (logDate.isEmpty || pillarKey.isEmpty || itemKey.isEmpty) return null;
      return PendingAmolAction(
        isLog: json['isLog'] == true,
        logDate: logDate,
        pillarKey: pillarKey,
        itemKey: itemKey,
        at: DateTime.tryParse(json['at']?.toString() ?? '') ?? DateTime.now(),
        rejections: (json['rejections'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      return null;
    }
  }
}
