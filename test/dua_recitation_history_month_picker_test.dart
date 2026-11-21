import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tuhfatul_muslim/features/dua/data/models/dua_reading_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/domain/repositories/dua_repository.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/screens/dua_recitation_history_screen.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

/// No entries: the summary cards are not what is under test here, and the
/// test font is wide enough to overflow their fixed-height row on its own.
class _Repo extends Fake implements DuaRepository {
  @override
  Future<DuaReadingHistoryPage> getReadingHistory({
    int page = 1,
    int limit = 20,
  }) async => const DuaReadingHistoryPage(items: [], page: 1, totalPage: 1);
}

/// What `MaterialLocalizations.formatMonthYear` prints for [month] in the
/// default English locale, so the test can name a row before tapping it.
String _monthYear(DateTime month) =>
    '${const ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][month.month - 1]} ${month.year}';

void main() {
  final thisMonth = DateTime(DateTime.now().year, DateTime.now().month);
  final lastMonth = DateTime(thisMonth.year, thisMonth.month - 1);
  final nextMonth = DateTime(thisMonth.year, thisMonth.month + 1);

  Future<void> openMonthly(WidgetTester tester) async {
    tester.view.physicalSize = const Size(375 * 3, 812 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        builder: (context, child) => BlocProvider(
          create: (_) => LanguageBloc(initialLanguage: AppLanguage.english),
          child: MaterialApp(
            home: DuaRecitationHistoryScreen(repository: _Repo()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Monthly'));
    await tester.pumpAndSettle();
  }

  testWidgets('the wheel opens on the month name', (tester) async {
    await openMonthly(tester);

    // Closed: only the selector's own heading carries the month.
    expect(find.text(_monthYear(thisMonth)), findsOneWidget);
    expect(find.text(_monthYear(lastMonth)), findsNothing);

    await tester.tap(find.text(_monthYear(thisMonth)));
    await tester.pumpAndSettle();

    // Open: five rows around the current month, which now appears twice.
    expect(find.text(_monthYear(thisMonth)), findsNWidgets(2));
    expect(find.text(_monthYear(lastMonth)), findsOneWidget);
    expect(find.text(_monthYear(nextMonth)), findsOneWidget);
  });

  testWidgets('picking a month from the wheel changes the month', (
    tester,
  ) async {
    await openMonthly(tester);
    await tester.tap(find.text(_monthYear(thisMonth)));
    await tester.pumpAndSettle();

    await tester.tap(find.text(_monthYear(lastMonth)));
    await tester.pumpAndSettle();

    // The heading followed the choice, and the wheel closed behind it.
    expect(find.text(_monthYear(lastMonth)), findsOneWidget);
    expect(find.text(_monthYear(thisMonth)), findsNothing);
  });

  testWidgets('the arrows keep stepping a month at a time', (tester) async {
    await openMonthly(tester);

    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();
    expect(find.text(_monthYear(lastMonth)), findsOneWidget);

    // One frame between taps: each step reads the month the last one left.
    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();
    expect(find.text(_monthYear(nextMonth)), findsOneWidget);
  });

  testWidgets('a wheel row that is tapped on its year picks that month too', (
    tester,
  ) async {
    await openMonthly(tester);
    await tester.tap(find.text(_monthYear(thisMonth)));
    await tester.pumpAndSettle();

    // The year sits in the row's right half; tapping it is the same choice.
    final row = find.ancestor(
      of: find.text(_monthYear(nextMonth)),
      matching: find.byType(InkWell),
    );
    await tester.tapAt(
      tester.getCenter(row.first) +
          Offset(tester.getSize(row.first).width / 4, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text(_monthYear(nextMonth)), findsOneWidget);
    expect(find.text(_monthYear(thisMonth)), findsNothing);
  });
}
