import 'package:flutter/services.dart' show rootBundle;
import 'package:xml/xml.dart';

/// Publication details for a hadith book, parsed from its bundled reference
/// file (e.g. `assets/hadith/fourty_hadith_ref.xml`). Shown in the reader
/// drawer.
class HadithBookReference {
  const HadithBookReference({
    required this.titleBn,
    required this.titleAr,
    required this.titleEn,
    required this.authorBn,
    required this.authorAr,
    required this.translatorBn,
    required this.translatorAr,
    required this.editorsBn,
    required this.editorsAr,
    required this.publisher,
    required this.yearGregorian,
    required this.yearHijri,
    required this.totalHadiths,
  });

  final String titleBn;
  final String titleAr;
  final String titleEn;
  final String authorBn;
  final String authorAr;
  final String translatorBn;
  final String translatorAr;
  final String editorsBn;
  final String editorsAr;
  final String publisher;
  final String yearGregorian;
  final String yearHijri;
  final int totalHadiths;

  /// Loads and parses the first `<row>` of the reference file at [assetPath].
  /// Returns null if the file is missing or malformed.
  static Future<HadithBookReference?> load(String assetPath) async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final rows = XmlDocument.parse(raw).findAllElements('row');
      if (rows.isEmpty) return null;
      final row = rows.first;
      String text(String tag) => row.getElement(tag)?.innerText.trim() ?? '';
      return HadithBookReference(
        titleBn: text('title_bn'),
        titleAr: text('title_ar'),
        titleEn: text('title_en'),
        authorBn: text('author_bn'),
        authorAr: text('author_ar'),
        translatorBn: text('translator_bn'),
        translatorAr: text('translator_ar'),
        editorsBn: text('editors_bn'),
        editorsAr: text('editors_ar'),
        publisher: text('publisher'),
        yearGregorian: text('year_gregorian'),
        yearHijri: text('year_hijri'),
        totalHadiths: int.tryParse(text('total_hadiths')) ?? 0,
      );
    } catch (_) {
      return null;
    }
  }
}
