abstract class HadithCategoryEvent {
  const HadithCategoryEvent();
}

/// Loads (or reloads) the first page of a collection's categories.
class LoadHadithCategories extends HadithCategoryEvent {
  const LoadHadithCategories(this.bookId);

  final String bookId;
}

/// Loads the next page; ignored while a load is running or after the last
/// page.
class LoadMoreHadithCategories extends HadithCategoryEvent {
  const LoadMoreHadithCategories();
}
