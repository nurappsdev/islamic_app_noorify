import 'package:dartz/dartz.dart';

import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/ebook.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_category_page.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_detail_page.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_last_read.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_library_book.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_plan.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_plan_draft.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_read_record.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_reading_comparison.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_reading_history.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_reading_progress.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_sub_category_page.dart';

abstract interface class HadithLibraryRepository {
  /// The hadith collections of the library (`GET /hadiths/books/lists`),
  /// in the server's display order.
  Future<Either<Failure, List<HadithLibraryBook>>> getBooks();

  /// The active e-books of the library (`GET /ebooks`), in the server's
  /// display order.
  Future<Either<Failure, List<Ebook>>> getEbooks();

  /// One page of the categories (chapters) of a collection
  /// (`GET /hadiths/categories?bookId=...&page=...&limit=...`), in display
  /// order.
  ///
  /// [searchTerm] filters by the category's Bangla, Arabic or English name.
  Future<Either<Failure, HadithCategoryPage>> getCategories(
    String bookId, {
    required int page,
    required int limit,
    String? searchTerm,
  });

  /// One page of a category's sub-categories
  /// (`GET /hadiths/categories/{categoryId}/subcategories`), in display
  /// order. [searchTerm] filters by name.
  Future<Either<Failure, HadithSubCategoryPage>> getSubCategories(
    String categoryId, {
    required int page,
    required int limit,
    String? searchTerm,
  });

  /// Reports the active reading time of one or more hadiths (`POST
  /// /learning/reading/track`). [date] is `YYYY-MM-DD`.
  Future<Either<Failure, Unit>> trackReading({
    required List<String> hadithIds,
    required int seconds,
    required bool completed,
    required String date,
  });

  /// The reading progress overall and per category
  /// (`GET /hadiths/reading/progress/categories`, needs the login token).
  Future<Either<Failure, HadithReadingProgress>> getReadingProgress();

  /// The reading progress overall and per sub-category
  /// (`GET /hadiths/reading/progress/sub-categories`, needs the login token).
  Future<Either<Failure, HadithReadingProgress>>
  getSubCategoryReadingProgress();

  /// The reading day by day between [from] and [to] (`YYYY-MM-DD`, inclusive)
  /// with totals (`GET /learning/reading/history`, needs the login token).
  Future<Either<Failure, HadithReadingHistory>> getReadingHistory({
    required String from,
    required String to,
  });

  /// The user next to another reader between [from] and [to] (`YYYY-MM-DD`,
  /// inclusive) (`GET /hadiths/reading/history/compare`, needs the login
  /// token).
  Future<Either<Failure, HadithReadingComparison>> getReadingComparison({
    required String from,
    required String to,
  });

  /// One page of the hadiths the user read, most recent first
  /// (`GET /hadiths/reading/recent?page=...&limit=...`, needs the login
  /// token).
  Future<Either<Failure, HadithReadRecordPage>> getReadRecords({
    required int page,
    required int limit,
  });

  /// One page of the user's reading plans, each with its hadith counts
  /// (`GET /hadiths/plans?status=...&page=...&limit=...`, needs the login
  /// token). [status] is `in_progress`, `completed` or `abandoned`; every
  /// plan when null.
  Future<Either<Failure, HadithPlanPage>> getPlans({
    String? status,
    required int page,
    required int limit,
  });

  /// Creates a reading plan (`POST /hadiths/plans`, needs the login token).
  /// Fails with a [ServerFailure] carrying the API's message, e.g. when the
  /// name is already taken or nothing was selected.
  Future<Either<Failure, Unit>> createPlan(HadithPlanDraft draft);

  /// Renames a plan and / or changes its target days
  /// (`PATCH /hadiths/plans/{id}`, needs the login token). Fails with the
  /// API's message, e.g. when the new name is already taken.
  Future<Either<Failure, Unit>> updatePlan(
    String id, {
    String? name,
    int? targetDays,
  });

  /// Deletes a plan (`DELETE /hadiths/plans/{id}`, needs the login token).
  Future<Either<Failure, Unit>> deletePlan(String id);

  /// The hadith read most recently (`GET /hadiths/reading/last-read`, needs
  /// the login token); null when nothing has been read yet.
  Future<Either<Failure, HadithLastRead?>> getLastRead();

  /// One page of the hadiths of a sub-category
  /// (`GET /hadiths?subCategoryId=...&page=...&limit=...`) or of a whole book
  /// (`...&bookId=...`), in display order; or of one reading plan
  /// (`GET /hadiths/plans/{planId}/hadiths`, needs the login token). Pass one
  /// of [subCategoryId] / [bookId] / [planId].
  Future<Either<Failure, HadithDetailPage>> getHadiths({
    String? subCategoryId,
    String? bookId,
    String? planId,
    required int page,
    required int limit,
  });

  /// The ids of the hadiths already marked as read within a scope (`GET
  /// /hadiths/reading/read?subCategoryId=...`, or `bookId=`/`planId=`, needs
  /// the login token). Pass one of [subCategoryId] / [bookId] / [planId].
  Future<Either<Failure, Set<String>>> getReadHadiths({
    String? subCategoryId,
    String? bookId,
    String? planId,
  });
}
