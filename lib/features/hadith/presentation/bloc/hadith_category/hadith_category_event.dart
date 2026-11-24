abstract class HadithCategoryEvent {
  const HadithCategoryEvent();
}

/// Loads (or reloads) the first page of a collection's categories.
class LoadHadithCategories extends HadithCategoryEvent {
  const LoadHadithCategories(this.bookId);

  final String bookId;
}

/// Reloads the first page straight from the API (a pull to refresh), keeping
/// the collection and any search term in place.
class RefreshHadithCategories extends HadithCategoryEvent {
  const RefreshHadithCategories();
}

/// Loads the next page; ignored while a load is running or after the last
/// page.
class LoadMoreHadithCategories extends HadithCategoryEvent {
  const LoadMoreHadithCategories();
}

/// Re-runs the list from page 1 filtered by [term] (Bangla, Arabic or English
/// category name); an empty term clears the filter.
class SearchHadithCategories extends HadithCategoryEvent {
  const SearchHadithCategories(this.term);

  final String term;
}
