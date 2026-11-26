import 'package:tuhfatul_muslim/features/settings/domain/entities/product_item.dart';

/// Reads one entry of `GET /settings/our-products`' `data` array:
/// ```json
/// {
///   "id": "tuhfatul-kids",
///   "name": "Tuhfatul Muslim Kids",
///   "tagline": "Islamic Learning for Children",
///   "logoUrl": "...",
///   "appStoreUrl": "https://...",
///   "playStoreUrl": "https://...",
///   "isPublished": true
/// }
/// ```
class ProductItemModel extends ProductItem {
  const ProductItemModel({
    required super.id,
    required super.name,
    super.tagline,
    super.logoUrl,
    super.appStoreUrl,
    super.playStoreUrl,
    super.isPublished,
  });

  factory ProductItemModel.fromJson(Map<String, dynamic> json) {
    return ProductItemModel(
      id: (json['id'] ?? json['_id'] ?? json['slug'] ?? '').toString(),
      name: _text(json['name']) ?? _text(json['title']) ?? '',
      tagline: _text(json['tagline']) ?? _text(json['description']),
      logoUrl: _text(json['logoUrl']) ?? _text(json['iconUrl']),
      appStoreUrl: _text(json['appStoreUrl']) ?? _text(json['iosUrl']),
      playStoreUrl: _text(json['playStoreUrl']) ?? _text(json['androidUrl']),
      // Absent means published, so a payload without the flag still shows.
      isPublished: json['isPublished'] != false,
    );
  }

  static String? _text(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
