/// The server sends a notification's `body` as HTML - `<div>`, `<br />` and
/// character entities (see `GET /notifications`). `NotificationDetailScreen`
/// renders that markup with `HtmlWidget`, but `NotificationCard` needs a
/// single clamped, ellipsised line of text, which HTML layout can't give.
///
/// This flattens the markup to plain text for that preview: block and line
/// breaks become spaces so words don't run together, remaining tags are
/// dropped, the common entities are decoded, and runs of whitespace collapse.
String notificationBodyPreview(String html) {
  if (html.isEmpty) return '';
  final text = html
      .replaceAll(_breakTag, ' ')
      .replaceAll(_anyTag, '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'")
      // Last, so a literal `&amp;lt;` doesn't decode twice.
      .replaceAll('&amp;', '&');
  return text.replaceAll(_whitespaceRun, ' ').trim();
}

final _breakTag = RegExp(
  r'<br\s*/?>|</(?:p|div|li|ul|ol|tr|h[1-6]|blockquote)\s*>',
  caseSensitive: false,
);
final _anyTag = RegExp(r'<[^>]*>');
final _whitespaceRun = RegExp(r'\s+');
