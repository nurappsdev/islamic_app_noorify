import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_last_read.dart';

Map<String, dynamic> _map(Object? value) =>
    value is Map<String, dynamic> ? value : const <String, dynamic>{};

String _string(Object? value) => value?.toString() ?? '';

class HadithLastReadModel extends HadithLastRead {
  const HadithLastReadModel({
    required super.hadithId,
    required super.hadithNumber,
    required super.sourceBangla,
    required super.sourceEnglish,
    required super.bookId,
    required super.subCategoryId,
    required super.subCategoryNameBangla,
    required super.subCategoryNameEnglish,
  });

  /// [lastRead] is `data.lastRead`; its `hadithId`, `bookId` and
  /// `subCategoryId` are populated objects.
  factory HadithLastReadModel.fromJson(Map<String, dynamic> lastRead) {
    final hadith = _map(lastRead['hadithId']);
    final book = _map(lastRead['bookId']);
    final subCategory = _map(lastRead['subCategoryId']);
    return HadithLastReadModel(
      hadithId: _string(hadith['_id']),
      hadithNumber: (hadith['hadithNumber'] as num?)?.toInt() ?? 0,
      // The book carries the source names; the hadith has them too.
      sourceBangla: _string(book['sourceBangla'] ?? hadith['sourceBangla']),
      sourceEnglish: _string(book['sourceEnglish'] ?? hadith['sourceEnglish']),
      bookId: _string(book['_id']),
      subCategoryId: _string(subCategory['_id']),
      subCategoryNameBangla: _string(
        subCategory['nameBangla'] ?? subCategory['name'],
      ),
      subCategoryNameEnglish: _string(subCategory['nameEnglish']),
    );
  }
}
