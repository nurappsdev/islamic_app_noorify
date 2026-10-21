/// One tick (or untick) made on this device that the server hasn't accepted
/// yet — the unit of the offline queue.
///
/// Identity is [id]: the day it belongs to *and* the item. The day matters,
/// because the same item is ticked again on the next Fajr-to-Fajr day and the
/// two must never collapse into one.
class PendingAmolAction {
  const PendingAmolAction({
    required this.isLog,
    required this.logDate,
    required this.pillarKey,
    required this.itemKey,
    required this.at,
    this.rejections = 0,
  });

  /// `true` for a tick (`log-item`), `false` for an untick (`delete-item`).
  final bool isLog;

  /// The Fajr-to-Fajr day this belongs to (`YYYY-MM-DD`), resolved when the
  /// user tapped — never re-derived at sync time, so a tick made before Fajr
  /// still lands on the day the user made it.
  final String logDate;
  final String pillarKey;
  final String itemKey;

  /// When the user made it. Orders the queue, and ages it out.
  final DateTime at;

  /// How many times the server has *rejected* this (a real 4xx/5xx answer,
  /// not being offline). Past a few, it is dropped instead of blocking the
  /// queue forever.
  final int rejections;

  /// One item on one day: the queue holds at most one action per [id], the
  /// last one the user made.
  String get id => '$logDate|$pillarKey|$itemKey';

  PendingAmolAction withRejection() => PendingAmolAction(
    isLog: isLog,
    logDate: logDate,
    pillarKey: pillarKey,
    itemKey: itemKey,
    at: at,
    rejections: rejections + 1,
  );
}
