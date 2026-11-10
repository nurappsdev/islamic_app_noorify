import 'package:flutter/material.dart';

/// Static content for the Dua feature.
///
/// The Dua screens are UI-only for now — nothing here is persisted. Category
/// and featured-card names mirror the design mocks (`devImg/img_1.png` …
/// `img_6.png`) the same way the Zikr feature keeps its mock content in
/// [ZikrCatalog] rather than in [AppText].
class DuaCategory {
  const DuaCategory({required this.name, required this.icon});

  final String name;
  final IconData icon;
}

/// A "Duas for help"-style card shown on the Featured Dua row/screen.
class DuaFeatured {
  const DuaFeatured({
    required this.title,
    required this.totalDua,
    required this.groupLabel,
  });

  final String title;
  final int totalDua;

  /// The group's breadcrumb label, shown as the header title on both
  /// [DuaGroupScreen] and [DuaReaderScreen] (design `img_4.png` / `img_6.png`:
  /// both say "Daily Life").
  final String groupLabel;
}

/// One Arabic line + its translation inside a [DuaDetail] (design
/// `img_6.png`'s line-by-line Arabic/translation blocks).
class DuaSegment {
  const DuaSegment({required this.arabic, required this.translation});

  final String arabic;
  final String translation;
}

/// A single dua's reading content, shown on [DuaReaderScreen] (design
/// `img_6.png`).
class DuaDetail {
  const DuaDetail({
    required this.name,
    required this.segments,
    required this.transliteration,
    this.repeatCount,
  });

  final String name;
  final List<DuaSegment> segments;
  final String transliteration;

  /// How many times to recite this dua, e.g. 10 for "Dua - 3" below. Null
  /// when the source doesn't specify a count, in which case the reader hides
  /// the "Recite … times" line.
  final int? repeatCount;
}

abstract final class DuaCatalog {
  /// Every category shown on [DuaAllCategoryScreen] (design `img_2.png`:
  /// "Total Category ( 12 )").
  static const List<DuaCategory> categories = [
    DuaCategory(name: 'Sleep Dua', icon: Icons.nightlight_round),
    DuaCategory(name: 'Morning Dua', icon: Icons.wb_sunny_outlined),
    DuaCategory(name: 'Qurans Dua', icon: Icons.menu_book_rounded),
    DuaCategory(name: 'Ruqyah Dua', icon: Icons.shield_outlined),
    DuaCategory(name: 'Morning Dua', icon: Icons.wb_cloudy_outlined),
    DuaCategory(name: 'Qurans Dua', icon: Icons.menu_book_rounded),
    DuaCategory(name: 'Evening Dua', icon: Icons.wb_twilight),
    DuaCategory(name: 'Travel Dua', icon: Icons.flight_outlined),
    DuaCategory(name: 'Food Dua', icon: Icons.restaurant_outlined),
    DuaCategory(name: 'Protection Dua', icon: Icons.security_outlined),
    DuaCategory(name: 'Forgiveness Dua', icon: Icons.favorite_border_rounded),
    DuaCategory(name: 'Home Dua', icon: Icons.home_outlined),
  ];

  /// The first 6 tiles shown on the dashboard's "Duas Category" preview grid
  /// (design `img_1.png`).
  static List<DuaCategory> get dashboardCategories =>
      categories.take(6).toList();

  /// The Featured Dua cards (design `img_1.png` row / `img_3.png` full list:
  /// "Total Featured Dua ( 2 )").
  static const List<DuaFeatured> featured = [
    DuaFeatured(
      title: 'Duas for help',
      totalDua: 132,
      groupLabel: 'Daily Life',
    ),
    DuaFeatured(
      title: 'Duas for help',
      totalDua: 132,
      groupLabel: 'Daily Life',
    ),
  ];

  /// Mock individual dua entries shown under a [DuaFeatured] group's
  /// "All dua" list (design `img_4.png` / `img_5.png`) and read on
  /// [DuaReaderScreen] (design `img_6.png`). Every featured group currently
  /// shares this same demo list.
  static const List<DuaDetail> groupDuas = [
    DuaDetail(
      name: 'Dua - 1',
      segments: [
        DuaSegment(
          arabic: 'أَسْتَغْفِرُ اللّٰه',
          translation: 'আমি মহান আল্লাহর কাছে ক্ষমা প্রার্থনা করি',
        ),
      ],
      transliteration: 'Astaghfiru-llāh',
      repeatCount: 100,
    ),
    DuaDetail(
      name: 'Dua - 2',
      segments: [
        DuaSegment(
          arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ سُبْحَانَ اللَّهِ الْعَظِيمِ',
          translation: 'আল্লাহ পবিত্র ও তাঁরই প্রশংসা, আল্লাহ মহান তিনি পবিত্র',
        ),
      ],
      transliteration: "Subḥānallāhi wa biḥamdihi, subḥānallāhil-'aẓīm",
      repeatCount: 100,
    ),
    DuaDetail(
      name: 'Dua - 3',
      segments: [
        DuaSegment(
          arabic: 'لَا إِلَـٰهَ إِلَّا اللَّهُ وَحْدَهُ',
          translation: 'তিনি একক আল্লাহ ছাড়া কোনো সত্য মাবুদ নেই',
        ),
        DuaSegment(
          arabic: 'لَا شَرِيكَ لَهُ لَهُ الْمُلْكُ',
          translation: 'রাজত্ব তারই তার কোনো শরীক নেই',
        ),
        DuaSegment(
          arabic: 'وَلَهُ الْحَمْدُ وَهُوَ عَلَىٰ كُلِّ',
          translation: 'সকল উপর এবং তিনি সমস্ত প্রশংসা এবং তারই',
        ),
        DuaSegment(arabic: 'شَيْءٍ قَدِيرٌ', translation: 'ক্ষমতাবান কিছুর'),
      ],
      transliteration:
          "লা- ইলা-হা ইল্লাল্লা-হ, ওয়া'হাদাহ লা- শারীকা লাহ, লাহুল মুলকু ওয়া "
          "লাহুল 'হামদু, ওয়া হুৱা 'আলা- কুল্লি শাইয়িন কাদীর",
      repeatCount: 10,
    ),
    DuaDetail(
      name: 'Dua - 4',
      segments: [
        DuaSegment(
          arabic:
              'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ '
              'حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
          translation:
              'হে আমাদের রব, আমাদেরকে দুনিয়াতে কল্যাণ দাও এবং আখিরাতেও কল্যাণ '
              'দাও এবং আমাদেরকে জাহান্নামের আযাব থেকে রক্ষা কর',
        ),
      ],
      transliteration:
          "Rabbanā ātinā fid-dunyā ḥasanatan wa fil-ākhirati ḥasanatan wa "
          "qinā 'adhāban-nār",
    ),
    DuaDetail(
      name: 'Dua - 5',
      segments: [
        DuaSegment(
          arabic: 'رَبِّ زِدْنِي عِلْمًا',
          translation: 'হে আমার রব, আমার জ্ঞান বৃদ্ধি করে দাও',
        ),
      ],
      transliteration: 'Rabbi zidnī ʿilmā',
    ),
  ];

  /// The mock "Last read" index shown on [DuaGroupScreen] (design
  /// `img_4.png`: "Last read : Dua ( 03 )").
  static const int mockLastReadIndex = 3;
}
