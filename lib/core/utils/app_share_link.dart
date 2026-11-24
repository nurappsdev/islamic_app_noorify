/// The app's own page on Google Play.
///
/// It goes under hadith (and any other) text the user copies out of the app,
/// so whoever they paste it to can find the app the text came from.
const String tuhfatulMuslimPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=com.tuhfatulmuslim.app&pcampaignid=web_share';

/// The citation that goes under copied hadith text: which hadith it is, the
/// book it came from, and the hadith's own reference line when it has one.
///
/// Reads as `Hadith No: 1 — Forty Hadith` with `Reference: Bukhari 1` under
/// it. [book] and [referenceLine] are left out when empty, so a hadith with
/// neither still says which number it is.
String hadithCitation({
  required String numberLabel,
  required String number,
  String book = '',
  String referenceLine = '',
}) {
  final head = [
    '$numberLabel: $number',
    book.trim(),
  ].where((part) => part.isNotEmpty).join(' — ');
  return [
    head,
    referenceLine.trim(),
  ].where((line) => line.isNotEmpty).join('\n');
}

/// [text] with [invitation] and [tuhfatulMuslimPlayStoreUrl] under it, a blank
/// line between each, ready for the clipboard or a share sheet.
///
/// Empty [text] stays empty: copying nothing must not put a bare advert on
/// the clipboard. An empty [invitation] is left out, so the link still
/// follows the text.
String withAppLink(String text, String invitation) {
  final body = text.trim();
  if (body.isEmpty) return '';
  return [
    body,
    invitation.trim(),
    tuhfatulMuslimPlayStoreUrl,
  ].where((line) => line.isNotEmpty).join('\n\n');
}
