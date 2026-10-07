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
        earnedPoints: 0,
        maxPoints: 2,
        percentage: 0,
        formattedSubtext: '0/2',
        items: [
          AmolItem(
            itemKey: '${key}_item',
            title: '${_titles[key]} item',
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

String _label(String title) =>
    AppText.forLanguage(AppLanguage.english).categoryLabel(title);

/// Lets the arrival, the slide and the focus pause all finish.
Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

/// The section titles, top to bottom, among those laid out.
List<String> _order(WidgetTester tester) {
  final found = <String, double>{};
  for (final title in _titles.values) {
    final finder = find.text(_label(title), skipOffstage: false);
    if (finder.evaluate().isNotEmpty) {
      found[title] = tester.getTopLeft(finder.first).dy;
    }
  }
  return (found.entries.toList()..sort((a, b) => a.value.compareTo(b.value)))
      .map((e) => e.key)
      .toList();
}

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

  for (final entry in {
    AmalSection.naflAndMore: 'Nafl & more',
    AmalSection.quiz: 'Quiz',
    AmalSection.quran: 'Quran',
  }.entries) {
    testWidgets('${entry.value} moves to the top, others keep their order', (
      tester,
    ) async {
      await _pump(tester, section: entry.key);
      await _settle(tester);
      final expected = [
        entry.value,
        ..._titles.values.where((t) => t != entry.value),
      ];
      expect(_order(tester), expected);
    });
  }

  testWidgets('the move is animated, not an instant jump', (tester) async {
    await _pump(tester, section: AmalSection.naflAndMore);
    final title = find.text(_label('Nafl & more'), skipOffstage: false);
    final ys = <double>[];
    for (var i = 0; i < 24; i++) {
      await tester.pump(const Duration(milliseconds: 40));
      ys.add(tester.getTopLeft(title.first).dy);
    }
    await _settle(tester);
    final end = tester.getTopLeft(title.first).dy;

    // It travels a real distance, in several steps, and never moves back down.
    expect(ys.first, greaterThan(end + 100));
    final steps = ys.toSet().where((y) => y > end && y < ys.first);
    expect(steps.length, greaterThan(3));
    for (var i = 1; i < ys.length; i++) {
      expect(ys[i], lessThanOrEqualTo(ys[i - 1] + 0.5));
    }
  });

  testWidgets('the selected section is focused once it is at the top', (
    tester,
  ) async {
    await _pump(tester, section: AmalSection.quiz);
    await _settle(tester);
    expect(_order(tester).first, 'Quiz');
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
