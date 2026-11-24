import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/hadith/domain/entities/hadith_category.dart';
import 'package:tuhfatul_muslim/features/hadith/domain/entities/hadith_category_page.dart';
import 'package:tuhfatul_muslim/features/hadith/domain/entities/hadith_detail.dart';
import 'package:tuhfatul_muslim/features/hadith/domain/entities/hadith_detail_page.dart';
import 'package:tuhfatul_muslim/features/hadith/domain/entities/hadith_sub_category.dart';
import 'package:tuhfatul_muslim/features/hadith/domain/entities/hadith_sub_category_page.dart';
import 'package:tuhfatul_muslim/features/hadith/domain/repositories/hadith_library_repository.dart';
import 'package:tuhfatul_muslim/features/hadith/domain/usecases/get_hadith_categories.dart';
import 'package:tuhfatul_muslim/features/hadith/domain/usecases/get_hadith_details.dart';
import 'package:tuhfatul_muslim/features/hadith/domain/usecases/get_hadith_sub_categories.dart';
import 'package:tuhfatul_muslim/features/hadith/presentation/bloc/hadith_category/hadith_category_bloc.dart';
import 'package:tuhfatul_muslim/features/hadith/presentation/bloc/hadith_detail/hadith_detail_bloc.dart';
import 'package:tuhfatul_muslim/features/hadith/presentation/bloc/hadith_sub_category/hadith_sub_category_bloc.dart';
import 'package:tuhfatul_muslim/features/hadith/presentation/widgets/hadith_list_scaffold.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

/// A book added in the admin dashboard: the app has never seen its ids.
const _bookId = 'new-book';
const _categoryId = 'new-category';
const _subCategoryId = 'new-chapter';

/// One hadith as the dashboard-built book serves it: the fields seeded books
/// carry on top of this (citations, Arabic title, explanation) are absent.
HadithDetail _hadith(String id, int number) => HadithDetail(
  id: id,
  hadithNumber: number,
  hadithNumberInChapter: 0,
  textArabic: 'نص $number',
  textBangla: 'হাদিস $number',
  textEnglish: 'Hadith $number',
  titleBangla: 'শিরোনাম $number',
  titleEnglish: 'Title $number',
  chapter: 'chapter title bangla',
  narrator: '',
  grade: 'Sahih',
  gradeBangla: '',
  takhrij: '',
  authorBangla: '',
  authorEnglish: '',
  sourceBangla: '',
  sourceEnglish: '',
  sectionNameBangla: '',
  explanationEnglish: '',
);

/// Serves the new book's content, and records how it was asked.
class _Repository implements HadithLibraryRepository {
  final categoryCalls = <bool>[];
  final subCategoryCalls = <bool>[];
  final hadithCalls = <bool>[];

  @override
  Future<Either<Failure, HadithCategoryPage>> getCategories(
    String bookId, {
    required int page,
    required int limit,
    String? searchTerm,
    bool forceRefresh = false,
  }) async {
    categoryCalls.add(forceRefresh);
    return Right(
      HadithCategoryPage(
        categories: bookId == _bookId
            ? const [
                HadithCategory(
                  id: _categoryId,
                  bookId: _bookId,
                  name: 'category name 1',
                  nameBangla: 'category bangla name 1',
                  nameArabic: '',
                  sectionNumber: 1,
                  displayOrder: 1,
                  totalHadiths: 2,
                  // 0 even though chapters exist (dashboard-built book).
                  totalSubCategories: 0,
                ),
              ]
            : const [],
        page: 1,
        totalPage: 1,
        total: 1,
      ),
    );
  }

  @override
  Future<Either<Failure, HadithSubCategoryPage>> getSubCategories(
    String categoryId, {
    required int page,
    required int limit,
    String? searchTerm,
    bool forceRefresh = false,
  }) async {
    subCategoryCalls.add(forceRefresh);
    return Right(
      HadithSubCategoryPage(
        subCategories: categoryId == _categoryId
            ? const [
                HadithSubCategory(
                  id: _subCategoryId,
                  categoryId: _categoryId,
                  name: 'chapter title bangla',
                  nameBangla: 'chapter title bangla',
                  nameEnglish: 'chapter title english',
                  nameArabic: 'chapter title arabic',
                  chapterNumber: 1,
                  displayOrder: 1,
                  totalHadiths: 2,
                ),
              ]
            : const [],
        page: 1,
        totalPage: 1,
        total: 1,
      ),
    );
  }

  @override
  Future<Either<Failure, HadithDetailPage>> getHadiths({
    String? subCategoryId,
    String? bookId,
    String? categoryId,
    String? planId,
    required int page,
    required int limit,
    bool forceRefresh = false,
  }) async {
    hadithCalls.add(forceRefresh);
    return Right(
      HadithDetailPage(
        hadiths: subCategoryId == _subCategoryId
            ? [_hadith('h1', 1), _hadith('h2', 2)]
            : const [],
        page: 1,
        totalPage: 1,
        total: 2,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

/// The scaffold the category and chapter screens are built on, wired the way
/// those screens wire it: a pull reloads the list straight from the API.
Widget _list({required Future<void> Function() onRefresh}) => ScreenUtilInit(
  designSize: const Size(390, 844),
  builder: (_, _) => BlocProvider(
    create: (_) => LanguageBloc(),
    child: MaterialApp(
      home: HadithListScaffold(
        title: 'Hadith Category',
        onRefresh: onRefresh,
        children: const [SizedBox(height: 40, child: Text('ROW'))],
      ),
    ),
  ),
);

void main() {
  group('a book added on the server', () {
    late _Repository repository;

    setUp(() => repository = _Repository());

    test('loads its categories, chapters and hadiths by id', () async {
      final categories = HadithCategoryBloc(GetHadithCategories(repository))
        ..add(const LoadHadithCategories(_bookId));
      final categoryState = await categories.stream.firstWhere(
        (s) => !s.isLoading,
      );
      expect(categoryState.categories.single.id, _categoryId);

      final chapters = HadithSubCategoryBloc(GetHadithSubCategories(repository))
        ..add(const LoadHadithSubCategories(_categoryId));
      final chapterState = await chapters.stream.firstWhere(
        (s) => !s.isLoading,
      );
      expect(chapterState.subCategories.single.id, _subCategoryId);

      final hadiths = HadithDetailBloc(GetHadithDetails(repository))
        ..add(const LoadHadithDetails(subCategoryId: _subCategoryId));
      final hadithState = await hadiths.stream.firstWhere((s) => !s.isLoading);
      expect(hadithState.hadiths.map((h) => h.id), ['h1', 'h2']);

      // A first open reads whatever is stored; it is the pull that must not.
      expect(repository.categoryCalls, [false]);
      expect(repository.subCategoryCalls, [false]);
      expect(repository.hadithCalls, [false]);

      await Future.wait([
        categories.close(),
        chapters.close(),
        hadiths.close(),
      ]);
    });

    test('a refresh asks the API for each of the three lists', () async {
      final categories = HadithCategoryBloc(GetHadithCategories(repository))
        ..add(const LoadHadithCategories(_bookId));
      await categories.stream.firstWhere((s) => !s.isLoading);
      categories.add(const RefreshHadithCategories());
      await categories.stream.firstWhere((s) => !s.isLoading);
      expect(repository.categoryCalls, [false, true]);

      final chapters = HadithSubCategoryBloc(GetHadithSubCategories(repository))
        ..add(const LoadHadithSubCategories(_categoryId));
      await chapters.stream.firstWhere((s) => !s.isLoading);
      chapters.add(const RefreshHadithSubCategories());
      await chapters.stream.firstWhere((s) => !s.isLoading);
      expect(repository.subCategoryCalls, [false, true]);

      final hadiths = HadithDetailBloc(GetHadithDetails(repository))
        ..add(const LoadHadithDetails(subCategoryId: _subCategoryId));
      await hadiths.stream.firstWhere((s) => !s.isLoading);
      hadiths.add(const RefreshHadithDetails());
      await hadiths.stream.firstWhere((s) => !s.isLoading);
      expect(repository.hadithCalls, [false, true]);

      await Future.wait([
        categories.close(),
        chapters.close(),
        hadiths.close(),
      ]);
    });

    // A refresh that keeps the scope is what makes an empty screen fixable
    // without reinstalling: the same ids, asked of the API again.
    test('a refresh keeps the collection it was loaded with', () async {
      final categories = HadithCategoryBloc(GetHadithCategories(repository))
        ..add(const LoadHadithCategories(_bookId));
      await categories.stream.firstWhere((s) => !s.isLoading);
      categories.add(const RefreshHadithCategories());
      final refreshed = await categories.stream.firstWhere((s) => !s.isLoading);
      expect(refreshed.categories.single.id, _categoryId);
      await categories.close();
    });
  });

  // The pull itself: the scaffold the category and chapter screens are built
  // on has to call back on a pull and stop spinning when that work is done.
  // (What the callback asks the API is covered above.)
  testWidgets('a pull calls back, and the spinner stops with it', (
    tester,
  ) async {
    var pulls = 0;
    final work = Completer<void>();

    await tester.pumpWidget(
      _list(
        onRefresh: () {
          pulls++;
          return work.future;
        },
      ),
    );
    await tester.pump();

    await tester.fling(find.text('ROW'), const Offset(0, 300), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(pulls, 1, reason: 'a pull has to reload the list');
    expect(find.byType(RefreshProgressIndicator), findsOneWidget);

    work.complete();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(RefreshProgressIndicator), findsNothing);
  });
}
