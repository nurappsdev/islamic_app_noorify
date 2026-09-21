import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_read_record.dart';

Map<String, dynamic> _map(Object? value) =>
    value is Map<String, dynamic> ? value : const <String, dynamic>{};

String _text(Object? value) => value?.toString() ?? '';

class HadithReadRecordModel extends HadithReadRecord {
  const HadithReadRecordModel({
    required super.id,
    required super.hadithNumber,
    required super.subCategoryName,
    required super.subCategoryNameBangla,
    required super.subCategoryNameEnglish,
    required super.lastReadAt,
  });

  /// [json] is one entry of `data`; its `hadithId` and `subCategoryId` are
  /// populated objects.
  factory HadithReadRecordModel.fromJson(Map<String, dynamic> json) {
    final hadith = _map(json['hadithId']);
    final subCategory = _map(json['subCategoryId']);
    return HadithReadRecordModel(
      id: _text(json['_id'] ?? json['id']),
      hadithNumber: (hadith['hadithNumber'] as num?)?.toInt() ?? 0,
      subCategoryName: _text(subCategory['name']),
      subCategoryNameBangla: _text(subCategory['nameBangla']),
      subCategoryNameEnglish: _text(subCategory['nameEnglish']),
      // ISO-8601 in UTC; shown in the user's own time.
      lastReadAt: DateTime.tryParse(_text(json['lastReadAt']))?.toLocal(),
    );
  }
}

class HadithReadRecordPageModel extends HadithReadRecordPage {
  const HadithReadRecordPageModel({
    required super.records,
    required super.page,
    required super.totalPage,
    required super.total,
  });

  factory HadithReadRecordPageModel.fromJson(
    List<Map<String, dynamic>> items,
    Map<String, dynamic> meta,
  ) {
    final records = items.map(HadithReadRecordModel.fromJson).toList();
    return HadithReadRecordPageModel(
      records: records,
      page: (meta['page'] as num?)?.toInt() ?? 1,
      // Without `meta`, treat what we got as the only page.
      totalPage: (meta['totalPage'] as num?)?.toInt() ?? 1,
      total: (meta['total'] as num?)?.toInt() ?? records.length,
    );
  }
}
