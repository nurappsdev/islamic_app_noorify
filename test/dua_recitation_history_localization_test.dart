import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/core/utils/localized_text.dart';
import 'package:tuhfatul_muslim/features/dua/data/models/dua_reading_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/domain/repositories/dua_repository.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/screens/dua_recitation_history_screen.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

/// One dua read today, so the Daily view has a row to write out.
class _Repo extends Fake implements DuaRepository {
  @override
  Future<DuaReadingHistoryPage> getReadingHistory({
    int page = 1,
    int limit = 20,
  }) async => DuaReadingHistoryPage(
    items: [
      DuaReadingHistoryItem(
        duaId: 'dua-1',
        title: const LocalizedText(
          bn: 'সকালের জিকির',
          en: 'Morning remembrance',
        ),
        arabic: 'اللّهم',
        category: const LocalizedText(bn: 'দৈনিক জিকির', en: 'Daily Adhkar'),
        lastReadAt: DateTime(2026, 11, 22, 7, 5),
      ),
    ],
    page: 1,
    totalPage: 1,
  );
}

void main() {
  Future<void> pumpHistory(WidgetTester tester, AppLanguage language) async {
    tester.view.physicalSize = const Size(375 * 3, 812 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        builder: (context, child) => BlocProvider(
          create: (_) => LanguageBloc(initialLanguage: language),
          child: MaterialApp(
            home: DuaRecitationHistoryScreen(repository: _Repo()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the screen is written in Bangla when Bangla is selected', (
    tester,
  ) async {
    final bangla = AppText.forLanguage(AppLanguage.bangla);
    await pumpHistory(tester, AppLanguage.bangla);

    // Heading and the three period tabs.
    expect(find.text(bangla.duaRecitationHistoryTitle), findsOneWidget);
    expect(find.text(bangla.daily), findsOneWidget);
    expect(find.text(bangla.weekly), findsOneWidget);
    expect(find.text(bangla.monthly), findsOneWidget);

    // No English is left behind in the tabs or the heading.
    expect(find.text('Daily'), findsNothing);
    expect(find.text('Recitation history'), findsNothing);

    // Weekday names and day numbers in the week strip are Bangla too.
    expect(find.text('রবি'), findsOneWidget);
    expect(find.textContaining('২'), findsWidgets);
  });

  testWidgets('the month calendar heads its columns from Sunday', (
    tester,
  ) async {
    await pumpHistory(tester, AppLanguage.english);
    await tester.tap(find.text('Monthly'));
    await tester.pumpAndSettle();

    // The grid starts each month on its Sunday column, so Sunday leads the
    // header — it used to read Fri–Thu over a Sunday-first grid.
    final header = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data)
        .toList();
    expect(header.contains('Sun'), isTrue);
    expect(header.indexOf('Sun') < header.indexOf('Mon'), isTrue);
  });

  testWidgets('every string this screen shows has a Bangla translation', (
    tester,
  ) async {
    final bangla = AppText.forLanguage(AppLanguage.bangla);
    for (final text in [
      bangla.duaRecitationHistoryTitle,
      bangla.duaNoRecitationHistory,
      bangla.duaReadDuaLabel,
      bangla.duaOpenFailed,
      bangla.daily,
      bangla.weekly,
      bangla.monthly,
    ]) {
      expect(text, isNotEmpty);
      // Bangla, not an English fallback left in the map.
      expect(RegExp(r'^[\x00-\x7F]+$').hasMatch(text), isFalse, reason: text);
    }
  });
}
