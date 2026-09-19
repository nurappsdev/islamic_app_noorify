abstract class HadithSubCategoryEvent {
  const HadithSubCategoryEvent();
}

/// Loads (or reloads) the first page of a category's sub-categories.
class LoadHadithSubCategories extends HadithSubCategoryEvent {
  const LoadHadithSubCategories(this.categoryId);

  final String categoryId;
}

/// Loads the next page; ignored while a load is running or after the last
/// page.
class LoadMoreHadithSubCategories extends HadithSubCategoryEvent {
  const LoadMoreHadithSubCategories();
}

/// Re-runs the list from page 1 filtered by [term]; empty clears the filter.
class SearchHadithSubCategories extends HadithSubCategoryEvent {
  const SearchHadithSubCategories(this.term);

  final String term;
}
