import 'dart:math' as math;

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/core/errors/failures.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_daily_dashboard.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_daily_summary.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_item.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/entities/amol_pillar.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/repositories/amol_tracking_repository.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/usecases/delete_amol_item.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/usecases/get_amol_daily.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/domain/usecases/log_amol_item.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/bloc/amol_daily/amol_daily_bloc.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/screens/amol_tracking_screen.dart';
import 'package:tuhfatul_muslim/features/amol_tracking/presentation/widgets/amol_shared_widgets.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

const _titles = {
  'fardh_prayer': 'Fardh Prayer',
  'sunnah_witr': 'Sunnah and Witr',
  'nafl_salat': 'Nafl Salat',
  'quran': 'Quran',
  'hadith': 'Hadith',
  'quiz': 'Quiz',
  'nafl_and_more': 'Nafl & more',
};

class _FakeRepository implements AmolTrackingRepository {
  _FakeRepository(this.dashboard);
  final AmolDailyDashboard dashboard;

  @override
  Future<Either<Failure, AmolDailyDashboard>> getDaily({
    required String date,
  }) async => Right(dashboard);

  @override
  Future<Either<Failure, AmolDailyDashboard>> logItem({
    required String logDate,
    required String pillarKey,
    required String itemKey,
  }) async => Right(dashboard);

  @override
  Future<Either<Failure, AmolDailyDashboard>> deleteItem({
    required String logDate,
    required String pillarKey,
    required String itemKey,
  }) async => Right(dashboard);
  @override
  Future<({int sent, int pending})> syncPending({
    AmolDailyDashboard? known,
  }) async => (sent: 0, pending: 0);
}

AmolDailyDashboard _dashboard() => AmolDailyDashboard(
  dateFormatted: '',
  dateIso: '2026-09-28',
  earnedPoints: 0,
  maxPoints: 10,
  completionPercentage: 0,
  summary: const AmolDailySummary(
    totalEarnedPoints: 0,
    totalPossiblePoints: 10,
    percentage: 0,
    pointsText: 'Point : 0/10',
  ),
  pillars: [
    for (final key in _titles.keys)
      AmolPillar(
        pillarKey: key,
        title: _titles[key]!,
        titleBn: _titles[key]!,
        earnedPoints: 0,
        maxPoints: 2,
        percentage: 0,
        formattedSubtext: '0/2',
        items: [
          AmolItem(
            itemKey: '${key}_item',
            title: '${_titles[key]} item',
            titleBn: '${_titles[key]} item',
            points: 0,
            maxPoints: 1,
            isCompleted: false,
          ),
        ],
      ),
  ],
);

Future<AmolDailyBloc> _pump(
  WidgetTester tester, {
  AmalSection? section,
  String? itemKey,
  AppLanguage selectedLanguage = AppLanguage.english,
}) async {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.runAsync(AppText.load);
  final repository = _FakeRepository(_dashboard());
  final bloc = AmolDailyBloc(
    GetAmolDaily(repository),
    LogAmolItem(repository),
    DeleteAmolItem(repository),
    initialDashboard: _dashboard(),
  );
  addTearDown(bloc.close);
  final language = LanguageBloc(
    initialLanguage: selectedLanguage,
    persist: (_) async {},
  );
  addTearDown(language.close);
  await tester.pumpWidget(
    BlocProvider.value(
      value: language,
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          home: AmolTrackingScreen(
            selectedSection: section,
            selectedItemKey: itemKey,
            bloc: bloc,
            now: () => DateTime(2026, 9, 28),
          ),
        ),
      ),
    ),
  );
  return bloc;
}

/// Lets the arrival, the scroll and the focus pause all finish.
Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

/// The section titles, top to bottom, among those laid out.
List<String> _order(WidgetTester tester) => _orderWithin(tester, null);

/// The section titles that are inside the scrolling viewport, top to bottom.
List<String> _visibleOrder(WidgetTester tester) =>
    _orderWithin(tester, tester.getRect(find.byType(Scrollable).first));

List<String> _orderWithin(WidgetTester tester, Rect? view) {
  final found = <String, double>{};
  for (final title in _titles.values) {
    final finder = find.text(title, skipOffstage: false);
    if (finder.evaluate().isEmpty) continue;
    final rect = tester.getRect(finder.first);
    if (view != null &&
        (rect.top < view.top - 1 || rect.bottom > view.bottom + 1)) {
      continue;
    }
    found[title] = rect.top;
  }
  return (found.entries.toList()..sort((a, b) => a.value.compareTo(b.value)))
      .map((e) => e.key)
      .toList();
}

ScrollableState _list(WidgetTester tester) =>
    tester.state<ScrollableState>(find.byType(Scrollable).first);

/// How far [title]'s section has faded in: the entrance wraps every slot in an
/// [Opacity], and the focus effect's own one is still 1 while it plays.
double _fade(WidgetTester tester, String title) => tester
    .widgetList<Opacity>(
      find.ancestor(
        of: find.text(title, skipOffstage: false).first,
        matching: find.byType(Opacity),
      ),
    )
    .map((o) => o.opacity)
    .reduce(math.min);

void main() {
  testWidgets('Bangla checklist localizes points and progress', (tester) async {
    await _pump(tester, selectedLanguage: AppLanguage.bangla);
    expect(find.text('পয়েন্ট : ০/১০'), findsOneWidget);
    expect(find.text('০ %'), findsOneWidget);
    expect(find.text('০/২'), findsNWidgets(7));
  });

  testWidgets('opened without a target, the order is untouched', (
    tester,
  ) async {
    await _pump(tester);
    await _settle(tester);
    expect(_order(tester), _titles.values.toList());
  });

  testWidgets('today\'s Amol summary stays fixed while sections scroll', (
    tester,
  ) async {
    await _pump(tester);
    await _settle(tester);

    final summary = find.byType(AmolSummaryCard);
    final before = tester.getTopLeft(summary);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -250));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(summary), before);
  });

  for (final entry in {
    AmalSection.naflAndMore: 'Nafl & more',
    AmalSection.quiz: 'Quiz',
    AmalSection.quran: 'Quran',
  }.entries) {
    testWidgets('${entry.value} is scrolled to the top, order untouched', (
      tester,
    ) async {
      await _pump(tester, section: entry.key);
      await _settle(tester);

      // Nothing is reordered: the list is scrolled instead.
      expect(_order(tester), _titles.values.toList());
      expect(_list(tester).position.pixels, greaterThan(0));

      final view = tester.getRect(find.byType(Scrollable).first);
      final target = tester.getRect(find.text(entry.value).first);
      expect(target.top - view.top, inInclusiveRange(0, 60));
      expect(_visibleOrder(tester).first, entry.value);
    });
  }

  testWidgets('Quiz finishes below the fixed Amol summary card', (
    tester,
  ) async {
    await _pump(tester, section: AmalSection.quiz);
    await _settle(tester);

    final summary = tester.getRect(find.byType(AmolSummaryCard));
    final quiz = tester.getRect(find.text('Quiz').first);
    expect(quiz.top, greaterThan(summary.bottom));
    expect(quiz.bottom, lessThanOrEqualTo(812));
  });

  testWidgets('the move is animated, not an instant jump', (tester) async {
    await _pump(tester, section: AmalSection.naflAndMore);
    final title = find.text('Nafl & more', skipOffstage: false);
    final ys = <double>[];
    final offsets = <double>[];
    for (var i = 0; i < 24; i++) {
      await tester.pump(const Duration(milliseconds: 40));
      ys.add(tester.getTopLeft(title.first).dy);
      offsets.add(_list(tester).position.pixels);
    }
    await _settle(tester);
    final end = tester.getTopLeft(title.first).dy;
    final endOffset = _list(tester).position.pixels;

    // It travels a real distance, in several steps, and never moves back down.
    expect(ys.first, greaterThan(end + 100));
    final steps = ys.toSet().where((y) => y > end && y < ys.first);
    expect(steps.length, greaterThan(3));
    for (var i = 1; i < ys.length; i++) {
      expect(ys[i], lessThanOrEqualTo(ys[i - 1] + 0.5));
    }

    // And the list itself scrolled there, rather than the card moving alone.
    expect(endOffset, greaterThan(100));
    final scrolled = offsets.toSet().where((o) => o > 0 && o < endOffset);
    expect(scrolled.length, greaterThan(3));
    for (var i = 1; i < offsets.length; i++) {
      expect(offsets[i], greaterThanOrEqualTo(offsets[i - 1] - 0.5));
    }
  });

  testWidgets('the sections enter one after another, from the top down', (
    tester,
  ) async {
    await _pump(tester, section: AmalSection.quiz);
    // Stop on a frame in the middle of the top section's own entrance.
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 40));
      final top = _fade(tester, 'Fardh Prayer');
      if (top > 0 && top < 1) break;
    }

    final top = _fade(tester, 'Fardh Prayer');
    expect(top, inExclusiveRange(0, 1));
    // The last section hasn't begun arriving while the first still is.
    expect(_fade(tester, 'Nafl & more'), lessThan(top));

    await _settle(tester);
    expect(_fade(tester, 'Fardh Prayer'), 1);
    expect(_fade(tester, 'Nafl & more'), 1);
  });

  testWidgets('a target near the bottom still reaches the top', (tester) async {
    await _pump(tester, section: AmalSection.naflAndMore);
    await _settle(tester);

    final view = tester.getRect(find.byType(Scrollable).first);
    final target = tester.getRect(find.text('Nafl & more').first);
    expect(target.top - view.top, inInclusiveRange(0, 60));
    // It can only get there because the list keeps room below it.
    expect(
      _list(tester).position.pixels,
      _list(tester).position.maxScrollExtent,
    );
  });

  testWidgets('a section already first still has an entrance animation', (
    tester,
  ) async {
    await _pump(tester, section: AmalSection.fardhPrayer);
    final title = find.text('Fardh Prayer', skipOffstage: false);

    final positions = <double>[];
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 40));
      positions.add(tester.getTopLeft(title.first).dy);
    }
    await _settle(tester);
    final end = tester.getTopLeft(title.first).dy;

    expect(positions.reduce(math.max), greaterThan(end + 20));
  });

  testWidgets('the selected section is focused once it is at the top', (
    tester,
  ) async {
    await _pump(tester, section: AmalSection.quiz);
    await _settle(tester);
    expect(_visibleOrder(tester).first, 'Quiz');
    // The tracker's own list is never rewritten.
    final bloc = BlocProvider.of<AmolDailyBloc>(
      tester.element(find.byType(Scaffold).first),
    );
    expect(
      bloc.state.dashboard!.pillars.map((p) => p.pillarKey).toList(),
      _titles.keys.toList(),
    );
  });
}
