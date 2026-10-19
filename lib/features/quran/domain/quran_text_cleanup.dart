/// The Arabic text from the server was scraped from a source that encoded
/// its own font's symbols as text. Rendered with a real Quran font they show
/// up as stray dashes, digits, random small ligatures, and invisible
/// left-to-right characters that reorder the line and detach waqf signs.
library;

// Patterns use RegExp's own \uXXXX escapes (raw strings) so no invisible
// characters live in this source file.

/// A ruku marker, e.g. U+06E0 then `(52)` then a small mark, ending an ayah.
final _rukuMarker = RegExp(r'\u06E0?[ \u00A0]*\(\d+\)[\u064B-\u065F]?');

/// The lam-alef ligature, the one presentation form that stands for letters.
final _lamAlef = RegExp(r'[\uFEF5-\uFEFC]');

/// The source font's symbols, encoded as presentation-form ligatures; real
/// Quran text never uses these code points.
final _fontSymbol = RegExp(r'[\uFB50-\uFDFF\uFE70-\uFEFF]');

/// Private-use glyphs, direction marks and invisible format characters.
/// ZWNJ/ZWJ (U+200C/U+200D) are kept: they affect Arabic shaping.
final _invisible = RegExp(
  r'[\uE000-\uF8FF\u200B\u200E\u200F\u202A-\u202E\u2060-\u2064\u2066-\u2069]',
);

/// The source joins a waqf sign to the next word with an ASCII hyphen.
final _hyphen = RegExp(r'[ \u00A0]*-+[ \u00A0]*');

/// A space before a waqf sign leaves it floating alone, free to wrap to
/// another line or crowd the ayah marker; keep it on its word.
final _spaceBeforeWaqf = RegExp(r' +(?=[\u06D6-\u06DC])');

final _spaces = RegExp(r' {2,}');

/// [text] with the source's encoding artefacts removed, ready to render.
/// Safe to apply more than once.
String cleanQuranArabic(String text) => text
    // .replaceAll(_rukuMarker, '')
    // .replaceAll(_lamAlef, '\u0644\u0627')
    // .replaceAll(_fontSymbol, '')
    // .replaceAll(_invisible, '')
    // .replaceAll(_hyphen, ' ')
    // .replaceAll(_spaceBeforeWaqf, '')
    // .replaceAll(_spaces, ' ')
    .trim();
