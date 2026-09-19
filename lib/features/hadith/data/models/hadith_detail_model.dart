import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_detail.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_detail_page.dart';

class HadithDetailModel extends HadithDetail {
  const HadithDetailModel({
    required super.id,
    required super.hadithNumber,
    required super.hadithNumberInChapter,
    required super.textArabic,
    required super.textBangla,
    required super.textEnglish,
    required super.titleBangla,
    required super.titleEnglish,
    required super.narrator,
    required super.grade,
    required super.gradeBangla,
    required super.takhrij,
    required super.authorBangla,
    required super.authorEnglish,
    required super.sourceBangla,
    required super.sourceEnglish,
    required super.sectionNameBangla,
    required super.explanationEnglish,
  });

  factory HadithDetailModel.fromJson(Map<String, dynamic> json) {
    String str(String key) => json[key]?.toString() ?? '';
    int number(String key) => (json[key] as num?)?.toInt() ?? 0;

    return HadithDetailModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      hadithNumber: number('hadithNumber'),
      hadithNumberInChapter: number('hadithNumberInChapter'),
      // The API embeds `<br />` tags in some Arabic texts.
      textArabic: str(
        'textArabic',
      ).replaceAll(RegExp(r'<br\s*/?>'), '\n').trim(),
      // `textBangla` and `text` carry the same translation; either may be
      // missing.
      textBangla: (json['textBangla'] ?? json['text'])?.toString() ?? '',
      textEnglish: str('textEnglish'),
      titleBangla: str('titleBangla'),
      titleEnglish: str('titleEnglish'),
      narrator: str('narrator'),
      grade: str('grade'),
      gradeBangla: str('gradeBangla'),
      takhrij: str('takhrij'),
      authorBangla: str('authorBangla'),
      authorEnglish: str('authorEnglish'),
      sourceBangla: str('sourceBangla'),
      sourceEnglish: str('sourceEnglish'),
      sectionNameBangla: str('sectionNameBangla'),
      explanationEnglish: str('explanationEnglish'),
    );
  }
}

class HadithDetailPageModel extends HadithDetailPage {
  const HadithDetailPageModel({
    required super.hadiths,
    required super.page,
    required super.totalPage,
    required super.total,
  });

  factory HadithDetailPageModel.fromJson(
    List<Map<String, dynamic>> items,
    Map<String, dynamic> meta,
  ) {
    final hadiths = items.map(HadithDetailModel.fromJson).toList();
    return HadithDetailPageModel(
      hadiths: hadiths,
      page: (meta['page'] as num?)?.toInt() ?? 1,
      // Without `meta`, treat what we got as the only page.
      totalPage: (meta['totalPage'] as num?)?.toInt() ?? 1,
      total: (meta['total'] as num?)?.toInt() ?? hadiths.length,
    );
  }
}
