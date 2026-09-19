import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_library_book.dart';

class HadithLibraryBookModel extends HadithLibraryBook {
  const HadithLibraryBookModel({
    required super.id,
    required super.titleEn,
    required super.titleBn,
    required super.titleAr,
    required super.authorEn,
    required super.authorBn,
    required super.totalHadiths,
    required super.totalCategories,
    required super.totalSubCategories,
    required super.displayOrder,
  });

  factory HadithLibraryBookModel.fromJson(Map<String, dynamic> json) =>
      HadithLibraryBookModel(
        id: (json['_id'] ?? json['id'])?.toString() ?? '',
        titleEn: json['sourceEnglish'] as String? ?? '',
        titleBn: json['sourceBangla'] as String? ?? '',
        titleAr: json['sourceArabic'] as String? ?? '',
        authorEn: json['authorEnglish'] as String? ?? '',
        authorBn: json['authorBangla'] as String? ?? '',
        totalHadiths: (json['totalHadiths'] as num?)?.toInt() ?? 0,
        totalCategories: (json['totalCategories'] as num?)?.toInt() ?? 0,
        totalSubCategories: (json['totalSubCategories'] as num?)?.toInt() ?? 0,
        displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      );
}
