import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:tuhfatul_muslim/core/storage/hive_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/auth/presentation/screens/signin_screen.dart';
import 'package:tuhfatul_muslim/features/auth/presentation/screens/signup_screen.dart';
import 'package:tuhfatul_muslim/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:tuhfatul_muslim/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:tuhfatul_muslim/features/profile/presentation/screens/change_password_screen.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

/// Every piece of user-visible text on screen: text, hints and tooltips.
List<String> visible(WidgetTester t) => [
  for (final x in t.widgetList<Text>(find.byType(Text)))
    if (x.data != null) x.data!,
  for (final f in t.widgetList<TextField>(find.byType(TextField)))
    if (f.decoration?.hintText != null) f.decoration!.hintText!,
  for (final b in t.widgetList<IconButton>(find.byType(IconButton)))
    if (b.tooltip != null) b.tooltip!,
];

Future<void> show(WidgetTester tester, Widget screen) async {
  await tester.runAsync(AppText.load);
  tester.view.physicalSize = const Size(375 * 2, 812 * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final bloc = LanguageBloc(
    initialLanguage: AppLanguage.bangla,
    persist: (_) async {},
  );
  addTearDown(bloc.close);
  await tester.pumpWidget(
    BlocProvider.value(
      value: bloc,
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(home: screen),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('probe_hive');
    Hive.init(dir.path);
    for (final name in [
      HiveService.authBox,
      HiveService.alarmsBox,
      HiveService.prayerAlarmsBox,
      HiveService.asmaHusnaBox,
    ]) {
      await Hive.openBox<dynamic>(name);
    }
  });
  final screens = <String, Widget Function()>{
    'SignIn': () => const SignInScreen(),
    'SignUp': () => const SignupScreen(),
    'Forgot': () => ForgotPasswordScreen(),
    'Reset': () => const ResetPasswordScreen(),
    'ChangePassword': () => const ChangePasswordScreen(),
  };
  screens.forEach((name, build) {
    testWidgets('$name shows no English text or ASCII digits in Bangla', (
      tester,
    ) async {
      await show(tester, build());
      final bad = [
        for (final t in visible(tester))
          if (RegExp('[A-Za-z]{2,}|[0-9]').hasMatch(t)) t,
      ];
      // The phone country's dial code (`+880`) is part of the number that is
      // sent, so it is the one thing left as it is.
      final leftover = bad.where((t) => !RegExp(r'^\S+ \+\d+$').hasMatch(t));
      expect(
        leftover,
        isEmpty,
        reason: '$name shows English or ASCII digits in Bangla: $leftover',
      );
    });
  });
}
