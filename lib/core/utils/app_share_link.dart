/// The app's own page on Google Play.
///
/// It goes under hadith (and any other) text the user copies out of the app,
/// so whoever they paste it to can find the app the text came from.
const String tuhfatulMuslimPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=com.tuhfatulmuslim.app&pcampaignid=web_share';

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
