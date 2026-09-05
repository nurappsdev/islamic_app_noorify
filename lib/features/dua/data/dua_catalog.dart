import 'package:flutter/material.dart';

/// Static content for the Dua feature.
///
/// The Dua screens are UI-only for now — nothing here is persisted. Category
/// and featured-card names mirror the design mocks (`devImg/img_1.png`,
/// `img_2.png`, `img_3.png`) the same way the Zikr feature keeps its mock
/// content in [ZikrCatalog] rather than in [AppText].
class DuaCategory {
  const DuaCategory({required this.name, required this.icon});

  final String name;
  final IconData icon;
}

/// A "Duas for help"-style card shown on the Featured Dua row/screen.
class DuaFeatured {
  const DuaFeatured({required this.title, required this.totalDua});

  final String title;
  final int totalDua;
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
    DuaFeatured(title: 'Duas for help', totalDua: 132),
    DuaFeatured(title: 'Duas for help', totalDua: 132),
  ];

  /// Mock individual dua entries shown under a [DuaFeatured] group's
  /// "All dua" list (design `img_4.png` / `img_5.png`). Every featured group
  /// currently shares this same demo list.
  static const List<String> groupDuaNames = [
    'Dua - 1',
    'Dua - 2',
    'Dua - 3',
    'Dua - 4',
    'Dua - 5',
  ];

  /// The mock "Last read" index shown on [DuaGroupScreen] (design
  /// `img_4.png`: "Last read : Dua ( 03 )").
  static const int mockLastReadIndex = 3;
}
