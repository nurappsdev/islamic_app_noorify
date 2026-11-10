import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/features/hadith/presentation/screens/hadith_intro_screen.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

Future<void> _pump(
  WidgetTester tester,
  Size size, {
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, child) => BlocProvider(
        create: (_) => LanguageBloc(initialLanguage: AppLanguage.english),
        child: MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: const HadithIntroScreen(),
        ),
      ),
    ),
  );
  await tester.pump();
}

Color _colorOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!.color!;

void main() {
  testWidgets('shows the hadith with its source, and the start button', (
    tester,
  ) async {
    await _pump(tester, const Size(375, 812));

    // The hadith text, in quotation marks, exactly as given.
    expect(find.text('“$hadithIntroQuote”'), findsOneWidget);
    expect(find.textContaining('জান্নাতের পথ সুগম করে দেন'), findsOneWidget);
    expect(find.textContaining('ফেরেশতারা ইলম'), findsOneWidget);

    // Its source line.
    expect(hadithIntroQuoteSource, 'সুনানে আবু দাউদ, হাদিস: ৩৬৪১');
    expect(find.text('— $hadithIntroQuoteSource'), findsOneWidget);

    // The rest of the screen is unchanged: the title and the start button.
    expect(find.text("Let's Get Start"), findsOneWidget);
    expect(find.text('Hadith and books'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('still fits a small phone, scrolling instead of overflowing', (
    tester,
  ) async {
    await _pump(tester, const Size(320, 568));

    expect(find.text('— $hadithIntroQuoteSource'), findsOneWidget);
    expect(find.text("Let's Get Start"), findsOneWidget);
    // A RenderFlex overflow would surface as an exception here.
    expect(tester.takeException(), isNull);
  });

  // The screen's gradient is light in both themes, so dark mode must not
  // turn its text into light ink: it goes black instead.
  testWidgets('in dark mode the text is black, not light ink', (tester) async {
    await _pump(tester, const Size(375, 812), brightness: Brightness.dark);

    expect(_colorOf(tester, '“$hadithIntroQuote”'), Colors.black);
    expect(_colorOf(tester, '— $hadithIntroQuoteSource'), Colors.black);
    expect(_colorOf(tester, 'Hadith and books'), Colors.black);
    // The back button keeps its pale badge, so its arrow keeps the near
    // black it is drawn in rather than being flipped to light ink.
    final back = tester.widget<IconButton>(find.byType(IconButton));
    expect(
      back.style!.foregroundColor!.resolve(const <WidgetState>{}),
      const Color(0xFF303629),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('light mode keeps the design colors', (tester) async {
    await _pump(tester, const Size(375, 812));

    expect(_colorOf(tester, '“$hadithIntroQuote”'), const Color(0xFF4C5346));
    expect(
      _colorOf(tester, '— $hadithIntroQuoteSource'),
      const Color(0xFF7D8765),
    );
    expect(_colorOf(tester, 'Hadith and books'), const Color(0xFF7D8765));
  });
}
