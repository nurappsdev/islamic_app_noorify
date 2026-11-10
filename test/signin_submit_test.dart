import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuhfatul_muslim/core/storage/hive_service.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/auth/presentation/screens/signin_screen.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

void main() {
  setUpAll(() async {
    await AppText.load();
    final dir = Directory.systemTemp.createTempSync('signin_submit');
    Hive.init(dir.path);
    // Signing in reads the session box.
    await Hive.openBox<dynamic>(HiveService.authBox);
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  // The password field's `onFieldSubmitted` used to read a getter that
  // watches LoginBloc, which provider only allows while building: pressing
  // the keyboard's Done key threw "Tried to listen to a value exposed with
  // provider, from outside of the widget tree".
  testWidgets(
    'submitting the password field from the keyboard does not throw',
    (tester) async {
      tester.view.physicalSize = const Size(375 * 3, 812 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final languageBloc = LanguageBloc();
      addTearDown(languageBloc.close);
      await tester.pumpWidget(
        BlocProvider.value(
          value: languageBloc,
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, _) => const MaterialApp(home: SignInScreen()),
          ),
        ),
      );
      await tester.pump();

      final password = find.byType(TextFormField).last;
      await tester.enterText(password, 'secret123');
      await tester.pump();

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(tester.takeException(), isNull);
    },
  );
}
