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

const kDefaultArabicFontId = 'indopak_nastaleeq';

/// The bundled Quranic typeface (assets/fonts/quran/IndopakNastaleeq.ttf)
/// used across the Quran module wherever Arabic text has a fixed font.
const kQuranArabicFontFamily = 'IndoPak Nastaleeq';

/// Arabic text zoom: the default (120%) and the range the slider and the
/// reader's pinch gesture allow.
const kDefaultArabicFontScale = 1.2;
const kMinArabicFontScale = 0.8;
const kMaxArabicFontScale = 2.5;

final List<ArabicFont> kArabicFonts = [
  // QuranWBW's IndoPak Nastaleeq (waqf lazim build), made for the Indo-Pak
  // script the server's Arabic text is written in.
  ArabicFont(
    id: kDefaultArabicFontId,
    label: 'IndoPak Nastaleeq',
    styleBuilder: (s) => s.copyWith(fontFamily: kQuranArabicFontFamily),
  ),
  ArabicFont(
    id: 'alqalam_quran_majeed',
    label: 'AlQalam Quran Majeed',
    styleBuilder: (s) => s.copyWith(fontFamily: 'AlQalam Quran Majeed'),
  ),
  // Bundled asset (assets/fonts/quran/Noorehuda.ttf), not Google Fonts:
  // freely licensed by its author at noorehidayat.org ("no copyright
  // notice, use freely").
  ArabicFont(
    id: 'noorehuda',
    label: 'Noorehuda',
    styleBuilder: (s) => s.copyWith(fontFamily: 'Noorehuda'),
  ),
  ArabicFont(
    id: 'amiri_quran',
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
];

ArabicFont arabicFontById(String id) => kArabicFonts.firstWhere(
  (f) => f.id == id,
  orElse: () => kArabicFonts.first,
);
