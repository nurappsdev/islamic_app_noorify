import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/features/hadith/presentation/screens/hadith_intro_screen.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';

Future<void> _pump(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, child) => BlocProvider(
        create: (_) => LanguageBloc(),
        child: const MaterialApp(home: HadithIntroScreen()),
      ),
    ),
  );
  await tester.pump();
}

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
}
