import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tuhfatul_muslim/features/home/presentation/widgets/amal_tracker_card_content.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

void main() {
  testWidgets('feature-card progress header reflects each completion state', (
    tester,
  ) async {
    final language = LanguageBloc(
      initialLanguage: AppLanguage.english,
      persist: (_) async {},
    );
    addTearDown(language.close);

    Future<double> pumpHeader(num percentage) async {
      await tester.pumpWidget(
        BlocProvider.value(
          value: language,
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, _) => MaterialApp(
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 340,
                    child: ProgressHeaderWidget(
                      percentage: percentage,
                      onTap: () {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester
          .getSize(find.byKey(const ValueKey('feature-card-progress-fill')))
          .width;
    }

    final initialFill = await pumpHeader(0);
    expect(find.text('In Progress'), findsOneWidget);
    expect(initialFill, greaterThan(0));

    await pumpHeader(1);
    expect(find.text('In Progress • 99% Remaining'), findsOneWidget);

    final partialFill = await pumpHeader(60);
    expect(find.text('In Progress • 40% Remaining'), findsOneWidget);
    expect(partialFill, greaterThan(initialFill));

    final completeFill = await pumpHeader(100);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.textContaining('In Progress'), findsNothing);
    expect(completeFill, greaterThan(partialFill));

    final fill = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('feature-card-progress-fill')),
    );
    expect((fill.decoration! as BoxDecoration).color, const Color(0xFFA1AD59));
  });
}
