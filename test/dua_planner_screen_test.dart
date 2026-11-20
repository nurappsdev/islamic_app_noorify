import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show FontLoader;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_plan_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_reading_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/domain/repositories/dua_repository.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/screens/dua_planner_screen.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

String _d(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

class _FakeRepository implements DuaRepository {
  _FakeRepository();
  final today = DateUtils.dateOnly(DateTime.now());

  /// Every `from`/`to` the screen asked the calendar endpoint for.
  final calendarWindows = <(String?, String?)>[];

  /// Every `status` the screen asked the plans endpoint for.
  final planRequests = <String?>[];

  /// Every `PATCH` of a plan's reminder flag.
  final reminderCalls = <(String, bool)>[];

  @override
  Future<DuaPlanPage> getPlans({
    String? status,
    int page = 1,
    int limit = 10,
  }) async {
    planRequests.add(status);
    if (status == 'completed') {
      return const DuaPlanPage(
        plans: [],
        page: 1,
        limit: 10,
        total: 4,
        totalPage: 1,
      );
    }
    return DuaPlanPage(
      plans: [
        for (var i = 1; i <= 4; i++)
          DuaPlan(
            id: 'plan-$i',
            name: switch (i) {
              1 => 'Morning Adhkar Routine',
              4 => 'Evening Routine',
              _ => 'Plan name here . . .',
            },
            status: 'in_progress',
            totalDuas: 10,
            completedDuas: 0,
            percentage: 0,
            isCompleted: false,
            currentStreak: 2,
            longestStreak: 5,
            reminderEnabled: true,
            // The fourth plan only starts in five days.
            startDate: i == 4
                ? _d(today.add(const Duration(days: 5)))
                : _d(today.subtract(const Duration(days: 10))),
            endDate: _d(today.add(const Duration(days: 20))),
          ),
      ],
      page: 1,
      limit: 10,
      total: 4,
      totalPage: 1,
    );
  }

  /// Every even past day met its goal, every odd one did not.
  @override
  Future<DuaReadingCalendar> getReadingCalendar({
    int days = 30,
    String? from,
    String? to,
  }) async {
    calendarWindows.add((from, to));
    return DuaReadingCalendar(
      from: from ?? '',
      to: to ?? '',
      currentStreak: 2,
      days: [
        for (var offset = -10; offset <= 10; offset++)
          DuaCalendarDay(
            date: _d(today.add(Duration(days: offset))),
            dayOfMonth: today.add(Duration(days: offset)).day,
            hasActivity: offset.isEven,
            isGoalMet: offset < 0 && offset.isEven,
            readMinutes: offset.isEven ? 10 : 0,
          ),
      ],
    );
  }

  @override
  Future<void> setPlanReminder(String id, {required bool enabled}) async =>
      reminderCalls.add((id, enabled));

  @override
  Future<DuaPlanHistory> getPlanHistory(
    String id, {
    String? from,
    String? to,
  }) async => DuaPlanHistory(
    planId: id,
    currentStreak: 2,
    longestStreak: 5,
    completedDays: 3,
    scheduledDays: 10,
    completionRate: 30,
    days: [
      for (var offset = -3; offset <= 0; offset++)
        DuaPlanHistoryDay(
          date: _d(today.add(Duration(days: offset))),
          completedDuas: offset.isEven ? 10 : 0,
          totalDuas: 10,
          isCompleted: offset.isEven,
          isScheduled: true,
          isFuture: false,
        ),
    ],
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();

  @override
  Future<List<DuaFeaturedModel>> getFeatured() => throw UnimplementedError();
  @override
  Future<List<DuaCategoryModel>> getCategories() => throw UnimplementedError();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final family in ['Roboto', 'serif']) {
      final loader = FontLoader(family)
        ..addFont(
          File(
            'assets/fonts/Ubuntu-Medium.ttf',
          ).readAsBytes().then(ByteData.sublistView),
        );
      await loader.load();
    }
  });

  Future<_FakeRepository> pumpPlanner(WidgetTester tester) async {
    tester.view.physicalSize = const Size(375 * 3, 812 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final repository = _FakeRepository();
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) => BlocProvider(
          create: (_) => LanguageBloc(initialLanguage: AppLanguage.english),
          child: MaterialApp(home: DuaPlannerScreen(repository: repository)),
        ),
      ),
    );
    // A spinner never "settles"; let the cubit's async work finish.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    return repository;
  }

  /// Every dot colour the week strip is showing.
  List<Color?> dotsOf(WidgetTester tester) => tester
      .widgetList<Container>(find.byType(Container))
      .map((container) => container.decoration)
      .whereType<BoxDecoration>()
      .where((decoration) => decoration.shape == BoxShape.circle)
      .map((decoration) => decoration.color)
      .toList();

  testWidgets(
    'the planner lists plan cards and marks read days green, missed days red',
    (tester) async {
      final repository = await pumpPlanner(tester);

      // The design's four plan cards, each with its "Added N Dua" subtitle.
      expect(find.text('Morning Adhkar Routine'), findsOneWidget);
      expect(find.text('Plan name here . . .'), findsNWidgets(2));
      // The fourth plan has not started yet, so today shows three.
      expect(find.text('Evening Routine'), findsNothing);
      expect(find.text('Added 10 Dua into this plan'), findsNWidgets(3));
      // The completed tab's count, and the plans running on the selected day.
      expect(find.text('04'), findsOneWidget);
      expect(find.text('Total plan 03'), findsOneWidget);

      // Plans and the week's dots are fetched together, in one window.
      expect(repository.calendarWindows, hasLength(1));
      expect(repository.calendarWindows.single, (
        _d(repository.today.subtract(const Duration(days: 3))),
        _d(repository.today.add(const Duration(days: 3))),
      ));

      // The strip runs today-3 ... today+3. Of its three past days the
      // calendar reports one as goal-met (green) and two as not (red);
      // today and the future days stay neutral.
      final dots = dotsOf(tester);
      expect(
        dots.where((color) => color == const Color(0xFF5FBD2F)),
        hasLength(1),
      );
      expect(
        dots.where((color) => color == const Color(0xFFE35D5D)),
        hasLength(2),
      );
    },
  );

  testWidgets('typing in the search field filters the cards locally', (
    tester,
  ) async {
    final repository = await pumpPlanner(tester);
    final requestsBefore = repository.planRequests.length;

    // The bottom nav carries a search icon too; the planner's own is first.
    await tester.tap(find.byIcon(Icons.search_rounded).first);
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'morning');
    await tester.pump();

    expect(find.text('Morning Adhkar Routine'), findsOneWidget);
    expect(find.text('Plan name here . . .'), findsNothing);
    // Filtering is local: no further request went out.
    expect(repository.planRequests, hasLength(requestsBefore));

    // The magnifier inside the field closes it again, clearing the filter.
    await tester.tap(
      find.descendant(
        of: find.byType(TextField),
        matching: find.byIcon(Icons.search_rounded),
      ),
    );
    await tester.pump();
    expect(find.text('Plan name here . . .'), findsNWidgets(2));
  });

  testWidgets('moving the week shows the plans running on that date', (
    tester,
  ) async {
    final repository = await pumpPlanner(tester);
    final requestsBefore = repository.planRequests.length;

    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    // A week on, the plan that started in five days is running too.
    expect(find.text('Evening Routine'), findsOneWidget);
    expect(find.text('Total plan 04'), findsOneWidget);
    // The list itself was not refetched, only the new week's dots.
    expect(repository.planRequests, hasLength(requestsBefore));
    expect(repository.calendarWindows.length, greaterThan(1));
  });

  testWidgets('the three-dot menu pauses the plan\'s reminders', (
    tester,
  ) async {
    final repository = await pumpPlanner(tester);

    await tester.tap(find.byIcon(Icons.more_vert_rounded).first);
    await tester.pumpAndSettle();
    // The four options of the spec.
    expect(find.text('Edit plan details'), findsOneWidget);
    expect(find.text('Plan info'), findsOneWidget);
    expect(find.text('Pause reminders'), findsOneWidget);
    expect(find.text('Delete plan'), findsOneWidget);

    await tester.tap(find.text('Pause reminders'));
    await tester.pumpAndSettle();

    expect(repository.reminderCalls, [('plan-1', false)]);
    expect(find.text('Reminders paused.'), findsOneWidget);
  });

  testWidgets('"Plan info" shows the streaks the history endpoint reports', (
    tester,
  ) async {
    await pumpPlanner(tester);

    await tester.tap(find.byIcon(Icons.more_vert_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plan info'));
    await tester.pumpAndSettle();

    expect(find.text('Current streak'), findsOneWidget);
    expect(find.text('Longest streak'), findsOneWidget);
    expect(find.text('3/10'), findsOneWidget);
    expect(find.text('30%'), findsOneWidget);
  });

  testWidgets('tapping a card reveals its "Explore now" button', (
    tester,
  ) async {
    await pumpPlanner(tester);
    expect(find.text('Explore now'), findsNothing);

    await tester.tap(find.text('Morning Adhkar Routine'));
    await tester.pump();
    expect(find.text('Explore now'), findsOneWidget);

    // Tapping it again closes it.
    await tester.tap(find.text('Morning Adhkar Routine'));
    await tester.pump();
    expect(find.text('Explore now'), findsNothing);
  });
}
