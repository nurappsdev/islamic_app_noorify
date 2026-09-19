import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_library_book.dart';

enum HadithLibraryStatus { initial, loading, success, failure }

class HadithLibraryState {
  const HadithLibraryState({
    this.status = HadithLibraryStatus.initial,
    this.books = const [],
    this.failure,
  });

  final HadithLibraryStatus status;
  final List<HadithLibraryBook> books;
  final Failure? failure;

  bool get isLoading =>
      status == HadithLibraryStatus.initial ||
      status == HadithLibraryStatus.loading;

  /// Sum of every collection's hadith count — the header's "Total Hadith".
  int get totalHadiths => books.fold(0, (sum, b) => sum + b.totalHadiths);
}
