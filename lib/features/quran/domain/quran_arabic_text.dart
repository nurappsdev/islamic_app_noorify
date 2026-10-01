/// Characters the Quran text source ships that should not be shown.
///
/// U+FB64 (ﭤ, "teheh initial form") is a glyph-encoded mark the source puts
/// at the end of many ayahs (483 of them, e.g. 1:4, 2:4); in the app's fonts it
/// renders as a stray letter.
const _hiddenQuranMarks = 'ﭤ';

/// [text] without [_hiddenQuranMarks], and without the space they leave at
/// the end of an ayah.
String cleanQuranArabic(String text) {
  if (!text.contains(RegExp('[$_hiddenQuranMarks]'))) return text;
  return text.replaceAll(RegExp('[$_hiddenQuranMarks]'), '').trimRight();
}
