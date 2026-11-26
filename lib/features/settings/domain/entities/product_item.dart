/// One app this team publishes, as listed by `GET /settings/our-products`.
class ProductItem {
  const ProductItem({
    required this.id,
    required this.name,
    this.tagline,
    this.logoUrl,
    this.appStoreUrl,
    this.playStoreUrl,
    this.isPublished = true,
  });

  final String id;
  final String name;
  final String? tagline;
  final String? logoUrl;
  final String? appStoreUrl;
  final String? playStoreUrl;
  final bool isPublished;

  /// Whether at least one store link can be opened.
  bool get hasStoreLink =>
      (appStoreUrl?.isNotEmpty ?? false) || (playStoreUrl?.isNotEmpty ?? false);
}
