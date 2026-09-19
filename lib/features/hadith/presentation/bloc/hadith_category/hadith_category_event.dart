abstract class HadithCategoryEvent {
  const HadithCategoryEvent();
}

class LoadHadithCategories extends HadithCategoryEvent {
  const LoadHadithCategories(this.bookId);

  final String bookId;
}
