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

/// Reloads the first page straight from the API (a pull to refresh), for the
/// scope the last [LoadHadithDetails] set.
class RefreshHadithDetails extends HadithDetailEvent {
  const RefreshHadithDetails();
}

/// Loads the next page; ignored while a load is running or after the last
/// page.
class LoadMoreHadithDetails extends HadithDetailEvent {
  const LoadMoreHadithDetails();
}
