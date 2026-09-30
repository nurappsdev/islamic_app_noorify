import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuhfatul_muslim/core/constants/route_names.dart';
import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/features/quran/domain/quran_plan.dart';
import 'package:tuhfatul_muslim/features/quran/domain/repositories/quran_plan_repository.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/quran_route_args.dart';
import 'package:tuhfatul_muslim/features/quran/presentation/screens/quran_plan_screen.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

final _active = QuranPlan.fromJson({
  '_id': 'p1',
  'name': 'Ramadan Khatm',
  'targetDays': 30,
  'status': 'in_progress',
  'createdAt': '2026-09-20T00:00:00Z',
  'counts': {
    'totalAyahs': 6236,
    'completedAyahs': 1309,
    'remainingAyahs': 4927,
    'percentage': 21,
  },
  'schedule': {
    'targetDays': 30,
    'dayNumber': 9,
    'daysLeft': 21,
    'ayahsPerDay': 208,
    'todayRemainingAyahs': 208,
  },
  'nextAyah': {
    'surahNumber': 2,
    'ayahNumber': 142,
    'ayahKey': '2:142',
    'paraNumber': 2,
    'surahNameEnglish': 'Al-Baqarah',
  },
});

class _Plans implements QuranPlanRepository {
  _Plans({this.plans = const [], this.failList = false});
  final List<QuranPlan> plans;
  final bool failList;
  final created = <CreateQuranPlanRequest>[];
  final completed = <String>[];

  /// Holds plan creation open until completed.
  Completer<void>? createGate;

  @override
  bool get isSignedIn => true;
  @override
  Stream<void> get onPlanChanged => const Stream.empty();

  @override
  Future<Either<Failure, QuranPlansResponse>> getPlans({
    String? status,
    int page = 1,
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    if (failList) return const Left(ServerFailure('Server unavailable'));
    final list = status == 'completed' ? <QuranPlan>[] : plans;
    return Right(
      QuranPlansResponse(
        plans: list,
        meta: QuranPlanMeta(total: list.length, totalPage: 1),
      ),
    );
  }

  @override
  Future<Either<Failure, QuranPlan>> createPlan(
    CreateQuranPlanRequest request,
  ) async {
    created.add(request);
    await createGate?.future;
    return Right(_active);
  }

  @override
  Future<Either<Failure, QuranPlan>> completePlan(String planId) async {
    completed.add(planId);
    return Right(_active);
  }

  @override
  void invalidateCache() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Future<List<RouteSettings>> _pump(WidgetTester tester, _Plans repo) async {
  // A 390x844 phone.
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final opened = <RouteSettings>[];
  await tester.pumpWidget(
    BlocProvider(
      create: (_) => LanguageBloc(
        initialLanguage: AppLanguage.english,
        persist: (_) async {},
      ),
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          home: QuranPlanScreen(repository: repo),
          onGenerateRoute: (settings) {
            opened.add(settings);
            return MaterialPageRoute(builder: (_) => const Scaffold());
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return opened;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('presets start plans for exactly what they name', (
    tester,
  ) async {
    final repo = _Plans();
    await _pump(tester, repo);
    await tester.tap(find.byKey(const ValueKey('quran-segment-1')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('quran-preset-preset_1_month')));
    await tester.pumpAndSettle();
    expect(repo.created.last.wholeQuran, isTrue);

    await tester.tap(find.byKey(const ValueKey('quran-segment-1')));
    await tester.pumpAndSettle();
    final juzAmma = find.byKey(const ValueKey('quran-preset-preset_juz_amma'));
    await tester.scrollUntilVisible(
      juzAmma,
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(juzAmma);
    await tester.pumpAndSettle();
    await tester.tap(juzAmma);
    await tester.pumpAndSettle();
    final request = repo.created.last;
    expect(request.wholeQuran, isFalse);
    expect(request.surahNumbers, [for (var n = 78; n <= 114; n++) n]);
    expect(request.targetDays, 15);
  });

  testWidgets('a preset being started cannot be started twice', (
    tester,
  ) async {
    final repo = _Plans()..createGate = Completer<void>();
    await _pump(tester, repo);
    await tester.tap(find.byKey(const ValueKey('quran-segment-1')));
    await tester.pumpAndSettle();
    final button = find.byKey(const ValueKey('quran-preset-preset_1_month'));
    await tester.tap(button);
    await tester.pump();
    await tester.tap(button, warnIfMissed: false);
    await tester.pump();
    expect(repo.created, hasLength(1));
    repo.createGate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('continue reading opens the next unread ayah', (tester) async {
    final opened = await _pump(tester, _Plans(plans: [_active]));
    expect(find.text('Today: 208 ayahs to go'), findsOneWidget);
    expect(find.text('Al-Baqarah · Ayah 142'), findsOneWidget);

    final continueButton = find.byKey(const ValueKey('quran-plan-continue'));
    await tester.ensureVisible(continueButton);
    await tester.pumpAndSettle();
    await tester.tap(continueButton);
    await tester.pumpAndSettle();
    final route = opened.single;
    expect(route.name, RouteNames.quranSurahDetail);
    final args = route.arguments! as SurahRouteArgs;
    expect((args.surahNo, args.ayahNo), (2, 142));
  });

  testWidgets('marking a plan completed asks first', (tester) async {
    final repo = _Plans(plans: [_active]);
    await _pump(tester, repo);
    Future<void> chooseMarkCompleted() async {
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark Completed'));
      await tester.pumpAndSettle();
    }

    await chooseMarkCompleted();
    expect(find.text('Mark this plan as completed?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repo.completed, isEmpty);

    await chooseMarkCompleted();
    await tester.tap(find.widgetWithText(FilledButton, 'Mark Completed'));
    await tester.pumpAndSettle();
    expect(repo.completed, ['p1']);
  });

  testWidgets('the preset list offers creating your own plan', (
    tester,
  ) async {
    await _pump(tester, _Plans());
    await tester.tap(find.byKey(const ValueKey('quran-segment-1')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('quran-plan-create-own')),
      findsOneWidget,
    );
    // No floating button over the presets there.
    expect(find.widgetWithText(FilledButton, 'Create Plan'), findsNothing);
  });

  testWidgets('an empty plan list points to the ready-made plans', (
    tester,
  ) async {
    await _pump(tester, _Plans());
    await tester.tap(find.byKey(const ValueKey('quran-plan-explore')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('quran-preset-preset_1_month')),
      findsOneWidget,
    );
  });

  testWidgets('a failed load offers Retry', (tester) async {
    await _pump(tester, _Plans(failList: true));
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Read'), findsNothing);
  });
}
