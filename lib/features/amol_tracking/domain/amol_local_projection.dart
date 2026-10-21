import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_daily_dashboard.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_pending_action.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_pillar.dart';

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
/// into a new day's template as if they had been earned again. Their subtext
/// is a server-written phrase (`"1hr 37min"`) that can't be recomputed here,
/// so it is cleared rather than left stale.
AmolPillar _blankPillar(AmolPillar pillar) {
  final blanked = pillar.copyWith(
    items: [
      for (final item in pillar.items)
        item.copyWith(isCompleted: false, points: 0),
    ],
    earnedPoints: 0,
    percentage: 0,
  );
  return isAmolQueueable(pillar.pillarKey)
      ? _recomputePillar(blanked)
      : blanked.copyWith(formattedSubtext: '');
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
/// fraction (an entry pillar's is a duration like `"1hr 37min"`).
String _retextFraction(String subtext, int done, int total) {
  if (!RegExp(r'^\s*\d+\s*/\s*\d+\s*$').hasMatch(subtext)) return subtext;
  return '$done/$total';
}

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
