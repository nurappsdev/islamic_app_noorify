// SHARED - compiled into every platform and used by BOTH dashboards.
//
// The Home feature cards (Fardh prayer, Hadith reading, Qur'an, Nafl, Zikr,
// Sunnah/Witr, Quiz) and the small building blocks they sit in: `HomeCard`,
// `HomeGradientShape`, `HomeCircleButton`.
//
// `home_screen_mobile.dart` stacks these in one scrolling column;
// `home_screen_web.dart` spreads the very same widgets across its columns.
// Edit anything here and BOTH Android and Web change - that is the purpose of
// this file, and the reason each platform's own layout lives elsewhere.

part of 'home_screen.dart';

/// Opens the Amol tracker with [section] popped to the front.
void _openTracker(
  BuildContext context,
  AmalSection section, {
  String? itemKey,
}) => openAmolTracker(context, section: section, itemKey: itemKey);

String _pillarText(
  BuildContext context,
  PillarCard? pillar,
  LocalizedText Function(PillarCard pillar) localizedValue,
  String fallback,
) {
  if (pillar == null) return fallback;
  final value = context.localized(localizedValue(pillar));
  return value.isEmpty ? fallback : value;
}

String _pillarCounter(
  BuildContext context,
  PillarCard? pillar,
  String fallback,
) {
  if (pillar == null) return fallback;
  final points = context.localized(pillar.localizedPoints);
  final maxPoints = context.localized(pillar.localizedMaxPoints);
  if (points.isNotEmpty && maxPoints.isNotEmpty) return '$points/$maxPoints';

  String format(num value) =>
      value == value.roundToDouble() ? value.toInt().toString() : '$value';
  return context.localizedDigits(
    '${format(pillar.points)}/${format(pillar.maxPoints)}',
  );
}

/// Fardh-prayer card: [AmalTrackerCardContent] over [HomeGradientShape],
/// fed from the home dashboard when it has loaded. Each bar shows only the
/// user's tracking status: dark green when tracked, soft red when its time has
/// passed untracked. Prayer times are the same Aladhan times (and on-device
/// cache) as [PrayerTimeCard].
class _FardhPrayerCard extends StatefulWidget {
  const _FardhPrayerCard();

  @override
  State<_FardhPrayerCard> createState() => _FardhPrayerCardState();
}

class _FardhPrayerCardState extends State<_FardhPrayerCard> {
  DailyPrayerTimes? _times;
  Timer? _clockTimer;
  DateTime _now = bangladeshNow();

  static const _itemKeys = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

  @override
  void initState() {
    super.initState();
    _loadTimes();
    AmolDailyStore.instance
      ..addListener(_onStoreChanged)
      ..ensureLoaded();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      setState(() => _now = bangladeshNow());
      // Times may only reach the cache after PrayerTimeCard's fetch lands, or
      // roll over at midnight; re-reading the cache costs no network call.
      _refreshFromCache();
    });
  }

  Future<void> _refreshFromCache() async {
    try {
      final service = await AladhanPrayerTimeService.create();
      final cached = service.cachedPrayerTimes(_now);
      if (mounted && cached != null) setState(() => _times = cached);
    } catch (_) {}
  }

  Future<void> _loadTimes() async {
    try {
      final service = await AladhanPrayerTimeService.create();
      final cached = service.cachedPrayerTimes(_now);
      if (cached != null) {
        if (mounted) setState(() => _times = cached);
        return;
      }
      final fresh = await service.loadPrayerTimes(_now);
      if (mounted && fresh != null) setState(() => _times = fresh);
    } catch (_) {}
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AmolDailyStore.instance.removeListener(_onStoreChanged);
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HomeDashboardBloc>().state;
    final dashboard = state.hasData ? state.dashboard : null;
    PillarCard? fardh;
    for (final p in dashboard?.pillarCards ?? const <PillarCard>[]) {
      if (p.pillarKey == 'fardh_prayer') fardh = p;
    }

    final times = _times;
    final minuteNow = _now.hour * 60 + _now.minute;
    // Tracked prayers, from the shared daily checklist (updates when the user
    // ticks one in the tracker).
    final trackedFardh = AmolDailyStore.instance.pillar('fardh_prayer');
    final completedKeys = {
      for (final item in trackedFardh?.items ?? const <AmolItem>[])
        if (item.isCompleted) item.itemKey,
    };
    // What each prayer is worth, as the tracker scores it: every fardh
    // prayer is 2 points. Taking it from the served item keeps the bars
    // right if that ever changes, with [PrayerBarData.defaults] standing in
    // until the daily store has loaded.
    final servedPoints = {
      for (final item in trackedFardh?.items ?? const <AmolItem>[])
        if (item.maxPoints > 0) item.itemKey: item.maxPoints,
    };
    int pointsFor(int index) =>
        (servedPoints[_itemKeys[index]] ?? PrayerBarData.defaults[index].points)
            .round();
    final prayers = [
      for (final (i, prayer) in PrayerBarData.defaults.indexed)
        PrayerBarData(
          name: PrayerPeriod.values[i].displayName(AppText.of(context)),
          trackingName: prayer.trackingName,
          points: pointsFor(i),
          completed: completedKeys.contains(_itemKeys[i]),
          // Red once its time has started (or passed) without being tracked;
          // a prayer that hasn't started yet stays the default colour.
          isMissed:
              times != null &&
              minuteNow >=
                  prayerStart(PrayerPeriod.values[i], times).totalMinutes,
        ),
    ];

    return HomeGradientShape(
      child: AmalTrackerCardContent(
        percentage: trackedFardh?.percentage ?? fardh?.percentage ?? 0,
        percentageLabel: trackedFardh == null
            ? _pillarText(
                context,
                fardh,
                (pillar) => pillar.localizedPercentage,
                '',
              )
            : context.localizedDigits('${trackedFardh.percentage}%'),
        title: _pillarText(
          context,
          fardh,
          (pillar) => pillar.localizedTitle,
          AppText.of(context).categoryLabel('Fardh Prayer'),
        ),
        completedLabel:
            trackedFardh?.formattedSubtext ??
            _pillarText(
              context,
              fardh,
              (pillar) => pillar.localizedFormattedSubtext,
              fardh?.formattedSubtext ?? '',
            ),
        prayers: prayers,
        onOpenDashboard: () => _openTracker(context, AmalSection.fardhPrayer),
        onPrayerTap: (prayer) => _openTracker(
          context,
          AmalSection.fardhPrayer,
          itemKey: _itemKeys[prayers.indexOf(prayer)],
        ),
      ),
      onTap: () => _openTracker(context, AmalSection.fardhPrayer),
    );
  }
}

/// Hadith-reading card: [HadithReadingCardContent] over [HomeGradientShape].
/// Its numbers come from the tracker's own `hadith` pillar (the shared daily
/// checklist, so they follow reading as it is tracked, offline included) and
/// fall back to the `hadith` pillar of the home dashboard.
class _HadithReadingCard extends StatelessWidget {
  const _HadithReadingCard();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HomeDashboardBloc>().state;
    final dashboard = state.hasData ? state.dashboard : null;
    PillarCard? hadith;
    for (final p in dashboard?.pillarCards ?? const <PillarCard>[]) {
      if (p.pillarKey == 'hadith') hadith = p;
    }

    return ValueListenableBuilder<AmolDailyDashboard?>(
      valueListenable: AmolDailyStore.instance,
      builder: (context, daily, _) {
        AmolPillar? tracked;
        for (final pillar in daily?.pillars ?? const <AmolPillar>[]) {
          if (pillar.pillarKey == 'hadith') {
            tracked = pillar;
            break;
          }
        }
        final entry = tracked?.entry;
        String number(num value) => value == value.roundToDouble()
            ? value.toInt().toString()
            : '$value';
        return HomeGradientShape(
          child: HadithReadingCardContent(
            percentage: tracked?.percentage ?? hadith?.percentage ?? 0,
            percentageLabel: tracked == null
                ? _pillarText(
                    context,
                    hadith,
                    (pillar) => pillar.localizedPercentage,
                    '',
                  )
                : context.localizedDigits('${tracked.percentage.round()}%'),
            title: _pillarText(
              context,
              hadith,
              (pillar) => pillar.localizedTitle,
              AppText.of(context).categoryLabel('Hadith'),
            ),
            onOpenDashboard: () => _openTracker(context, AmalSection.hadith),
            counter: tracked == null
                ? _pillarCounter(context, hadith, '0/7')
                : context.localizedDigits(
                    '${number(tracked.earnedPoints)}/'
                    '${number(tracked.maxPoints)}',
                  ),
            // The footer is the time read, which the tracker reports in the
            // item's entry block rather than in the pillar's subtext (a
            // points fraction).
            readingTimeLabel: entry != null && entry.isMinutes
                ? context.amolEntryAmount(entry)
                : _pillarText(
                    context,
                    hadith,
                    (pillar) => pillar.localizedFormattedSubtext,
                    hadith?.formattedSubtext ?? '',
                  ),
          ),
          onTap: () => _openTracker(context, AmalSection.hadith),
        );
      },
    );
  }
}

/// Quran card: [QuranCardContent] over [HomeGradientShape], fed from the
/// `quran` pillar of the home dashboard when it has loaded.
class _QuranCard extends StatelessWidget {
  const _QuranCard();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HomeDashboardBloc>().state;
    final dashboard = state.hasData ? state.dashboard : null;
    PillarCard? quran;
    for (final p in dashboard?.pillarCards ?? const <PillarCard>[]) {
      if (p.pillarKey == 'quran') quran = p;
    }

    return ValueListenableBuilder<AmolDailyDashboard?>(
      valueListenable: AmolDailyStore.instance,
      builder: (context, daily, _) {
        AmolPillar? tracked;
        for (final pillar in daily?.pillars ?? const <AmolPillar>[]) {
          if (pillar.pillarKey == 'quran') {
            tracked = pillar;
            break;
          }
        }
        final points = tracked?.earnedPoints ?? quran?.points ?? 0;
        final max = tracked?.maxPoints ?? quran?.maxPoints ?? 0;
        final entry = tracked?.entry;
        String number(num value) => value == value.roundToDouble()
            ? value.toInt().toString()
            : '$value';
        return HomeGradientShape(
          child: QuranCardContent(
            onOpenQuran: () => _openTracker(context, AmalSection.quran),
            percentageLabel: tracked == null
                ? _pillarText(
                    context,
                    quran,
                    (pillar) => pillar.localizedPercentage,
                    '',
                  )
                : context.localizedDigits('${tracked.percentage.round()}%'),
            title: _pillarText(
              context,
              quran,
              (pillar) => pillar.localizedTitle,
              AppText.of(context).categoryLabel('Quran'),
            ),
            counter: tracked == null
                ? _pillarCounter(context, quran, '0/11')
                : context.localizedDigits('${number(points)}/${number(max)}'),
            progress: max <= 0 ? 0 : (points / max).toDouble(),
            // Inside the ring: how long the Quran has been read today. The
            // tracker's own entry block holds those minutes (its pillar
            // subtext is the points fraction already shown above), and it
            // carries this device's unsent reading too. Without it, the Home
            // dashboard's own duration is used.
            readingTimeLabel: entry != null && entry.isMinutes
                ? context.amolEntryAmount(entry)
                : _pillarText(
                    context,
                    quran,
                    (pillar) => pillar.localizedFormattedSubtext,
                    quran?.formattedSubtext ?? '',
                  ),
          ),
          onTap: () => _openTracker(context, AmalSection.quran),
        );
      },
    );
  }
}

/// Nafl and more card: [NaflMoreCardContent] over [HomeGradientShape], fed
/// from the `nafl_and_more` pillar of the home dashboard when it has loaded.
class _NaflMoreCard extends StatefulWidget {
  const _NaflMoreCard();

  @override
  State<_NaflMoreCard> createState() => _NaflMoreCardState();
}

class _NaflMoreCardState extends State<_NaflMoreCard> {
  @override
  void initState() {
    super.initState();
    AmolDailyStore.instance
      ..addListener(_onStoreChanged)
      ..ensureLoaded();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AmolDailyStore.instance.removeListener(_onStoreChanged);
    super.dispose();
  }

  /// The items and each one's tracked state come from the shared daily
  /// checklist (`nafl_and_more` pillar).
  List<NaflItemData> _items(BuildContext context, PillarCard? pillar) => [
    for (final item
        in AmolDailyStore.instance.pillar('nafl_and_more')?.items ??
            const <AmolItem>[])
      NaflItemData(
        name: _localizedNaflItemName(context, pillar, item),
        points: item.maxPoints,
        completed: item.isCompleted,
        itemKey: item.itemKey,
      ),
  ];

  String _localizedNaflItemName(
    BuildContext context,
    PillarCard? pillar,
    AmolItem item,
  ) {
    final chartKey = switch (item.itemKey) {
      'sadaqah_hadia' => 'sadaqah',
      'nafl_fasting' => 'fasting',
      'given_good_advice' => 'advice',
      'physical_exercise' => 'exercise',
      _ => null,
    };
    final apiLabel = chartKey == null
        ? ''
        : context.localized(pillar?.localizedChartLabels[chartKey]);
    if (apiLabel.isNotEmpty) return apiLabel;

    final appText = AppText.of(context);
    return switch (item.itemKey) {
      'sadaqah_hadia' => appText.moreSadaqah,
      'karje_hasanah' => appText.moreKarzeHasanah,
      'nafl_fasting' => appText.moreNaflFasting,
      'physical_exercise' => appText.morePhysicalExercise,
      'given_good_advice' => appText.moreGivenGoodAdvice,
      'skill_development' => appText.moreSkillDevelopment,
      _ => context.localized(LocalizedText(en: item.title, bn: item.titleBn)),
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HomeDashboardBloc>().state;
    final dashboard = state.hasData ? state.dashboard : null;
    PillarCard? nafl;
    for (final p in dashboard?.pillarCards ?? const <PillarCard>[]) {
      if (p.pillarKey == 'nafl_and_more') nafl = p;
    }

    return HomeGradientShape(
      child: NaflMoreCardContent(
        percentage: nafl?.percentage ?? 0,
        percentageLabel: _pillarText(
          context,
          nafl,
          (pillar) => pillar.localizedPercentage,
          '',
        ),
        title: _pillarText(
          context,
          nafl,
          (pillar) => pillar.localizedTitle,
          AppText.of(context).categoryLabel('Nafl & more'),
        ),
        onOpenDashboard: () => _openTracker(context, AmalSection.naflAndMore),
        counter: _pillarCounter(context, nafl, '0/7'),
        items: _items(context, nafl),
        onItemTap: (item) => _openTracker(
          context,
          AmalSection.naflAndMore,
          itemKey: item.itemKey,
        ),
      ),
      onTap: () => _openTracker(context, AmalSection.naflAndMore),
    );
  }
}

/// Zikr card: [ZikrCardContent] over [HomeGradientShape], fed from the
/// `tasbih` pillar (the server's pillarKey for Zikr) of the home dashboard
/// when it has loaded. The tracker has no Zikr section, so it opens the Zikr
/// feature instead.
class _ZikrCard extends StatefulWidget {
  const _ZikrCard();

  @override
  State<_ZikrCard> createState() => _ZikrCardState();
}

class _ZikrCardState extends State<_ZikrCard> {
  /// The name for one tracked zikr item: the dashboard's own API label for
  /// this `itemKey` when the server sends one (same source the Nafl & more
  /// and Sunnah/Witr cards use), else the local Prayer-Zikr translation, else
  /// the tracker's own `title` as-is.
  String _localizedZikrItemName(
    BuildContext context,
    PillarCard? pillar,
    AmolItem item,
  ) {
    final apiLabel = context.localized(
      pillar?.localizedChartLabels[item.itemKey],
    );
    if (apiLabel.isNotEmpty) return apiLabel;

    final staticName = localizedTrackedZikrName(
      AppText.of(context),
      item.itemKey,
    );
    if (staticName != null) return staticName;

    return context.localized(LocalizedText(en: item.title, bn: item.titleBn));
  }

  @override
  void initState() {
    super.initState();
    AmolDailyStore.instance
      ..addListener(_onStoreChanged)
      ..ensureLoaded();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AmolDailyStore.instance.removeListener(_onStoreChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HomeDashboardBloc>().state;
    final dashboard = state.hasData ? state.dashboard : null;
    PillarCard? zikr;
    for (final p in dashboard?.pillarCards ?? const <PillarCard>[]) {
      if (p.pillarKey == 'tasbih') zikr = p;
    }
    // The tracker's `tasbih` pillar (the server's pillarKey for Zikr; when
    // it sends one) supplies the list and each zikr's tracked state; without
    // it the card keeps its five numbered placeholders and the Home
    // dashboard's numbers.
    final tracked = AmolDailyStore.instance.pillar('tasbih');
    final items = tracked == null || tracked.items.isEmpty
        ? [
            for (var index = 1; index <= 5; index++)
              ZikrItemData(
                name:
                    '${AppText.of(context).zikrTitle} '
                    '${context.localizedDigits('$index')}',
              ),
          ]
        : [
            for (final item in tracked.items)
              ZikrItemData(
                name: _localizedZikrItemName(context, zikr, item),
                completed: item.isCompleted,
                itemKey: item.itemKey,
              ),
          ];

    void openZikr() => tracked == null
        ? Navigator.of(context).pushNamed(RouteNames.zikr)
        : _openTracker(context, AmalSection.zikr);

    return HomeGradientShape(
      onTap: openZikr,
      child: ZikrCardContent(
        percentage: tracked?.percentage ?? zikr?.percentage ?? 0,
        percentageLabel: _pillarText(
          context,
          zikr,
          (pillar) => pillar.localizedPercentage,
          '',
        ),
        title: _pillarText(
          context,
          zikr,
          (pillar) => pillar.localizedTitle,
          AppText.of(context).categoryLabel('Zikr'),
        ),
        counter: _pillarCounter(context, zikr, '0/7'),
        items: items,
        // With a tracker pillar, the arrow opens the tracker on it (where
        // Zikr is ticked); otherwise the Zikr feature.
        onOpenZikr: openZikr,
        onItemTap: (item) => tracked == null
            ? openZikr()
            : _openTracker(context, AmalSection.zikr, itemKey: item.itemKey),
      ),
    );
  }
}

/// Sunnah and Witr card: [SunnahWitrCardContent] over [HomeGradientShape],
/// fed from the `sunnah_witr` pillar of the home dashboard when it has loaded.
class _SunnahWitrCard extends StatefulWidget {
  const _SunnahWitrCard();

  @override
  State<_SunnahWitrCard> createState() => _SunnahWitrCardState();
}

class _SunnahWitrCardState extends State<_SunnahWitrCard> {
  /// Pill label -> the tracker `itemKey` behind it. Witr has its own pill
  /// (in place of Asr, which has no Sunnah of its own), so Isha's pill is
  /// just the Isha Sunnah.
  static const _pillItems = {
    'Fajr': ['fajr_sunnah'],
    'Duhr': ['dhuhr_sunnah'],
    'Witr': ['witr'],
    'Magrib': ['maghrib_sunnah'],
    'Esa': ['isha_sunnah'],
  };

  @override
  void initState() {
    super.initState();
    AmolDailyStore.instance
      ..addListener(_onStoreChanged)
      ..ensureLoaded();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AmolDailyStore.instance.removeListener(_onStoreChanged);
    super.dispose();
  }

  /// Per-prayer points and tracked state from the shared daily checklist
  /// (`sunnah_witr` pillar); empty until it loads.
  List<SunnahPrayerData> _prayers(BuildContext context, PillarCard? pillar) {
    final items = AmolDailyStore.instance.pillar('sunnah_witr')?.items;
    if (items == null) return const [];
    final byKey = {for (final item in items) item.itemKey: item};
    const chartKeyByItemKey = {
      'fajr_sunnah': 'fajrSunnah',
      'dhuhr_sunnah': 'dhuhrSunnah',
      'maghrib_sunnah': 'maghribSunnah',
      'isha_sunnah': 'ishaSunnah',
      'witr': 'witr',
    };
    return [
      for (final entry in _pillItems.entries)
        if (byKey[entry.value.first] != null)
          SunnahPrayerData(
            prayerName: entry.key,
            label: context.localized(
              pillar?.localizedChartLabels[chartKeyByItemKey[entry
                  .value
                  .first]],
            ),
            points: [
              for (final key in entry.value) byKey[key]?.maxPoints ?? 0,
            ].fold<num>(0, (sum, v) => sum + v),
            sunnahCompleted: byKey[entry.value.first]!.isCompleted,
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HomeDashboardBloc>().state;
    final dashboard = state.hasData ? state.dashboard : null;
    PillarCard? sunnah;
    for (final p in dashboard?.pillarCards ?? const <PillarCard>[]) {
      if (p.pillarKey == 'sunnah_witr') sunnah = p;
    }

    return HomeGradientShape(
      child: SunnahWitrCardContent(
        percentage: sunnah?.percentage ?? 0,
        percentageLabel: _pillarText(
          context,
          sunnah,
          (pillar) => pillar.localizedPercentage,
          '',
        ),
        title: _pillarText(
          context,
          sunnah,
          (pillar) => pillar.localizedTitle,
          AppText.of(context).categoryLabel('Sunnah and Witr'),
        ),
        counter: _pillarCounter(context, sunnah, '0/6'),
        prayers: _prayers(context, sunnah),
        onOpenTracker: () => _openTracker(context, AmalSection.sunnahWitr),
        onPrayerTap: (name) => _openTracker(
          context,
          AmalSection.sunnahWitr,
          itemKey: _pillItems[name]?.first,
        ),
      ),
      onTap: () => _openTracker(context, AmalSection.sunnahWitr),
    );
  }
}

/// Quiz card: [QuizCardContent] over [HomeGradientShape], fed from the `quiz`
/// pillar of the home dashboard (title/percentage/counter) and the two
/// glass tiles from the tracker's own `quiz` pillar items (the same
/// `AmolDailyStore` source the Zikr card reads for its items), when the
/// server sends them.
///
/// The tracker sends the day's quizzes as one item worth them all
/// (`daily_quiz`, `maxPoints: 2`); its `entry` block holds the per-quiz rule
/// (`entryPoints: 1`, `maxEntries: 2`), which is what a tile shows.
class _QuizCard extends StatefulWidget {
  const _QuizCard();

  @override
  State<_QuizCard> createState() => _QuizCardState();
}

class _QuizCardState extends State<_QuizCard> {
  @override
  void initState() {
    super.initState();
    AmolDailyStore.instance
      ..addListener(_onStoreChanged)
      ..ensureLoaded();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AmolDailyStore.instance.removeListener(_onStoreChanged);
    super.dispose();
  }

  /// One diamond tile from a tracked quiz item: its own localized title, and
  /// its earned points once played, otherwise the worth it shows before
  /// being played. Only used when the server splits the day into one item
  /// per quiz; a single item covering them all goes through [_tilesFromItem].
  QuizTileData _tileFromItem(BuildContext context, AmolItem item) =>
      QuizTileData(
        title: _itemTitle(context, item),
        points: item.isCompleted ? item.points : item.maxPoints,
        completed: item.isCompleted,
      );

  String _itemTitle(BuildContext context, AmolItem item) =>
      context.localized(LocalizedText(en: item.title, bn: item.titleBn));

  /// Both tiles from the one quiz item that covers the whole day. Its `entry`
  /// block counts the quizzes ([AmolEntry.maxEntries]) and what each is worth
  /// ([AmolEntry.entryPoints]), so a tile carries a single quiz's point - not
  /// the item's total - and is selected once that many quizzes are answered.
  /// Without an entry block the item is a plain tick-mark, so it stays one
  /// tile.
  List<QuizTileData> _tilesFromItem(BuildContext context, AmolItem item) {
    final entry = item.entry;
    if (entry == null || entry.maxEntries <= 1) {
      return [_tileFromItem(context, item)];
    }
    final title = _itemTitle(context, item);
    return [
      for (var i = 0; i < entry.maxEntries; i++)
        QuizTileData(
          title: '$title ${context.localizedDigits('${i + 1}')}',
          points: entry.entryPoints,
          completed: i < entry.entries,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HomeDashboardBloc>().state;
    final dashboard = state.hasData ? state.dashboard : null;
    PillarCard? quiz;
    for (final p in dashboard?.pillarCards ?? const <PillarCard>[]) {
      if (p.pillarKey == 'quiz') quiz = p;
    }

    final title = _pillarText(
      context,
      quiz,
      (pillar) => pillar.localizedTitle,
      AppText.of(context).categoryLabel('Quiz'),
    );

    // The tracker's `quiz` pillar supplies the Daily Quiz tiles: one item
    // covering the day splits into a tile per quiz, while a server that
    // sends an item per quiz maps one to one. Without the tracker the tiles
    // fall back to the Home dashboard's own quiz summary.
    final trackedItems =
        AmolDailyStore.instance.pillar('quiz')?.items ?? const <AmolItem>[];
    final quizTiles = switch (trackedItems) {
      [] => quizTilesFromPillar(
        quiz,
        titleFor: (index) => '$title ${context.localizedDigits('$index')}',
      ),
      [final only] => _tilesFromItem(context, only),
      _ => [for (final item in trackedItems) _tileFromItem(context, item)],
    };

    return HomeGradientShape(
      child: QuizCardContent(
        percentage: quiz?.percentage ?? 0,
        percentageLabel: _pillarText(
          context,
          quiz,
          (pillar) => pillar.localizedPercentage,
          '',
        ),
        title: title,
        counter: _pillarCounter(context, quiz, '0/$quizTilesPerDay'),
        tiles: quizTiles,
        onOpenTracker: () => _openTracker(context, AmalSection.quiz),
      ),
      onTap: () => _openTracker(context, AmalSection.quiz),
    );
  }
}

/// Rounded panel with a top-to-bottom white -> light green gradient.
class HomeGradientShape extends StatelessWidget {
  const HomeGradientShape({super.key, this.child, this.onTap});

  final Widget? child;

  /// Makes the whole card tappable. A button or item inside the card that
  /// handles its own tap still wins on its own area.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(24.r);
    final card = Container(
      width: double.infinity,
      height: 380.h,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFDCEBBB)],
        ),
        border: Border.all(color: const Color(0xFFDCEBBB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 40.h,
              child: Image.asset(
                'assets/newShape.png',
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
              ),
            ),
            if (child != null) Positioned.fill(child: child!),
          ],
        ),
      ),
    );
    if (onTap == null) return card;
    // No ripple or highlight: the card looks exactly as before; only its tap
    // area grows to cover all of it.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: card,
    );
  }
}

class HomeCard extends StatelessWidget {
  const HomeCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
    this.backgroundColor,
    this.radius = 11,
    this.shadows,
  });

  final double radius;
  final List<BoxShadow>? shadows;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: context.surfaceColor(backgroundColor ?? palette.surface),
        borderRadius: BorderRadius.circular(radius.r),
        border: Border.all(
          color: context.lineColor(borderColor ?? palette.border),
        ),
        boxShadow: shadows,
      ),
      child: child,
    );
  }
}

/// Pass [context] to follow the active theme; without it (and without
/// [color]) the light-mode color is used.
TextStyle homeSerifStyle({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  BuildContext? context,
}) {
  return TextStyle(
    color: color ?? (context?.appPalette ?? AppPalette.light).textStrong,
    fontSize: fontSize,
    fontFamily: appFontFamilyFor(LanguagePreference.current),
    fontFamilyFallback: appFontFamilyFallback,
    fontStyle: FontStyle.italic,
    fontWeight: fontWeight,
  );
}

TextStyle homeSansStyle({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  BuildContext? context,
}) {
  return TextStyle(
    color: color ?? (context?.appPalette ?? AppPalette.light).textPrimary,
    fontSize: fontSize,
    fontFamily: appFontFamilyFor(LanguagePreference.current),
    fontFamilyFallback: appFontFamilyFallback,
    fontWeight: fontWeight,
  );
}

class HomeCircleButton extends StatelessWidget {
  const HomeCircleButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size ?? 25.r,
      child: IconButton(
        onPressed: onPressed ?? () {},
        style: IconButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: context.appPalette.tint,
          foregroundColor: AppColor.primary,
        ),
        icon: Icon(icon, size: 15.sp),
      ),
    );
  }
}
