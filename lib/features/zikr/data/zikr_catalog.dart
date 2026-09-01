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
  });

  final String name;
  final String arabic;
  final String transliteration;
  final int target;

  /// e.g. "Subhan Allah (33)"
  String get labelWithTarget => '$name ($target)';
}

/// A named group of zikr counts, shown as a card on the dashboard.
class ZikrPreset {
  const ZikrPreset({
    required this.name,
    required this.formula,
    required this.items,
  });

  final String name;

  /// e.g. "33 +33 +34"
  final String formula;
  final List<ZikrItem> items;

  int get total => items.fold(0, (sum, item) => sum + item.target);
}

/// One zikr line inside a [ZikrPlan] — a zikr name and its total reading target.
class ZikrPlanEntry {
  const ZikrPlanEntry({required this.name, required this.value});

  final String name;
  final int value;
}

/// A daily-zikr plan (design `devImg/img_22.png` / `img_24.png`). UI only.
class ZikrPlan {
  const ZikrPlan({
    required this.name,
    required this.days,
    required this.entries,
    this.completed = false,
  });

  final String name;
  final int days;
  final List<ZikrPlanEntry> entries;
  final bool completed;

  int get totalValue => entries.fold(0, (sum, e) => sum + e.value);
}

abstract final class ZikrCatalog {
  static const subhanAllah = ZikrItem(
    name: 'Subhan Allah',
    arabic: 'سُبْحَانَ اللّٰه',
    transliteration: 'Subhāna-llāh',
    target: 33,
  );

  static const alhamdulillah = ZikrItem(
    name: 'Alhamdulillah',
    arabic: 'اَلْحَمْدُ لِلّٰه',
    transliteration: 'Al-ḥamdu li-llāh',
    target: 33,
  );

  static const allahuAkbar = ZikrItem(
    name: 'Allahu Akbar',
    arabic: 'اَللّٰهُ أَكْبَر',
    transliteration: 'Allāhu akbar',
    target: 34,
  );

  static const laIlahaIllallah = ZikrItem(
    name: 'La ilaha illallah',
    arabic: 'لَا إِلٰهَ إِلَّا اللّٰه',
    transliteration: 'Lā ilāha illā-llāh',
    target: 100,
  );

  static const astaghfirullah = ZikrItem(
    name: 'Astaghfirullah',
    arabic: 'أَسْتَغْفِرُ اللّٰه',
    transliteration: 'Astaghfiru-llāh',
    target: 100,
  );

  static const laHawla = ZikrItem(
    name: 'La hawla wa la quwwata illa billah',
    arabic: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللّٰه',
    transliteration: 'Lā ḥawla wa lā quwwata illā bi-llāh',
    target: 100,
  );

  static const salawat = ZikrItem(
    name: 'Salawat',
    arabic: 'اَللّٰهُمَّ صَلِّ عَلَىٰ مُحَمَّد',
    transliteration: 'Allāhumma ṣalli ʿalā Muḥammad',
    target: 100,
  );

  static const subhanAllahiWaBihamdihi = ZikrItem(
    name: "Subhan Allahi wa bihamdihi",
    arabic: 'سُبْحَانَ اللّٰهِ وَبِحَمْدِهِ',
    transliteration: 'Subḥāna-llāhi wa bi-ḥamdihi',
    target: 100,
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

  /// The two "Prayer Zikr" presets shown in the dashboard header.
  static const List<ZikrPreset> prayerPresets = [
    ZikrPreset(
      name: 'Prayer Zikr 1',
      formula: '33 +33 +34',
      items: [subhanAllah, alhamdulillah, allahuAkbar],
    ),
    ZikrPreset(
      name: 'Prayer Zikr 2',
      formula: '33 +33 +33 +1',
      items: [
        subhanAllah,
        alhamdulillah,
        ZikrItem(
          name: 'Allahu Akbar',
          arabic: 'اَللّٰهُ أَكْبَر',
          transliteration: 'Allāhu akbar',
          target: 33,
        ),
        ZikrItem(
          name: 'La ilaha illallah',
          arabic: 'لَا إِلٰهَ إِلَّا اللّٰه',
          transliteration: 'Lā ilāha illā-llāh',
          target: 1,
        ),
      ],
    ),
  ];

  /// The single "My Created Zikr" card shown on the dashboard (mock data).
  static const ZikrPreset createdSample = ZikrPreset(
    name: 'Prayer Zikr',
    formula: '33 +33 +34',
    items: [subhanAllah, alhamdulillah, allahuAkbar],
  );

  /// Names shown in the "Select Zikr" dropdown (design `devImg/img_14.png`).
  static const List<ZikrItem> dropdownItems = [
    subhanAllah,
    alhamdulillah,
    allahuAkbar,
  ];

  /// Mock finished plans for the planner's "Complete Plan" tab.
  static const List<ZikrPlan> mockCompletedPlans = [
    ZikrPlan(
      name: 'Subhan-Allah',
      days: 30,
      completed: true,
      entries: [ZikrPlanEntry(name: 'Subhan-Allah', value: 5000)],
    ),
    ZikrPlan(
      name: 'Allahu Akbar',
      days: 30,
      completed: true,
      entries: [ZikrPlanEntry(name: 'Allahu Akbar', value: 5000)],
    ),
  ];

  // --- Mock dashboard numbers ---------------------------------------------

  static const int mockTotalCount = 176337;
  static const ZikrItem mockLastZikr = subhanAllah;
  static const int mockLastZikrDone = 28;

  /// Formats [mockTotalCount] the Indian way — "1,76,337".
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
