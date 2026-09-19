abstract class HadithDetailEvent {
  const HadithDetailEvent();
}

/// Loads (or reloads) the first page of a sub-category's hadiths.
class LoadHadithDetails extends HadithDetailEvent {
  const LoadHadithDetails(this.subCategoryId);

  final String subCategoryId;
}

/// Loads the next page; ignored while a load is running or after the last
/// page.
class LoadMoreHadithDetails extends HadithDetailEvent {
  const LoadMoreHadithDetails();
}
