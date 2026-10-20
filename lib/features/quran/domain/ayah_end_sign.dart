/// The marks the IndoPak text puts on an ayah's last letter to end it: the
/// pause (waqf) signs ط (U+0615), ز (U+0617) and the small high ۖ ۗ ۘ ۙ ۚ ۛ ۜ
/// (U+06D6-06DC), the ruku sign (U+06E0, which the bundled font draws as an
/// ع badge) and the ones the font draws beside ط (U+0614, U+065A). The last
/// two also occur inside ayahs; only a trailing run is taken.
bool _isEndMark(int c) =>
    c == 0x0614 ||
    c == 0x0615 ||
    c == 0x0617 ||
    c == 0x065A ||
    c == 0x06E0 ||
    (c >= 0x06D6 && c <= 0x06DC);

/// Glyphs after the last word that the font draws on their own (a hizb
/// quarter, ruku or sajdah ornament), e.g. " \uF64C".
final _trailingGlyphs = RegExp('(\\s+[\uE000-\uF8FF]+)+\$');

/// An ayah's text with the end marks on its last letter taken off, to be
/// drawn over the ayah-number marker instead of in the last word's corner.
/// [sign] is empty when the ayah ends without one.
({String text, String sign}) splitAyahEndSign(String ayah) {
  final glyphs = _trailingGlyphs.firstMatch(ayah)?.group(0) ?? '';
  final body = ayah.substring(0, ayah.length - glyphs.length);
  var start = body.length;
  while (start > 0 && _isEndMark(body.codeUnitAt(start - 1))) {
    start--;
  }
  return (text: body.substring(0, start) + glyphs, sign: body.substring(start));
}
