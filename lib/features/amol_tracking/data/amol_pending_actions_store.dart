import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A single `log-item`/`delete-item` call that couldn't reach the server, to
/// be replayed once connectivity is back.
class PendingAmolAction {
  const PendingAmolAction({
    required this.isLog,
    required this.logDate,
    required this.pillarKey,
    required this.itemKey,
  });

  /// `true` for `log-item` (checked), `false` for `delete-item` (unchecked).
  final bool isLog;
  final String logDate;
  final String pillarKey;
  final String itemKey;

  Map<String, dynamic> toJson() => {
    'isLog': isLog,
    'logDate': logDate,
    'pillarKey': pillarKey,
    'itemKey': itemKey,
  };

  factory PendingAmolAction.fromJson(Map<String, dynamic> json) =>
      PendingAmolAction(
        isLog: json['isLog'] == true,
        logDate: json['logDate']?.toString() ?? '',
        pillarKey: json['pillarKey']?.toString() ?? '',
        itemKey: json['itemKey']?.toString() ?? '',
      );
}

/// Persists the tracking changes made while offline, so they survive the app
/// being closed and can be replayed against the server once it's reachable
/// again — `logItem`/`deleteItem` never silently lose what the user did.
///
/// A later action for the same pillar/item collapses the earlier one (only
/// the user's latest intended state for that item matters — ticking then
/// unticking the same item while offline should replay as just "untick").
class AmolPendingActionsStore {
  static const _key = 'offline_cache_amol_pending_actions';

  Future<List<PendingAmolAction>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_key);
      if (raw == null) return const [];
      return raw
          .map((e) => PendingAmolAction.fromJson(jsonDecode(e)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> enqueue(PendingAmolAction action) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final actions = await load();
      actions.removeWhere(
        (a) => a.pillarKey == action.pillarKey && a.itemKey == action.itemKey,
      );
      actions.add(action);
      await prefs.setStringList(
        _key,
        actions.map((a) => jsonEncode(a.toJson())).toList(),
      );
    } catch (_) {
      // Best-effort: worst case this one change doesn't survive a restart
      // while offline, same as before this store existed.
    }
  }

  Future<void> remove(PendingAmolAction action) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final actions = await load();
      actions.removeWhere(
        (a) => a.pillarKey == action.pillarKey && a.itemKey == action.itemKey,
      );
      await prefs.setStringList(
        _key,
        actions.map((a) => jsonEncode(a.toJson())).toList(),
      );
    } catch (_) {}
  }

  Future<bool> get hasPending async => (await load()).isNotEmpty;
}
