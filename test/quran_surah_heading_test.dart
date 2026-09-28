import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/features/quran/domain/surah_summary.dart';
import 'package:islami_app_noorify/features/quran/presentation/widgets/quran_surah_heading.dart';
import 'package:islami_app_noorify/features/quran/presentation/widgets/quran_page_viewport.dart';

const surah = SurahSummary(
  number: 2,
  name: 'Al-Baqarah',
  nameArabic: 'البقرة',
  translation: '',
  revelationPlace: 'medinan',
  totalAyah: 286,
);

void main() {
  testWidgets('banner and ayahs scroll together without overlap', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final width in [320.0, 430.0]) {
      for (final scale in [1.0, 2.0]) {
        tester.view.physicalSize = Size(width, 850);
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 850),
                  padding: const EdgeInsets.only(top: 44),
                  textScaler: TextScaler.linear(scale),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(height: 72, child: Text('Controls')),
                      Expanded(
                        child: QuranPageViewport(
                          pageNumber: 1,
                          showHeader: false,
                          footer: const SizedBox(),
                          header: const QuranSurahHeading(
                            surah: surah,
                            showBismillah: true,
                          ),
                          child: Column(
                            children: [
                              const Text('First ayah'),
                              const SizedBox(height: 1500),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        final header = find.byType(QuranSurahHeading);
        final pattern = find.byKey(const ValueKey('surah-background-pattern'));
        final title = find.text('Al-Baqarah');
        final metadata = find.text('MEDINAN • 286 AYAT');
        final bismillah = find.byWidgetPredicate(
          (w) => w is Image && w.semanticLabel == 'Bismillah',
        );
        final ayah = find.text('First ayah');
        final scroll = tester
            .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
            .controller!;
        scroll.jumpTo(0);
        await tester.pump();
        expect(tester.getRect(pattern).top, tester.getRect(header).top);
        expect(tester.getRect(pattern).left, 0);
        expect(tester.widget<Image>(pattern).fit, BoxFit.cover);
        expect(find.text('Controls').hitTestable(), findsOneWidget);
        expect(tester.getRect(pattern).width, width);
        expect(tester.getRect(find.text('Controls')).top, 44);
        expect(
          tester.getRect(title).top - tester.getRect(header).top,
          closeTo(width * .57, .01),
        );
        expect(
          tester.getRect(metadata).top - tester.getRect(title).bottom,
          closeTo(8, .01),
        );
        expect(
          tester.getRect(bismillah).top - tester.getRect(metadata).bottom,
          closeTo(16, .01),
        );
        expect(
          tester.getRect(ayah).top,
          greaterThanOrEqualTo(tester.getRect(pattern).bottom + 24),
        );
        expect(
          tester.getRect(ayah).top,
          greaterThanOrEqualTo(tester.getRect(bismillah).bottom + 24),
        );
        final before = [
          pattern,
          title,
          metadata,
          bismillah,
          ayah,
        ].map((f) => tester.getTopLeft(f).dy).toList();
        scroll.jumpTo(200);
        await tester.pump();
        final after = [
          pattern,
          title,
          metadata,
          bismillah,
          ayah,
        ].map((f) => tester.getTopLeft(f).dy).toList();
        for (var i = 0; i < before.length; i++) {
          expect(before[i] - after[i], closeTo(200, .01));
        }
        expect(tester.getRect(pattern).top, tester.getRect(header).top);
        expect(
          tester.getRect(ayah).top,
          greaterThanOrEqualTo(tester.getRect(pattern).bottom + 24),
        );
        final controlsTop = tester.getRect(find.text('Controls')).top;
        await tester.drag(
          find.byType(QuranPageViewport),
          const Offset(0, -180),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getRect(ayah).top,
          greaterThanOrEqualTo(tester.getRect(pattern).bottom + 24),
        );
        expect(tester.getRect(find.text('Controls')).top, controlsTop);
        expect(tester.takeException(), isNull);
      }
    }
  });
}
