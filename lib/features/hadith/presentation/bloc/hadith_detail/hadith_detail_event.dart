abstract class HadithDetailEvent {
  const HadithDetailEvent();
}

/// Loads (or reloads) the first page of the hadiths of a sub-category, of a
/// whole category, of a whole book or of a reading plan — pass one of
/// [subCategoryId] / [categoryId] / [bookId] / [planId].
class LoadHadithDetails extends HadithDetailEvent {
  const LoadHadithDetails({
    this.subCategoryId,
    this.bookId,
    this.categoryId,
    this.planId,
  });

  final String? subCategoryId;
  final String? bookId;
  final String? categoryId;
  final String? planId;
}

/// Loads the next page; ignored while a load is running or after the last
/// page.
class LoadMoreHadithDetails extends HadithDetailEvent {
  const LoadMoreHadithDetails();
}
