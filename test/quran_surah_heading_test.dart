import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/features/quran/domain/surah_summary.dart';
import 'package:islami_app_noorify/features/quran/presentation/widgets/quran_surah_heading.dart';

void main() {
  testWidgets('pattern fills screen edges behind safe-area controls', (
    tester,
  ) async {
    for (final width in [320.0, 430.0]) {
      tester.view.physicalSize = Size(width, 850);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 850),
                padding: const EdgeInsets.only(top: 44),
              ),
              child: const QuranSurahBackdrop(
                visible: true,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 48,
                        width: double.infinity,
                        child: Text('Controls'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final pattern = find.byKey(const ValueKey('surah-background-pattern'));
      expect(tester.getRect(pattern).left, 0);
      expect(tester.getRect(pattern).top, 0);
      expect(tester.getRect(pattern).width, width);
      expect(tester.widget<Image>(pattern).fit, BoxFit.cover);
      expect(tester.getRect(find.text('Controls')).left, 16);
      expect(tester.getRect(find.text('Controls')).top, 44);
      expect(find.text('Controls').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
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
          expect(tester.takeException(), isNull);
        }
      }
    },
  );
}
