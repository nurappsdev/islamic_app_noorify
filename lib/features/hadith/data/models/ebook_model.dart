import 'package:islami_app_noorify/features/hadith/domain/entities/ebook.dart';

class EbookModel extends Ebook {
  const EbookModel({
    required super.id,
    required super.title,
    required super.author,
    required super.category,
    required super.coverImageUrl,
    required super.pdfFileUrl,
    required super.totalPages,
    required super.description,
    required super.language,
    required super.displayOrder,
    required super.isActive,
  });

  factory EbookModel.fromJson(Map<String, dynamic> json) => EbookModel(
    id: (json['_id'] ?? json['id'])?.toString() ?? '',
    title: json['title'] as String? ?? '',
    author: json['author'] as String? ?? '',
    category: json['category'] as String? ?? '',
    coverImageUrl: json['coverImageUrl'] as String? ?? '',
    pdfFileUrl: json['pdfFileUrl'] as String? ?? '',
    totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
    description: json['description'] as String? ?? '',
    language: json['language'] as String? ?? '',
    displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
    isActive: json['isActive'] as bool? ?? true,
  );
}
