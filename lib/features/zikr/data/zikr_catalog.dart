/// Static content for the Zikr feature.
///
/// The Zikr screens are UI-only for now — nothing here is persisted. Arabic and
/// transliteration strings live in code (not [AppText]), the same way the Hadith
/// feature keeps hadith text out of localization.
class ZikrItem {
  const ZikrItem({
    required this.name,
    required this.arabic,
    required this.transliteration,
    required this.target,
    this.trackingKey,
    this.zikrKey = 'general',
    this.routineId,
    this.planId,
  });

  final String name;
  final String arabic;
  final String transliteration;
  final int target;

  /// Stable Hive key for the Home Screen's Prayer Zikr 1 & 2 counters. `null`
  /// for every other zikr (All Zikr list, dropdown, My Created Zikr, custom
  /// zikr) — those stay in-memory only.
  final String? trackingKey;
  final String zikrKey;
  final String? routineId;
  final String? planId;

  /// e.g. "Subhan Allah (33)"
  String get labelWithTarget => '$name ($target)';

  ZikrItem copyWith({
    int? target,
    String? trackingKey,
    String? zikrKey,
    String? routineId,
    String? planId,
  }) => ZikrItem(
    name: name,
    arabic: arabic,
    transliteration: transliteration,
    target: target ?? this.target,
    trackingKey: trackingKey ?? this.trackingKey,
    zikrKey: zikrKey ?? this.zikrKey,
    routineId: routineId ?? this.routineId,
    planId: planId ?? this.planId,
  );
}

/// A named group of zikr counts, shown as a card on the dashboard.
class ZikrPreset {
  const ZikrPreset({
    this.id,
    required this.name,
    required this.formula,
    required this.items,
  });

  final String name;
  final String? id;

  /// e.g. "33 +33 +34"
  final String formula;
  final List<ZikrItem> items;

  int get total => items.fold(0, (sum, item) => sum + item.target);
}

/// One zikr line being built on [ZikrPlanCreateScreen] — a zikr name and its
/// total reading target, before it's persisted as a `PlanZikrItem`.
class ZikrPlanEntry {
  const ZikrPlanEntry({required this.name, required this.value});

  final String name;
  final int value;
}

abstract final class ZikrCatalog {
  static const subhanAllah = ZikrItem(
    name: 'Subhan Allah',
    arabic: 'سُبْحَانَ اللّٰه',
    transliteration: 'Subhāna-llāh',
    target: 33,
    zikrKey: 'subhanallah',
  );

  static const alhamdulillah = ZikrItem(
    name: 'Alhamdulillah',
    arabic: 'اَلْحَمْدُ لِلّٰه',
    transliteration: 'Al-ḥamdu li-llāh',
    target: 33,
    zikrKey: 'alhamdulillah',
  );

  static const allahuAkbar = ZikrItem(
    name: 'Allahu Akbar',
    arabic: 'اَللّٰهُ أَكْبَر',
    transliteration: 'Allāhu akbar',
    target: 34,
    zikrKey: 'allahu-akbar',
  );

  static const laIlahaIllallah = ZikrItem(
    name: 'La ilaha illallah',
    arabic: 'لَا إِلٰهَ إِلَّا اللّٰه',
    transliteration: 'Lā ilāha illā-llāh',
    target: 100,
    zikrKey: 'la-ilaha-illallah',
  );

  static const astaghfirullah = ZikrItem(
    name: 'Astaghfirullah',
    arabic: 'أَسْتَغْفِرُ اللّٰه',
    transliteration: 'Astaghfiru-llāh',
    target: 100,
    zikrKey: 'astaghfirullah',
  );

  static const laHawla = ZikrItem(
    name: 'La hawla wa la quwwata illa billah',
    arabic: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللّٰه',
    transliteration: 'Lā ḥawla wa lā quwwata illā bi-llāh',
    target: 100,
    zikrKey: 'la-hawla-wa-la-quwwata-illa-billah',
  );

  static const salawat = ZikrItem(
    name: 'Salawat',
    arabic: 'اَللّٰهُمَّ صَلِّ عَلَىٰ مُحَمَّد',
    transliteration: 'Allāhumma ṣalli ʿalā Muḥammad',
    target: 100,
    zikrKey: 'salawat',
  );

  static const subhanAllahiWaBihamdihi = ZikrItem(
    name: "Subhan Allahi wa bihamdihi",
    arabic: 'سُبْحَانَ اللّٰهِ وَبِحَمْدِهِ',
    transliteration: 'Subḥāna-llāhi wa bi-ḥamdihi',
    target: 100,
    zikrKey: 'subhan-allahi-wa-bihamdihi',
  );

  /// Every zikr shown on the "All Zikr" screen.
  static const List<ZikrItem> all = [
    subhanAllah,
    alhamdulillah,
    allahuAkbar,
    laIlahaIllallah,
    astaghfirullah,
    laHawla,
    salawat,
    subhanAllahiWaBihamdihi,
  ];

  /// Prayer Zikr 1's three counters, each persisted in Hive under its own
  /// [ZikrItem.trackingKey] (Home Screen Zikr section).
  static final subhanAllahPrayer1 = subhanAllah.copyWith(
    trackingKey: 'subhanAllah1',
  );
  static final alhamdulillahPrayer1 = alhamdulillah.copyWith(
    trackingKey: 'alhamdulillah1',
  );
  static const allahuAkbarPrayer1 = ZikrItem(
    name: 'Allahu Akbar',
    arabic: 'اَللّٰهُ أَكْبَر',
    transliteration: 'Allāhu akbar',
    target: 33,
    trackingKey: 'allahuAkbar1',
  );

  /// Prayer Zikr 2's 4th counter (its first 3 are shared with Prayer Zikr 1 —
  /// see [prayerPresets]), persisted in Hive under its [ZikrItem.trackingKey]
  /// (Home Screen Zikr section).
  static const finalZikrPrayer2 = ZikrItem(
    name:
        "La ilaha illallahu wahdahu la sharika lah, lahul mulku wa lahul "
        "hamdu wa huwa 'ala kulli shay'in qadir",
    arabic:
        'لَا إِلٰهَ إِلَّا اللّٰهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ '
        'وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِير',
    transliteration:
        "Lā ilāha illā-llāhu waḥdahu lā sharīka lahu, lahu-l-mulku wa "
        "lahu-l-ḥamdu wa huwa ʿalā kulli shayʾin qadīr",
    target: 1,
    trackingKey: 'finalZikr2',
  );

  /// The two "Prayer Zikr" presets shown in the dashboard header, backed by
  /// Hive — see [ZikrItem.trackingKey].
  ///
  /// Prayer Zikr 2 walks the same SubhanAllah / Alhamdulillah / Allahu Akbar
  /// counters as Prayer Zikr 1 (same [ZikrItem] instances, same Hive keys)
  /// plus its own 4th zikr, so counting from either preset updates one
  /// shared progress and the Home Screen total never double-counts.
  static final List<ZikrPreset> prayerPresets = [
    ZikrPreset(
      name: 'Prayer Zikr 1',
      formula: '33 +33 +33',
      items: [subhanAllahPrayer1, alhamdulillahPrayer1, allahuAkbarPrayer1],
    ),
    ZikrPreset(
      name: 'Prayer Zikr 2',
      formula: '33 +33 +33 +1',
      items: [
        subhanAllahPrayer1,
        alhamdulillahPrayer1,
        allahuAkbarPrayer1,
        finalZikrPrayer2,
      ],
    ),
  ];

  /// Every [ZikrItem.trackingKey] used by the Home Screen Zikr section, in
  /// display order — the keys [ZikrProgressStore] persists in Hive.
  static const List<String> trackedKeys = [
    'subhanAllah1',
    'alhamdulillah1',
    'allahuAkbar1',
    'finalZikr2',
  ];

  /// Names shown in the "Select Zikr" dropdown (design `devImg/img_14.png`).
  static const List<ZikrItem> dropdownItems = [
    subhanAllah,
    alhamdulillah,
    allahuAkbar,
  ];

  /// Formats a count the Indian way — e.g. "1,76,337".
  static String formatIndian(int value) {
    final digits = value.toString();
    if (digits.length <= 3) return digits;
    final head = digits.substring(0, digits.length - 3);
    final tail = digits.substring(digits.length - 3);
    final buffer = StringBuffer();
    for (var i = 0; i < head.length; i++) {
      final fromEnd = head.length - i;
      buffer.write(head[i]);
      if (fromEnd > 1 && fromEnd.isOdd) buffer.write(',');
    }
    return '$buffer,$tail';
  }
}
