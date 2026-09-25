/// Which legal page to load from `/settings/...`.
enum LegalDocumentType { termsOfService, privacyPolicy }

/// A Terms of Service / Privacy Policy page. [content] is an HTML fragment.
class LegalDocument {
  const LegalDocument({
    required this.title,
    required this.content,
    this.effectiveDate,
    this.lastUpdated,
  });

  final String title;
  final String content;
  final String? effectiveDate;
  final String? lastUpdated;
}
