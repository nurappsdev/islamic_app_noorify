import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/profile/presentation/screens/app_language_screen.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> _prefs([Map<String, Object> values = const {}]) {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

/// Reads the saved language the way `main` does, then builds the bloc.
Future<LanguageBloc> _launch([Map<String, Object> saved = const {}]) async {
  final prefs = await _prefs(saved);
  return LanguageBloc(initialLanguage: LanguagePreference.read(prefs));
}

void main() {
  group('default language', () {
    test('is Bangla', () {
      expect(const LanguageState().language, AppLanguage.bangla);
      expect(LanguageBloc().state.language, AppLanguage.bangla);
      expect(LanguagePreference.defaultLanguage, AppLanguage.bangla);
    });

    test('a first launch, with nothing saved, opens in Bangla', () async {
      final bloc = await _launch();
      addTearDown(bloc.close);
      expect(bloc.state.language, AppLanguage.bangla);
    });

    test('an unreadable saved value falls back to Bangla', () async {
      for (final junk in ['', 'english', 'EN', 'fr', 'null']) {
        final bloc = await _launch({LanguagePreference.key: junk});
        addTearDown(bloc.close);
        expect(bloc.state.language, AppLanguage.bangla, reason: junk);
      }
    });
  });

  group('saved language', () {
    test('a saved English opens in English', () async {
      final bloc = await _launch({LanguagePreference.key: 'en'});
      addTearDown(bloc.close);
      expect(bloc.state.language, AppLanguage.english);
    });

    test('a saved Bangla opens in Bangla', () async {
      final bloc = await _launch({LanguagePreference.key: 'bn'});
      addTearDown(bloc.close);
      expect(bloc.state.language, AppLanguage.bangla);
    });

    test('choosing English is saved and survives a restart', () async {
      var bloc = await _launch();
      bloc.add(const UpdateLanguage(AppLanguage.english));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.language, AppLanguage.english);
      expect(
        (await SharedPreferences.getInstance()).getString('app_language'),
        'en',
      );
      await bloc.close();

      // "Restart": a new bloc built from what was saved.
      final prefs = await SharedPreferences.getInstance();
      bloc = LanguageBloc(initialLanguage: LanguagePreference.read(prefs));
      addTearDown(bloc.close);
      expect(bloc.state.language, AppLanguage.english);
    });

    test(
      'choosing Bangla again is saved, so the next launch is Bangla',
      () async {
        final bloc = await _launch({LanguagePreference.key: 'en'});
        addTearDown(bloc.close);

        bloc.add(const UpdateLanguage(AppLanguage.bangla));
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('app_language'), 'bn');
        expect(LanguagePreference.read(prefs), AppLanguage.bangla);
      },
    );

    test('the language still changes if saving fails', () async {
      final bloc = LanguageBloc(persist: (_) => throw StateError('disk full'));
      addTearDown(bloc.close);

      bloc.add(const UpdateLanguage(AppLanguage.english));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.language, AppLanguage.english);
    });
  });

  group('first render', () {
    setUpAll(() async {
      // The language files are loaded before the first frame, as in `main`.
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    testWidgets('is Bangla from the very first frame, even on an English '
        'device, and never shows English', (tester) async {
      await tester.runAsync(AppText.load);
      tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      final bloc = await tester.runAsync(_launch) as LanguageBloc;
      addTearDown(bloc.close);

      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: Builder(
            builder: (context) => Directionality(
              textDirection: TextDirection.ltr,
              child: Text(AppText.of(context).login),
            ),
          ),
        ),
      );

      // No further pump: this is the first frame.
      final bangla = AppText.forLanguage(AppLanguage.bangla).login;
      final english = AppText.forLanguage(AppLanguage.english).login;
      expect(bangla, isNot(english), reason: 'the two languages differ');
      expect(find.text(bangla), findsOneWidget);
      expect(find.text(english), findsNothing);
    });

    testWidgets('a saved English is English from the first frame', (
      tester,
    ) async {
      await tester.runAsync(AppText.load);
      final bloc =
          await tester.runAsync(() => _launch({'app_language': 'en'}))
              as LanguageBloc;
      addTearDown(bloc.close);

      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: Builder(
            builder: (context) => Directionality(
              textDirection: TextDirection.ltr,
              child: Text(AppText.of(context).login),
            ),
          ),
        ),
      );

      expect(
        find.text(AppText.forLanguage(AppLanguage.english).login),
        findsOneWidget,
      );
    });
  });

  group('the language screen', () {
    Future<LanguageBloc> pump(WidgetTester tester) async {
      await tester.runAsync(AppText.load);
      tester.view.physicalSize = const Size(375 * 3, 812 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final bloc = await tester.runAsync(_launch) as LanguageBloc;
      addTearDown(bloc.close);
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, _) => const MaterialApp(home: AppLanguageScreen()),
          ),
        ),
      );
      await tester.pump();
      return bloc;
    }

    testWidgets('opens on Bangla, and switching to English then back to '
        'Bangla is saved each time', (tester) async {
      final bloc = await pump(tester);
      expect(bloc.state.language, AppLanguage.bangla);

      await tester.tap(
        find.text(AppText.forLanguage(AppLanguage.bangla).english),
      );
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(); // the screen rebuilds in English
      expect(bloc.state.language, AppLanguage.english);
      final prefs = await tester.runAsync(SharedPreferences.getInstance);
      expect(prefs!.getString('app_language'), 'en');

      await tester.tap(
        find.text(AppText.forLanguage(AppLanguage.english).bangla),
      );
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      expect(bloc.state.language, AppLanguage.bangla);
      expect(prefs.getString('app_language'), 'bn');
    });
  });
}
