import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_category.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_category_page.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_library_book.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_plan_draft.dart';
import 'package:islami_app_noorify/features/hadith/domain/repositories/hadith_library_repository.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/create_hadith_plan.dart';
import 'package:islami_app_noorify/features/hadith/presentation/bloc/hadith_create_plan/hadith_create_plan_bloc.dart';
import 'package:islami_app_noorify/features/hadith/presentation/screens/hadith_create_plan_screen.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';

const _book = HadithLibraryBook(
  id: 'book-1',
  titleEn: 'Book One',
  titleBn: 'Book One',
  titleAr: '',
  authorEn: '',
  authorBn: '',
  totalHadiths: 40,
  totalCategories: 2,
  totalSubCategories: 0,
  displayOrder: 1,
);

const _category = HadithCategory(
  id: 'cat-1',
  bookId: 'book-1',
  name: 'Category One',
  nameBangla: 'Category One',
  nameArabic: '',
  sectionNumber: 1,
  displayOrder: 1,
  totalHadiths: 12,
  totalSubCategories: 0,
);

/// Serves one book with one category, and records / answers plan creation.
class _FakeRepository implements HadithLibraryRepository {
  _FakeRepository({this.createResult});

  /// What creating answers; success unless a test sets a failure.
  Either<Failure, Unit>? createResult;
  final created = <HadithPlanDraft>[];

  /// When set, creating waits for it, i.e. the request stays in flight.
  Completer<void>? gate;

  @override
  Future<Either<Failure, List<HadithLibraryBook>>> getBooks() async =>
      const Right([_book]);

  @override
  Future<Either<Failure, HadithCategoryPage>> getCategories(
    String bookId, {
    required int page,
    required int limit,
    String? searchTerm,
  }) async => Right(
    HadithCategoryPage(
      categories: bookId == _book.id ? const [_category] : const [],
      page: 1,
      totalPage: 1,
      total: 1,
    ),
  );

  @override
  Future<Either<Failure, Unit>> createPlan(HadithPlanDraft draft) async {
    created.add(draft);
    await gate?.future;
    return createResult ?? const Right(unit);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('HadithPlanDraft.toJson', () {
    test('sends the fields of the API example', () {
      const draft = HadithPlanDraft(
        name: 'My 40 Hadith journey',
        description: 'One chapter a day',
        bookId: '6aae74f6ac63e38856600b06',
        categoryIds: ['c1'],
        subCategoryIds: ['s1'],
        targetDays: 30,
      );
      expect(draft.toJson(), {
        'name': 'My 40 Hadith journey',
        'description': 'One chapter a day',
        'bookId': '6aae74f6ac63e38856600b06',
        'categoryIds': ['c1'],
        'subCategoryIds': ['s1'],
        'targetDays': 30,
      });
    });

    test('leaves out what was not given', () {
      const draft = HadithPlanDraft(
        name: 'Plan',
        bookId: 'b',
        categoryIds: ['c1', 'c2'],
        description: '   ',
      );
      expect(draft.toJson(), {
        'name': 'Plan',
        'bookId': 'b',
        'categoryIds': ['c1', 'c2'],
      });
    });
  });

  group('HadithCreatePlanBloc', () {
    const draft = HadithPlanDraft(name: 'P', bookId: 'b', categoryIds: ['c']);

    test('success: submitting, then success with the plan name', () async {
      final repo = _FakeRepository();
      final bloc = HadithCreatePlanBloc(CreateHadithPlan(repo));
      addTearDown(bloc.close);

      final states = <HadithCreatePlanStatus>[];
      final sub = bloc.stream.listen((s) => states.add(s.status));
      bloc.add(const SubmitHadithPlan(draft));
      final done = await bloc.stream.firstWhere((s) => !s.isSubmitting);
      await sub.cancel();

      expect(states, [
        HadithCreatePlanStatus.submitting,
        HadithCreatePlanStatus.success,
      ]);
      expect(done.planName, 'P');
      expect(repo.created.single, same(draft));
    });

    test('failure keeps the API message', () async {
      final repo = _FakeRepository(
        createResult: const Left(
          ServerFailure(
            'A plan with this name already exists',
            statusCode: 409,
          ),
        ),
      );
      final bloc = HadithCreatePlanBloc(CreateHadithPlan(repo));
      addTearDown(bloc.close);

      bloc.add(const SubmitHadithPlan(draft));
      final done = await bloc.stream.firstWhere((s) => !s.isSubmitting);

      expect(done.status, HadithCreatePlanStatus.failure);
      expect(done.failure!.message, 'A plan with this name already exists');
    });

    test('a second tap while sending does not create the plan twice', () async {
      // The first request stays in flight, as a real network call does.
      final repo = _FakeRepository()..gate = Completer<void>();
      final bloc = HadithCreatePlanBloc(CreateHadithPlan(repo));
      addTearDown(bloc.close);

      bloc.add(const SubmitHadithPlan(draft));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.isSubmitting, isTrue);
      bloc.add(const SubmitHadithPlan(draft));
      await Future<void>.delayed(Duration.zero);

      // Ignored while the first is still running.
      expect(repo.created, hasLength(1));

      repo.gate!.complete();
      await bloc.stream.firstWhere((s) => !s.isSubmitting);
      expect(repo.created, hasLength(1));

      // Once it has finished, sending again (a retry) is allowed.
      bloc.add(const SubmitHadithPlan(draft));
      await bloc.stream.firstWhere((s) => !s.isSubmitting);
      expect(repo.created, hasLength(2));
    });
  });

  group('HadithCreatePlanScreen', () {
    String? popped;

    /// A host that opens the create screen and keeps what it popped with.
    Future<void> pumpHost(WidgetTester tester, _FakeRepository repo) async {
      popped = null;
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => BlocProvider(
            create: (_) => LanguageBloc(),
            child: MaterialApp(
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () async {
                      popped = await Navigator.of(context).push<String>(
                        MaterialPageRoute(
                          builder: (_) =>
                              HadithCreatePlanScreen(repository: repo),
                        ),
                      );
                    },
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    /// Picks the book and the category through the two sheets.
    Future<void> pickBookAndCategory(WidgetTester tester) async {
      await tester.tap(find.text('Eg : Sahih Bukhari'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Book One'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Eg : Ohir Sucona'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Category One'));
      await tester.pumpAndSettle();
    }

    testWidgets('Create sends the name, book and category to the API', (
      tester,
    ) async {
      final repo = _FakeRepository();
      await pumpHost(tester, repo);

      await tester.enterText(
        find.byKey(const Key('plan-name-field')),
        'My plan',
      );
      await tester.enterText(find.byKey(const Key('target-days-field')), '30');
      await pickBookAndCategory(tester);
      // The picked book and category now show in their fields.
      expect(find.text('Book One'), findsOneWidget);
      expect(find.text('Category One'), findsOneWidget);

      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(repo.created, hasLength(1));
      final draft = repo.created.single;
      expect(draft.name, 'My plan');
      expect(draft.bookId, 'book-1');
      expect(draft.categoryIds, ['cat-1']);
      expect(draft.targetDays, 30);
      // The request body carries it, as in the API example.
      expect(draft.toJson(), {
        'name': 'My plan',
        'bookId': 'book-1',
        'categoryIds': ['cat-1'],
        'targetDays': 30,
      });
      // Success closes the screen with the plan's name for the planner.
      expect(popped, 'My plan');
    });

    testWidgets('an empty Target Days field is not sent', (tester) async {
      final repo = _FakeRepository();
      await pumpHost(tester, repo);

      await pickBookAndCategory(tester);
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(repo.created.single.targetDays, isNull);
      expect(repo.created.single.toJson().containsKey('targetDays'), isFalse);
    });

    testWidgets('Target Days takes digits only, and zero is not sent', (
      tester,
    ) async {
      final repo = _FakeRepository();
      await pumpHost(tester, repo);

      // Letters and signs are dropped as they are typed.
      await tester.enterText(
        find.byKey(const Key('target-days-field')),
        '1a2-b3',
      );
      expect(find.text('123'), findsOneWidget);
      // At most four digits.
      await tester.enterText(
        find.byKey(const Key('target-days-field')),
        '123456',
      );
      expect(find.text('1234'), findsOneWidget);

      // Zero isn't a target.
      await tester.enterText(find.byKey(const Key('target-days-field')), '0');
      await pickBookAndCategory(tester);
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(repo.created.single.targetDays, isNull);
    });

    testWidgets('the value stays while adding categories', (tester) async {
      final repo = _FakeRepository();
      await pumpHost(tester, repo);

      await tester.enterText(find.byKey(const Key('target-days-field')), '45');
      await pickBookAndCategory(tester);
      // Add hides the form and shows the added list; Add More brings it back.
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add More'));
      await tester.pumpAndSettle();
      expect(find.text('45'), findsOneWidget);

      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();
      expect(repo.created.single.targetDays, 45);
    });

    testWidgets('Add then Create sends every added category', (tester) async {
      final repo = _FakeRepository();
      await pumpHost(tester, repo);

      await pickBookAndCategory(tester);
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      // The added list shows the category with its hadith count.
      expect(find.text('Category One'), findsOneWidget);
      expect(find.text('12 Hadith'), findsOneWidget);

      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(repo.created.single.categoryIds, ['cat-1']);
    });

    testWidgets('nothing chosen: no request, and it says what is missing', (
      tester,
    ) async {
      final repo = _FakeRepository();
      await pumpHost(tester, repo);

      await tester.tap(find.text('Create'));
      await tester.pump();

      expect(repo.created, isEmpty);
      expect(find.text('Select Hadith book'), findsWidgets);
      expect(popped, isNull);
    });

    testWidgets('a book but no category: still no request', (tester) async {
      final repo = _FakeRepository();
      await pumpHost(tester, repo);

      await tester.tap(find.text('Eg : Sahih Bukhari'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Book One'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create'));
      await tester.pump();

      expect(repo.created, isEmpty);
      expect(find.text('Select Category'), findsWidgets);
    });

    testWidgets('the API refusing (name taken) shows its message and stays', (
      tester,
    ) async {
      final repo = _FakeRepository(
        createResult: const Left(
          ServerFailure(
            'A plan with this name already exists',
            statusCode: 409,
          ),
        ),
      );
      await pumpHost(tester, repo);

      await pickBookAndCategory(tester);
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(repo.created, hasLength(1));
      expect(find.text('A plan with this name already exists'), findsOneWidget);
      // Still on the form, so the user can change the name and try again.
      expect(find.text('Create'), findsOneWidget);
      expect(popped, isNull);
    });
  });
}
