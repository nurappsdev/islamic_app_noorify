import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:islami_app_noorify/core/bloc/app_preferences/app_preferences_cubit.dart';
import 'package:islami_app_noorify/core/utils/app_text.dart';
import 'package:islami_app_noorify/main.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_cubit.dart';

void main() {
  testWidgets('shows sign in screen', (WidgetTester tester) async {
    await AppText.load();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => LanguageCubit()),
          BlocProvider(create: (_) => AppPreferencesCubit()),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pump();

    expect(
      find.text(AppText.forLanguage(AppLanguage.english).login),
      findsOneWidget,
    );
  });
}
