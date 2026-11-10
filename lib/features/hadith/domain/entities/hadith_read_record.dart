/// One entry of the user's reading history (`GET /hadiths/reading/recent`):
/// a hadith read, and when.
class HadithReadRecord {
  const HadithReadRecord({
    required this.id,
    required this.hadithNumber,
    required this.subCategoryName,
    required this.subCategoryNameBangla,
    required this.subCategoryNameEnglish,
    required this.lastReadAt,
  });

  final String id;
  final int hadithNumber;

  /// The sub-category (chapter) the hadith belongs to, in the API's own
  /// `name` and its Bangla / English forms.
  final String subCategoryName;
  final String subCategoryNameBangla;
  final String subCategoryNameEnglish;

  /// When it was last read, in the device's local time; null if the API sent
  /// none.
  final DateTime? lastReadAt;

  /// The sub-category name in the chosen language, falling back to the other
  /// one and then to `name` when it is empty.
  String title({required bool bangla}) {
    final preferred = bangla ? subCategoryNameBangla : subCategoryNameEnglish;
    final other = bangla ? subCategoryNameEnglish : subCategoryNameBangla;
    return [
      preferred,
      subCategoryName,
      other,
    ].firstWhere((n) => n.isNotEmpty, orElse: () => '');
  }
}

/// One page of `GET /hadiths/reading/recent` plus its pagination `meta`.
class HadithReadRecordPage {
  const HadithReadRecordPage({
    required this.records,
    required this.page,
    required this.totalPage,
    required this.total,
  });

  final List<HadithReadRecord> records;
  final int page;
  final int totalPage;
  final int total;

  bool get hasMore => page < totalPage;
}
