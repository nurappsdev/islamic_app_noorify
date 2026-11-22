import 'package:tuhfatul_muslim/features/promo_banner/domain/entities/promo_banner.dart';

class PromoBannerModel extends PromoBanner {
  const PromoBannerModel({
    required super.id,
    required super.title,
    required super.description,
    required super.imageUrl,
    required super.action,
    required super.actionUrl,
    super.displayOrder,
  });

  factory PromoBannerModel.fromJson(Map<String, dynamic> json) {
    final action = PromoBannerAction.fromJson(json['actionType']);
    final url = (json['actionUrl'] ?? '').toString().trim();
    return PromoBannerModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? json['image'] ?? '').toString().trim(),
      action: action,
      // `actionUrl` is documented as null for `none`, but a leftover value
      // alongside `actionType: "none"` must not become a live link either.
      actionUrl: action == PromoBannerAction.none || url == 'null' ? '' : url,
      displayOrder: switch (json['displayOrder']) {
        final num order => order.toInt(),
        final Object? order => int.tryParse('$order') ?? 0,
      },
    );
  }

  /// Reads the envelope's `data` array. Entries without an image are dropped
  /// rather than drawn as blanks, and the server's order is kept.
  static List<PromoBanner> listFrom(Object? data) => [
    if (data is List)
      for (final entry in data)
        if (entry is Map)
          PromoBannerModel.fromJson(Map<String, dynamic>.from(entry)),
  ].where((banner) => banner.isDisplayable).toList(growable: false);
}
