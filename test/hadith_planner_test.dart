import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/core/constants/route_names.dart';
import 'package:islami_app_noorify/core/errors/failures.dart';
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
  totalHadiths: 10 + i,
  completedHadiths: 0,
  percentage: 0,
  isCompleted: false,
);

/// Serves [total] plans, [limit] per page, and remembers every request.
class _FakeRepository implements HadithLibraryRepository {
  _FakeRepository({this.total = 0, this.failure});

  final int total;
  Failure? failure;
  final requests = <({String? status, int page, int limit})>[];

  @override
  Future<Either<Failure, HadithPlanPage>> getPlans({
    String? status,
    required int page,
    required int limit,
  }) async {
    requests.add((status: status, page: page, limit: limit));
    final error = failure;
    if (error != null) return Left(error);
    final first = (page - 1) * limit;
    final count = (total - first).clamp(0, limit);
    return Right(
      HadithPlanPage(
        plans: [for (var i = first; i < first + count; i++) _plan(i + 1)],
        page: page,
        totalPage: (total / limit).ceil(),
        total: total,
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
              home: HadithPlannerScreen(getPlans: GetHadithPlans(repo)),
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
        expect(repo.requests.first.status, 'in_progress');
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
      expect(repo.requests, hasLength(2));
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
      expect(repo.requests, hasLength(1));

      await tester.tap(find.text('Create Plan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('finish'));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Back on the planner, which asked the API again.
      expect(repo.requests, hasLength(2));
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

      expect(repo.requests, hasLength(1));
    });
  });
}
