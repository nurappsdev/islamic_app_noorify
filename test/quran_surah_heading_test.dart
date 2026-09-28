import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/features/quran/domain/surah_summary.dart';
import 'package:islami_app_noorify/features/quran/presentation/widgets/quran_surah_heading.dart';

void main() {
  testWidgets(
    'Surah heading uses live metadata and keeps text inside the arch',
    (tester) async {
      for (final width in [272.0, 354.0]) {
        for (final scale in [1.0, 2.0]) {
          const surah = SurahSummary(
            number: 3,
            name: 'Aal Imran',
            nameArabic: 'آل عمران',
            translation: '',
            revelationPlace: 'medinan',
            totalAyah: 200,
          );
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: MediaQuery(
                    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                    child: SizedBox(
                      width: width,
                      child: const QuranSurahHeading(
                        surah: surah,
                        showBismillah: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          expect(find.text('Aal Imran'), findsOneWidget);
          expect(find.text('MEDINAN • 200 AYAT'), findsOneWidget);
          final title = tester.getRect(find.text('Aal Imran'));
          final metadata = tester.getRect(find.text('MEDINAN • 200 AYAT'));
          expect(title.top, greaterThanOrEqualTo(width * .61));
          expect(title.width, lessThanOrEqualTo(width * .52));
          expect(metadata.top, greaterThan(title.bottom));
          final ornament = tester.widgetList<Image>(find.byType(Image)).first;
          expect(ornament.fit, BoxFit.contain);
          expect(ornament.height, closeTo(width * 380 / 402, .01));
          expect(tester.takeException(), isNull);
        }
      }
    },
  );
}
