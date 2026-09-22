import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/errors/failures.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/features/hadith/presentation/screens/hadith_detail_screen.dart';
import 'package:islami_app_noorify/features/hadith/presentation/screens/hadith_edit_plan_screen.dart';
import 'package:islami_app_noorify/features/hadith/data/models/hadith_plan_model.dart';
import 'package:islami_app_noorify/features/hadith/domain/entities/hadith_plan.dart';
import 'package:islami_app_noorify/features/hadith/domain/repositories/hadith_library_repository.dart';
import 'package:islami_app_noorify/features/hadith/domain/usecases/get_hadith_plans.dart';
import 'package:islami_app_noorify/features/hadith/presentation/bloc/hadith_plans/hadith_plans_bloc.dart';
import 'package:islami_app_noorify/features/hadith/presentation/screens/hadith_planner_screen.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';

/// The two plans of a real `GET /hadiths/plans` response, trimmed.
final _realPlans = <Map<String, dynamic>>[
  {
    '_id': '6ab123dc0a38d3cb8f0c54cd',
    'name': 'euur',
    'bookId': {
      '_id': '6aae74f6ac63e38856600b06',
      'sourceEnglish': "An-Nawawi's Forty Hadith",
    },
    'categoryIds': ['6aaf545bac63e38856601db0'],
    'subCategoryIds': <String>[],
    'targetDays': 20,
    'status': 'in_progress',
    'isActive': true,
    'counts': {
      'totalHadiths': 7,
      'completedHadiths': 0,
      'remainingHadiths': 7,
      'percentage': 0,
      'isCompleted': false,
    },
  },
  {
    '_id': '6ab11dca0a38d3cb8f0c5393',
    'name': 'hello',
    'bookId': {
      '_id': '6aae3486ac63e388565ffccb',
      'sourceEnglish': 'Riyad as-Salihin',
    },
    'categoryIds': ['6aae3486ac63e388565ffccd'],
    'subCategoryIds': <String>[],
    'targetDays': 30,
    'status': 'in_progress',
    'isActive': true,
    'counts': {
      'totalHadiths': 46,
      'completedHadiths': 1,
      'remainingHadiths': 45,
      'percentage': 2,
      'isCompleted': false,
    },
  },
];

HadithPlan _plan(int i) => HadithPlan(
  id: 'p$i',
  name: 'Plan $i',
  status: 'in_progress',
  targetDays: 10 * i,
  totalHadiths: 10 + i,
  completedHadiths: 0,
  percentage: 0,
  isCompleted: false,
  bookId: 'book$i',
  categoryIds: ['cat$i'],
);

/// Serves [total] plans (all `in_progress` to start), [limit] per page,
/// remembers every request, and applies `updatePlan` / `deletePlan` to its
/// own plans so `getPlans` reflects them afterwards — e.g. completing a plan
/// really does move it from one status's page to the other's.
class _FakeRepository implements HadithLibraryRepository {
  _FakeRepository({this.total = 0, this.failure})
    : _plans = [for (var i = 1; i <= total; i++) _plan(i)];

  final int total;
  Failure? failure;
  final requests = <({String? status, int page, int limit})>[];

  /// The edits and deletes the planner sent, and what answering them does.
  final updates =
      <
        ({
          String id,
          String? name,
          int? targetDays,
          String? status,
          String? bookId,
          List<String>? categoryIds,
          List<String>? subCategoryIds,
        })
      >[];
  final deletes = <String>[];
  Failure? actionFailure;

  final List<HadithPlan> _plans;

  @override
  Future<Either<Failure, Unit>> updatePlan(
    String id, {
    String? name,
    int? targetDays,
    String? status,
    String? bookId,
    List<String>? categoryIds,
    List<String>? subCategoryIds,
  }) async {
    updates.add((
      id: id,
      name: name,
      targetDays: targetDays,
      status: status,
      bookId: bookId,
      categoryIds: categoryIds,
      subCategoryIds: subCategoryIds,
    ));
    final error = actionFailure;
    if (error != null) return Left(error);
    final index = _plans.indexWhere((p) => p.id == id);
    if (index != -1) {
      final current = _plans[index];
      _plans[index] = HadithPlan(
        id: current.id,
        name: name ?? current.name,
        status: status ?? current.status,
        targetDays: targetDays ?? current.targetDays,
        totalHadiths: current.totalHadiths,
        completedHadiths: current.completedHadiths,
        percentage: current.percentage,
        isCompleted: current.isCompleted,
        bookId: bookId ?? current.bookId,
        bookTitleEnglish: current.bookTitleEnglish,
        bookTitleBangla: current.bookTitleBangla,
        categoryIds: categoryIds ?? current.categoryIds,
      );
    }
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> deletePlan(String id) async {
    deletes.add(id);
    final error = actionFailure;
    if (error != null) return Left(error);
    _plans.removeWhere((p) => p.id == id);
    return const Right(unit);
  }

  @override
  Future<Either<Failure, HadithPlanPage>> getPlans({
    String? status,
    required int page,
    required int limit,
  }) async {
    requests.add((status: status, page: page, limit: limit));
    final error = failure;
    if (error != null) return Left(error);
    final matching = status == null
        ? _plans
        : _plans.where((p) => p.status == status).toList();
    final first = (page - 1) * limit;
    final count = (matching.length - first).clamp(0, limit);
    return Right(
      HadithPlanPage(
        plans: matching.sublist(first, first + count),
        page: page,
        totalPage: (matching.length / limit).ceil(),
        total: matching.length,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('HadithPlanModel', () {
    test('reads name, target and counts from a real response', () {
      final page = HadithPlanPageModel.fromJson(_realPlans, {
        'page': 1,
        'limit': 10,
        'total': 2,
        'totalPage': 1,
      });

      expect(page.plans.map((p) => p.name), ['euur', 'hello']);
      expect(page.plans.map((p) => p.totalHadiths), [7, 46]);
      expect(page.plans.map((p) => p.completedHadiths), [0, 1]);
      expect(page.plans.map((p) => p.remainingHadiths), [7, 45]);
      expect(page.plans.map((p) => p.percentage), [0, 2]);
      expect(page.plans.map((p) => p.targetDays), [20, 30]);
      expect(page.plans.first.id, '6ab123dc0a38d3cb8f0c54cd');
      expect(page.plans.first.status, 'in_progress');
      expect(page.plans.first.isCompleted, isFalse);
      // `bookId` comes populated (an object); `categoryIds` are plain ids.
      expect(page.plans.first.bookId, '6aae74f6ac63e38856600b06');
      expect(page.plans.first.bookTitleEnglish, "An-Nawawi's Forty Hadith");
      expect(page.plans.first.categoryIds, ['6aaf545bac63e38856601db0']);
      expect(page.total, 2);
      expect(page.hasMore, isFalse);
    });

    test('tolerates missing counts, a zero target and a wild percentage', () {
      final bare = HadithPlanModel.fromJson({'_id': 'x', 'name': 'Bare'});
      expect(bare.totalHadiths, 0);
      expect(bare.targetDays, isNull);
      expect(bare.percentage, 0);

      final odd = HadithPlanModel.fromJson({
        'name': 'Odd',
        'targetDays': 0,
        'counts': {'percentage': 140, 'isCompleted': true},
      });
      expect(odd.targetDays, isNull);
      expect(odd.percentage, 100);
      expect(odd.isCompleted, isTrue);
    });

    test('without meta, what came is the only page', () {
      final page = HadithPlanPageModel.fromJson(_realPlans, {});
      expect(page.hasMore, isFalse);
      expect(page.total, 2);
    });
  });

  group('HadithPlansBloc', () {
    test('asks for the in-progress plans, then pages to the end', () async {
      final repo = _FakeRepository(total: 25);
      final bloc = HadithPlansBloc(GetHadithPlans(repo), status: 'in_progress');
      addTearDown(bloc.close);

      bloc.add(const LoadHadithPlans());
      var state = await bloc.stream.firstWhere((s) => !s.isLoading);
      expect(state.plans, hasLength(10));
      expect(state.hasMore, isTrue);

      bloc.add(const LoadMoreHadithPlans());
      state = await bloc.stream.firstWhere(
        (s) => !s.isLoadingMore && s.plans.length == 20,
      );
      bloc.add(const LoadMoreHadithPlans());
      state = await bloc.stream.firstWhere(
        (s) => !s.isLoadingMore && s.plans.length == 25,
      );
      expect(state.hasMore, isFalse);

      // Nothing left: no further request.
      bloc.add(const LoadMoreHadithPlans());
      await Future<void>.delayed(Duration.zero);

      expect(repo.requests.map((r) => r.page), [1, 2, 3]);
      expect(repo.requests.every((r) => r.status == 'in_progress'), isTrue);
      expect(repo.requests.every((r) => r.limit == 10), isTrue);
    });

    test('a failure is kept, and a reload recovers', () async {
      final repo = _FakeRepository(
        total: 2,
        failure: const ServerFailure('Invalid or expired access token.'),
      );
      final bloc = HadithPlansBloc(GetHadithPlans(repo), status: 'in_progress');
      addTearDown(bloc.close);

      bloc.add(const LoadHadithPlans());
      var state = await bloc.stream.firstWhere((s) => !s.isLoading);
      expect(state.status, HadithPlansStatus.failure);
      expect(state.failure!.message, 'Invalid or expired access token.');

      repo.failure = null;
      bloc.add(const LoadHadithPlans());
      state = await bloc.stream.firstWhere((s) => !s.isLoading);
      expect(state.status, HadithPlansStatus.success);
      expect(state.plans, hasLength(2));
    });
  });

  group('HadithPlannerScreen', () {
    Future<void> pumpPlanner(
      WidgetTester tester,
      _FakeRepository repo, {
      Map<String, WidgetBuilder> routes = const {},
    }) async {
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
              routes: routes,
              home: HadithPlannerScreen(repository: repo),
            ),
          ),
        ),
      );
      // A spinner never "settles"; let the bloc's async work finish.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    testWidgets(
      'My Plan lists the plans with name, hadith count and progress',
      (tester) async {
        final repo = _FakeRepository(total: 2);
        await pumpPlanner(tester, repo);

        expect(find.text('Plan 1'), findsOneWidget);
        expect(find.text('Plan 2'), findsOneWidget);
        // totalHadiths and the read share, on the card.
        expect(find.text('11 Hadith · 0%'), findsOneWidget);
        expect(find.text('12 Hadith · 0%'), findsOneWidget);
        // The list came from the API, asking for in-progress plans.
        expect(repo.requests.map((r) => r.status), contains('in_progress'));
      },
    );

    testWidgets('no plans shows the empty message, not a list', (tester) async {
      await pumpPlanner(tester, _FakeRepository(total: 0));

      expect(find.text('Plan 1'), findsNothing);
      expect(find.byIcon(Icons.sticky_note_2_rounded), findsOneWidget);
    });

    testWidgets('a failed load shows the message, and Try Again reloads', (
      tester,
    ) async {
      final repo = _FakeRepository(
        total: 1,
        failure: const ServerFailure('Something went wrong'),
      );
      await pumpPlanner(tester, repo);
      expect(find.text('Something went wrong'), findsOneWidget);

      repo.failure = null;
      await tester.tap(find.text('Try Again'));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('Plan 1'), findsOneWidget);
      expect(repo.requests.where((r) => r.status == 'in_progress'), hasLength(2));
    });

    testWidgets('creating a plan reloads the list', (tester) async {
      final repo = _FakeRepository(total: 1);
      await pumpPlanner(
        tester,
        repo,
        routes: {
          // Stands in for the create form: "creates" and pops with the name.
          RouteNames.hadithCreatePlan: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).pop('New plan'),
              child: const Text('finish'),
            ),
          ),
        },
      );
      expect(repo.requests.where((r) => r.status == 'in_progress'), hasLength(1));

      await tester.tap(find.text('Create Plan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('finish'));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Back on the planner, which asked the API again.
      expect(repo.requests.where((r) => r.status == 'in_progress'), hasLength(2));
      expect(find.text('Plan 1'), findsOneWidget);
    });

    testWidgets('backing out of the form without creating does not reload', (
      tester,
    ) async {
      final repo = _FakeRepository(total: 1);
      await pumpPlanner(
        tester,
        repo,
        routes: {
          RouteNames.hadithCreatePlan: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('back'),
            ),
          ),
        },
      );

      await tester.tap(find.text('Create Plan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('back'));
      await tester.pumpAndSettle();

      expect(repo.requests.where((r) => r.status == 'in_progress'), hasLength(1));
    });

    /// Opens the ⋮ menu of the first plan.
    Future<void> openMenu(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.more_vert_rounded).first);
      await tester.pumpAndSettle();
    }

    /// Lets the bloc's async work finish after an action.
    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    group('the ⋮ menu', () {
      testWidgets('offers Edit, Complete and Delete, each with its icon', (
        tester,
      ) async {
        await pumpPlanner(tester, _FakeRepository(total: 2));
        // Before opening: no menu entries yet.
        expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);

        await openMenu(tester);

        expect(find.text('Edit'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);
        expect(find.text('Complete'), findsOneWidget);
        expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
        expect(
          find.byIcon(Icons.check_circle_outline_rounded),
          findsOneWidget,
        );
        // The pencil is also on the "Create Plan" button: 2 = it + the menu.
        expect(find.byIcon(Icons.edit_outlined), findsNWidgets(2));
      });

      testWidgets('Delete asks first, then deletes and reloads the list', (
        tester,
      ) async {
        final repo = _FakeRepository(total: 2);
        await pumpPlanner(tester, repo);

        await openMenu(tester);
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();
        // The question names the plan; nothing is sent yet.
        expect(find.text('Delete this plan?'), findsOneWidget);
        expect(find.text('Plan 1'), findsWidgets);
        expect(repo.deletes, isEmpty);

        await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
        await settle(tester);

        expect(repo.deletes, ['p1']);
        // Reloaded: the first load plus one after the delete.
        expect(repo.requests.where((r) => r.status == 'in_progress'), hasLength(2));
      });

      testWidgets('cancelling the question deletes nothing', (tester) async {
        final repo = _FakeRepository(total: 2);
        await pumpPlanner(tester, repo);

        await openMenu(tester);
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(repo.deletes, isEmpty);
        expect(repo.requests.where((r) => r.status == 'in_progress'), hasLength(1));
      });

      testWidgets('a failed delete shows the API message and keeps the list', (
        tester,
      ) async {
        final repo = _FakeRepository(total: 2)
          ..actionFailure = const ServerFailure('Plan not found');
        await pumpPlanner(tester, repo);

        await openMenu(tester);
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
        await settle(tester);

        expect(repo.deletes, ['p1']);
        expect(find.text('Plan not found'), findsOneWidget);
        // No reload: nothing changed on the server.
        expect(repo.requests.where((r) => r.status == 'in_progress'), hasLength(1));
        expect(find.text('Plan 1'), findsOneWidget);
      });

      testWidgets(
        'Complete asks first, then completes, switches to My Complete and '
        'shows the plan there',
        (tester) async {
          final repo = _FakeRepository(total: 2);
          await pumpPlanner(tester, repo);

          await openMenu(tester);
          await tester.tap(find.text('Complete'));
          await tester.pumpAndSettle();
          // The question names the plan; nothing is sent yet.
          expect(find.text('Mark this plan as complete?'), findsOneWidget);
          expect(find.text('Plan 1'), findsWidgets);
          expect(repo.updates, isEmpty);

          await tester.tap(find.widgetWithText(FilledButton, 'Complete'));
          await settle(tester);

          expect(repo.updates.last, (
            id: 'p1',
            name: null,
            targetDays: null,
            status: 'completed',
            bookId: null,
            categoryIds: null,
            subCategoryIds: null,
          ));
          // Switched to "My Complete" on its own: Plan 1 shows there, and
          // Plan 2 (still "My Plan") is off screen.
          expect(find.text('Plan 1'), findsOneWidget);
          expect(find.text('Plan 2'), findsNothing);
        },
      );

      testWidgets('cancelling the question completes nothing', (
        tester,
      ) async {
        final repo = _FakeRepository(total: 2);
        await pumpPlanner(tester, repo);

        await openMenu(tester);
        await tester.tap(find.text('Complete'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(repo.updates, isEmpty);
        expect(find.text('Plan 1'), findsOneWidget);
      });

      testWidgets(
        'Edit opens the edit screen with the plan\'s current values, and '
        'reloads both lists when it saves',
        (tester) async {
          final repo = _FakeRepository(total: 2);
          Object? arguments;
          await pumpPlanner(
            tester,
            repo,
            routes: {
              RouteNames.hadithEditPlan: (context) {
                arguments = ModalRoute.of(context)!.settings.arguments;
                return Scaffold(
                  body: TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('saved'),
                  ),
                );
              },
            },
          );

          await openMenu(tester);
          await tester.tap(find.text('Edit'));
          await tester.pumpAndSettle();

          final args = arguments as HadithEditPlanArgs;
          expect(args.planId, 'p1');
          expect(args.name, 'Plan 1');
          expect(args.bookId, 'book1');
          expect(args.categoryIds, ['cat1']);
          // _plan(1) targets 10 days.
          expect(args.targetDays, 10);

          await tester.tap(find.text('saved'));
          await settle(tester);

          // Both lists reload: this is the same trigger Complete uses.
          expect(
            repo.requests.where((r) => r.status == 'in_progress'),
            hasLength(2),
          );
          expect(
            repo.requests.where((r) => r.status == 'completed'),
            hasLength(2),
          );
        },
      );

      testWidgets('backing out of the edit screen does not reload', (
        tester,
      ) async {
        final repo = _FakeRepository(total: 2);
        await pumpPlanner(
          tester,
          repo,
          routes: {
            RouteNames.hadithEditPlan: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('back'),
              ),
            ),
          },
        );

        await openMenu(tester);
        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('back'));
        await settle(tester);

        expect(
          repo.requests.where((r) => r.status == 'in_progress'),
          hasLength(1),
        );
      });
    });

    group('My Complete', () {
      /// Completes Plan 1 (switches to My Complete on its own) and clears
      /// the confirmation dialogs already exercised elsewhere.
      Future<void> completePlanOne(WidgetTester tester) async {
        await tester.tap(find.byIcon(Icons.more_vert_rounded).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Complete'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Complete'));
        await settle(tester);
      }

      testWidgets('has its own delete icon, which asks first, then deletes', (
        tester,
      ) async {
        final repo = _FakeRepository(total: 2);
        await pumpPlanner(tester, repo);
        await completePlanOne(tester);

        expect(find.text('Plan 1'), findsOneWidget);
        expect(repo.deletes, isEmpty);

        await tester.tap(find.byIcon(Icons.delete_outline_rounded));
        await tester.pumpAndSettle();
        // The question names the plan; nothing is sent yet.
        expect(find.text('Delete this plan?'), findsOneWidget);
        expect(repo.deletes, isEmpty);

        await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
        await settle(tester);

        expect(repo.deletes, ['p1']);
        expect(find.text('Plan 1'), findsNothing);
      });

      testWidgets('cancelling the question deletes nothing', (tester) async {
        final repo = _FakeRepository(total: 2);
        await pumpPlanner(tester, repo);
        await completePlanOne(tester);

        await tester.tap(find.byIcon(Icons.delete_outline_rounded));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(repo.deletes, isEmpty);
        expect(find.text('Plan 1'), findsOneWidget);
      });
    });

    group('Get Start', () {
      final getStart = AppText.forLanguage(AppLanguage.english).getStart;

      testWidgets('opens that plan\'s hadiths, and reloads when back', (
        tester,
      ) async {
        final repo = _FakeRepository(total: 2);
        Object? arguments;
        await pumpPlanner(
          tester,
          repo,
          routes: {
            RouteNames.hadithDetail: (context) {
              arguments = ModalRoute.of(context)!.settings.arguments;
              return Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('leave'),
                ),
              );
            },
          },
        );

        // The second plan's button.
        await tester.tap(find.text(getStart).at(1));
        await tester.pumpAndSettle();

        final args = arguments as HadithDetailArgs;
        // The plan's own hadiths endpoint comes back without hadith content,
        // so "Get Start" opens the same book + category instead.
        expect(args.bookId, 'book2');
        expect(args.categoryId, 'cat2');
        expect(args.title, 'Plan 2');
        expect(args.subCategoryId, isNull);
        expect(args.planId, isNull);

        // Reading there moves the progress: coming back reloads the plans.
        expect(repo.requests.where((r) => r.status == 'in_progress'), hasLength(1));
        await tester.tap(find.text('leave'));
        await settle(tester);
        expect(repo.requests.where((r) => r.status == 'in_progress'), hasLength(2));
      });
    });
  });
}
