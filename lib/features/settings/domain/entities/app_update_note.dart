/// The current release notes, as returned by `GET /settings/new-updates`.
/// [content] is Markdown.
class AppUpdateNote {
  const AppUpdateNote({
    required this.title,
    required this.content,
    this.version,
    this.releaseDate,
  });

  final String title;
  final String content;
  final String? version;

  /// An ISO date as text (`2026-11-26`), exactly as the API sends it.
  final String? releaseDate;
}
