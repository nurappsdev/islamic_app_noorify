import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tuhfatul_muslim/features/dua/data/models/dua_reading_api_models.dart';
import 'package:tuhfatul_muslim/features/dua/presentation/widgets/dua_dashboard_charts.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

/// The reading dashboard sends `dayOfWeek` in English, so the weekly chart's
/// axis has to write the day out itself.
void main() {
  /// Calls [duaLocalizedWeekdayLabel] under [language].
  Future<String> label(
    WidgetTester tester, {
    required AppLanguage language,
    required String serverLabel,
    required String isoDate,
  }) async {
    var result = '';
    await tester.pumpWidget(
      BlocProvider(
        // Keyed by the language: a second pump in the same test has to build
        // a fresh bloc rather than keep the first one.
        key: ValueKey(language),
        create: (_) => LanguageBloc(initialLanguage: language),
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              result = duaLocalizedWeekdayLabel(
                context,
                serverLabel: serverLabel,
                isoDate: isoDate,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    await tester.pump();
    return result;
  }

  testWidgets('the day the server named is written in the app language', (
    tester,
  ) async {
    expect(
      await label(
        tester,
        language: AppLanguage.bangla,
        serverLabel: 'Mon',
        isoDate: '2026-11-16',
      ),
      'সোম',
    );
    // English is the server's own wording, unchanged.
    expect(
      await label(
        tester,
        language: AppLanguage.english,
        serverLabel: 'Mon',
        isoDate: '2026-11-16',
      ),
      'Mon',
    );
  });

  testWidgets('the label decides which day is meant, not the date beside it', (
    tester,
  ) async {
    // The dashboard counts a day in the reader's own timezone, so its label
    // can name a different day than the date it sends; translating must not
    // move the bar to another day.
    expect(
      await label(
        tester,
        language: AppLanguage.bangla,
        serverLabel: 'Sat',
        isoDate: '2026-11-15', // a Sunday
      ),
      'শনি',
    );
  });

  testWidgets('a day with no usable label falls back to its date', (
    tester,
  ) async {
    expect(
      await label(
        tester,
        language: AppLanguage.bangla,
        serverLabel: '',
        isoDate: '2026-11-16', // a Monday
      ),
      'সোম',
    );
    // Longer spellings and odd casing are still the same day.
    expect(
      await label(
        tester,
        language: AppLanguage.bangla,
        serverLabel: 'friday',
        isoDate: '',
      ),
      'শুক্র',
    );
  });

  testWidgets('a label that is not a weekday keeps its own wording', (
    tester,
  ) async {
    // The monthly axis sends day numbers through here as well.
    expect(
      await label(
        tester,
        language: AppLanguage.bangla,
        serverLabel: '21',
        isoDate: '',
      ),
      '২১',
    );
    expect(
      await label(
        tester,
        language: AppLanguage.english,
        serverLabel: '21',
        isoDate: '',
      ),
      '21',
    );
  });

  testWidgets('a single-day monthly bucket keeps the date it came with', (
    tester,
  ) async {
    final buckets = duaMonthlyBuckets([
      const DuaDashboardActivityDay(
        label: 'Sat',
        date: '2026-11-21',
        minutes: 25,
        duas: 4,
      ),
    ]);
    expect(buckets.single.dayDate, '2026-11-21');
    expect(
      await label(
        tester,
        language: AppLanguage.bangla,
        serverLabel: buckets.single.dayLabel,
        isoDate: buckets.single.dayDate,
      ),
      'শনি',
    );
  });
}
