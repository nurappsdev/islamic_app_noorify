import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_daily_dashboard.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_pending_action.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_pillar.dart';
import 'package:tuhfatul_muslim/features/dua/domain/dua_reading_points.dart';
import 'package:tuhfatul_muslim/features/quran/domain/quran_reading_points.dart';

/// The pillars whose items are a plain tick, and so may be queued offline and
/// replayed safely.
///
/// `POST /amol/tracker/log-item` is documented as *additive* for the entry
/// pillars — "logging an entry item adds one entry (e.g. 5 minutes); deleting
/// removes the last one" — so `quran`, `hadith`, `dua`, `tasbih` and `quiz`
/// must never be queued and replayed: a replay would add a second entry. They
/// are logged inside their own features (which carry their own offline
/// handling) and this tracker only ever displays their result, which is why
/// its rows for them navigate instead of ticking.
const amolQueueablePillarKeys = {
  'fardh_prayer',
  'sunnah_witr',
  'nafl_salat',
  'nafl_and_more',
};

/// Whether an item in [pillarKey] may be tracked offline at all.
bool isAmolQueueable(String pillarKey) =>
    amolQueueablePillarKeys.contains(pillarKey);

/// [dashboard] as it should be shown with [actions] applied on top: the
/// server's day plus everything this device has done to it since.
///
/// Points, pillar progress and the day's total are recomputed locally so the
/// bars and the summary move the moment the user ticks, offline or not. They
/// are provisional: the next successful call replaces the whole day with the
/// server's own arithmetic.
AmolDailyDashboard projectAmolDay(
  AmolDailyDashboard dashboard,
  Iterable<PendingAmolAction> actions,
) {
  final forThisDay = actions
      .where(
        (a) => a.logDate == dashboard.dateIso && isAmolQueueable(a.pillarKey),
      )
      .toList();
  if (forThisDay.isEmpty) {
    return dashboard.pendingItemKeys.isEmpty
        ? dashboard
        : dashboard.copyWith(pendingItemKeys: const {});
  }

  final desired = <String, bool>{};
  final pendingKeys = <String>{};
  for (final action in forThisDay) {
    desired['${action.pillarKey}|${action.itemKey}'] = action.isLog;
    pendingKeys.add(action.itemKey);
  }

  final pillars = [
    for (final pillar in dashboard.pillars)
      _recomputePillar(
        pillar.copyWith(
          items: [
            for (final item in pillar.items)
              switch (desired['${pillar.pillarKey}|${item.itemKey}']) {
                null => item,
                final bool checked => item.copyWith(
                  isCompleted: checked,
                  // A plain tick earns the item's full points (the API's
                  // default when no option is sent).
                  points: checked ? item.maxPoints : 0,
                ),
              },
          ],
        ),
      ),
  ];

  return _recomputeDay(
    dashboard.copyWith(pillars: pillars, pendingItemKeys: pendingKeys),
  );
}

/// Applies Quran reading still held on this device to the server's daily
/// checklist. The Quran item awards one point for every completed five
/// minutes, so the total is calculated from the duration the day already
/// holds instead of rounding each offline session separately.
AmolDailyDashboard projectOfflineQuranReading(
  AmolDailyDashboard dashboard, {
  required int additionalSeconds,
}) => _projectOfflineReading(
  dashboard,
  pillarKey: 'quran',
  additionalSeconds: additionalSeconds,
  pointsForSeconds: quranReadingPointsForSeconds,
);

/// The same for dua reading, under the Dua item's own rule: half a point for
/// every completed five minutes, one point a day at most (ten minutes).
///
/// The day's dua time is cumulative, so a visit read offline is added to
/// what the day already holds rather than rounded on its own — three
/// two-minute visits earn the same half point one six-minute visit does.
AmolDailyDashboard projectOfflineDuaReading(
  AmolDailyDashboard dashboard, {
  required int additionalSeconds,
}) => _projectOfflineReading(
  dashboard,
  pillarKey: 'dua',
  additionalSeconds: additionalSeconds,
  pointsForSeconds: duaReadingPointsForSeconds,
);

/// [dashboard] with [additionalSeconds] of reading this device still holds
/// added to the pillar measured in minutes under [pillarKey].
///
/// The day's duration comes from the item's own `entry` block (`amount`, in
/// minutes) — the pillar's `formattedSubtext` is a points fraction such as
/// `"5/9"`, not a duration. A payload with neither (an older response) still
/// has its local minutes added, but keeps the points the server awarded:
/// a duration this code cannot read is never treated as zero minutes.
/// [pointsForSeconds] is that pillar's own rule, used only when the response
/// carries no `entry` block to read it from.
AmolDailyDashboard _projectOfflineReading(
  AmolDailyDashboard dashboard, {
  required String pillarKey,
  required int additionalSeconds,
  required num Function(int seconds) pointsForSeconds,
}) {
  final index = dashboard.pillars.indexWhere((p) => p.pillarKey == pillarKey);
  if (index < 0) return dashboard;

  final current = dashboard.pillars[index];
  final entry = current.entry;
  final isMinuteEntry = entry != null && entry.isMinutes;
  final recordedSeconds = isMinuteEntry
      ? (entry.amount * 60).round()
      : _durationSeconds(current.formattedSubtext);
  if (recordedSeconds == null) {
    // The day's own duration is unknown here, so nothing can be verified
    // against it: only add what this device has read, on top of the
    // server's points.
    return additionalSeconds <= 0
        ? dashboard
        : _withEntryPoints(
            dashboard,
            index,
            earned: _cap(
              current.earnedPoints + pointsForSeconds(additionalSeconds),
              current.maxPoints,
            ),
          );
  }

  final totalSeconds = recordedSeconds + additionalSeconds;
  final totalMinutes = totalSeconds ~/ 60;
  // Duration is the source of truth for a five-minute rule. A stale
  // response can otherwise say e.g. "14min" and "4 points" at the same
  // time, even though four points require at least twenty minutes. Rebuild
  // the shown point total from the same duration shown on the card, by the
  // item's own rule when the server sent one.
  final pointsForDuration = _cap(
    isMinuteEntry
        ? entry.pointsFor(totalMinutes)
        : pointsForSeconds(totalSeconds),
    current.maxPoints,
  );
  // With no new local time, only repair an impossible over-award from a
  // stale response. Do not invent points the server has not awarded yet.
  final earned = additionalSeconds > 0
      ? pointsForDuration
      : (current.earnedPoints > pointsForDuration
            ? pointsForDuration
            : current.earnedPoints);
  if (earned == current.earnedPoints && additionalSeconds <= 0) {
    return dashboard;
  }

  return _withEntryPoints(
    dashboard,
    index,
    earned: earned,
    // The entry block carries the minutes the card shows; the subtext stays
    // the points fraction the server writes there.
    minutes: isMinuteEntry ? totalMinutes : null,
    formattedSubtext: isMinuteEntry
        ? _retextPoints(current.formattedSubtext, earned, current.maxPoints)
        : _durationText(totalSeconds),
  );
}

/// [dashboard] with the entry pillar at [index] rewritten to [earned] points
/// (and [minutes] read, when known), and the day's total recomputed.
AmolDailyDashboard _withEntryPoints(
  AmolDailyDashboard dashboard,
  int index, {
  required num earned,
  int? minutes,
  String? formattedSubtext,
}) {
  final current = dashboard.pillars[index];
  final pillars = [...dashboard.pillars];
  pillars[index] = current.copyWith(
    earnedPoints: earned,
    percentage: _percentage(earned, current.maxPoints),
    formattedSubtext: formattedSubtext,
    items: [
      for (final item in current.items)
        if (item.entry == null)
          item
        else
          item.copyWith(
            points: earned,
            entry: minutes == null
                ? item.entry
                : item.entry!.withAmount(minutes),
          ),
    ],
  );
  return _recomputeDay(dashboard.copyWith(pillars: pillars));
}

num _cap(num value, num maxPoints) {
  if (value < 0) return 0;
  return maxPoints > 0 && value > maxPoints ? maxPoints : value;
}

/// `"1hr 37min"` -> seconds. `null` when [value] isn't a duration at all
/// (the server writes a points fraction there), which must never be read as
/// "nothing was read today".
int? _durationSeconds(String value) {
  final match = RegExp(
    r'^\s*(?:(\d+)\s*hr)?\s*(?:(\d+)\s*min)?\s*$',
    caseSensitive: false,
  ).firstMatch(value);
  if (match == null) return null;
  final hours = int.tryParse(match.group(1) ?? '');
  final minutes = int.tryParse(match.group(2) ?? '');
  if (hours == null && minutes == null) return null;
  return ((hours ?? 0) * 60 + (minutes ?? 0)) * 60;
}

String _durationText(int seconds) {
  final minutes = seconds ~/ 60;
  final hours = minutes ~/ 60;
  final remainder = minutes % 60;
  return hours == 0 ? '${remainder}min' : '${hours}hr ${remainder}min';
}

/// A fresh, untouched day built from the last day the server sent: the same
/// pillars, items, titles and point values, nothing completed.
///
/// This is what makes a new Fajr-to-Fajr day tickable while offline — the
/// checklist itself only ever comes from the server, so without a template
/// there would be nothing on screen to tick.
AmolDailyDashboard blankAmolDay(AmolDailyDashboard template, String dateIso) {
  final pillars = [for (final pillar in template.pillars) _blankPillar(pillar)];
  return _recomputeDay(
    template.copyWith(
      dateIso: dateIso,
      // The screen formats the date itself; the server's string belonged to
      // the day the template came from.
      dateFormatted: '',
      pillars: pillars,
      pendingItemKeys: const {},
    ),
  );
}

/// A pillar with nothing done yet. Every pillar is emptied, entry pillars
/// included: yesterday's minutes read or zikr counted must not be carried
/// into a new day's template as if they had been earned again — their
/// amounts go back to zero along with their points. The subtext is a
/// server-written phrase that can't be recomputed for an entry pillar, so it
/// is cleared rather than left stale.
AmolPillar _blankPillar(AmolPillar pillar) {
  final blanked = pillar.copyWith(
    items: [
      for (final item in pillar.items)
        item.copyWith(
          isCompleted: false,
          points: 0,
          entry: item.entry?.withAmount(0),
        ),
    ],
    earnedPoints: 0,
    percentage: 0,
  );
  if (isAmolQueueable(pillar.pillarKey)) return _recomputePillar(blanked);
  // An entry pillar's subtext is a points fraction, so it can be emptied to
  // `0/max`; anything else (an older duration phrase) is cleared.
  return blanked.copyWith(
    formattedSubtext: _isFraction(pillar.formattedSubtext)
        ? _retextPoints(pillar.formattedSubtext, 0, pillar.maxPoints)
        : '',
  );
}

AmolPillar _recomputePillar(AmolPillar pillar) {
  // An entry pillar's own numbers are the server's to compute (minutes read,
  // zikr counted, quiz attempts): only its items' tick state is projected.
  if (!isAmolQueueable(pillar.pillarKey)) return pillar;
  final earned = pillar.items.fold<num>(0, (sum, item) => sum + item.points);
  final done = pillar.items.where((item) => item.isCompleted).length;
  return pillar.copyWith(
    earnedPoints: earned,
    percentage: _percentage(earned, pillar.maxPoints),
    formattedSubtext: _retextFraction(
      pillar.formattedSubtext,
      done,
      pillar.items.length,
    ),
  );
}

AmolDailyDashboard _recomputeDay(AmolDailyDashboard day) {
  final earned = day.pillars.fold<num>(0, (sum, p) => sum + p.earnedPoints);
  // The API caps the day's score at its maximum; match it rather than show a
  // total the server will never agree with.
  final capped = day.maxPoints > 0 && earned > day.maxPoints
      ? day.maxPoints
      : earned;
  final percentage = _percentage(capped, day.maxPoints);
  final total = day.summary.totalPossiblePoints;
  return day.copyWith(
    earnedPoints: capped,
    completionPercentage: percentage,
    summary: day.summary.copyWith(
      totalEarnedPoints: capped,
      percentage: _percentage(capped, total),
      pointsText: _retextPoints(day.summary.pointsText, capped, total),
    ),
  );
}

num _percentage(num earned, num possible) {
  if (possible <= 0) return 0;
  final value = earned / possible * 100;
  return value < 0 ? 0 : (value > 100 ? 100 : value);
}

/// `"2/7"` -> `"3/7"`. Left alone when the server's subtext isn't a plain
/// fraction.
String _retextFraction(String subtext, int done, int total) {
  if (!_isFraction(subtext)) return subtext;
  return '$done/$total';
}

bool _isFraction(String subtext) =>
    RegExp(r'^\s*\d+(?:\.\d+)?\s*/\s*\d+(?:\.\d+)?\s*$').hasMatch(subtext);

/// `"Point : 2/40"` -> `"Point : 3/40"`, keeping whatever label the server
/// used. Left alone when it doesn't end in a fraction.
String _retextPoints(String pointsText, num earned, num possible) {
  final match = RegExp(
    r'^(.*?)(\d+(?:\.\d+)?)\s*/\s*(\d+(?:\.\d+)?)\s*$',
  ).firstMatch(pointsText);
  if (match == null) return pointsText;
  return '${match.group(1)}${formatAmolPointValue(earned)}'
      '/${formatAmolPointValue(possible)}';
}

/// `3` rather than `3.0`, `2.5` kept as is.
String formatAmolPointValue(num value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();
