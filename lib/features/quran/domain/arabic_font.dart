import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A selectable Arabic typeface for rendering ayah text, backed by a Google
/// Fonts family (fetched and cached on first use, no bundled font assets
/// required).
class ArabicFont {
  const ArabicFont({
    required this.id,
    required this.label,
    required this.styleBuilder,
  });

  final String id;
  final String label;
  final TextStyle Function(TextStyle textStyle) styleBuilder;

  TextStyle apply(TextStyle base) => styleBuilder(base);
}

const kDefaultArabicFontId = 'amiri_quran';

final List<ArabicFont> kArabicFonts = [
  ArabicFont(
    id: kDefaultArabicFontId,
    label: 'Amiri Quran',
    styleBuilder: (s) => GoogleFonts.amiriQuran(textStyle: s),
  ),
  ArabicFont(
    id: 'amiri',
    label: 'Amiri',
    styleBuilder: (s) => GoogleFonts.amiri(textStyle: s),
  ),
  ArabicFont(
    id: 'scheherazade_new',
    label: 'Scheherazade New',
    styleBuilder: (s) => GoogleFonts.scheherazadeNew(textStyle: s),
  ),
  ArabicFont(
    id: 'noto_naskh_arabic',
    label: 'Noto Naskh Arabic',
    styleBuilder: (s) => GoogleFonts.notoNaskhArabic(textStyle: s),
  ),
  ArabicFont(
    id: 'lateef',
    label: 'Lateef',
    styleBuilder: (s) => GoogleFonts.lateef(textStyle: s),
  ),
  // Bundled asset (assets/fonts/quran/Noorehuda.ttf), not Google Fonts:
  // freely licensed by its author at noorehidayat.org ("no copyright
  // notice, use freely").
  ArabicFont(
    id: 'noorehuda',
    label: 'Noorehuda',
    styleBuilder: (s) => s.copyWith(fontFamily: 'Noorehuda'),
  ),
];

ArabicFont arabicFontById(String id) =>
    kArabicFonts.firstWhere((f) => f.id == id, orElse: () => kArabicFonts.first);
