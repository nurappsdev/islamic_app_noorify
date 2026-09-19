abstract class HadithDetailEvent {
  const HadithDetailEvent();
}

/// Loads (or reloads) the first page of the hadiths of a sub-category or of a
/// whole book — pass one of [subCategoryId] / [bookId].
class LoadHadithDetails extends HadithDetailEvent {
  const LoadHadithDetails({this.subCategoryId, this.bookId});

  final String? subCategoryId;
  final String? bookId;
}

/// Loads the next page; ignored while a load is running or after the last
/// page.
class LoadMoreHadithDetails extends HadithDetailEvent {
  const LoadMoreHadithDetails();
}
