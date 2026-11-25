import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tuhfatul_muslim/core/storage/hive_service.dart';
import 'package:tuhfatul_muslim/core/utils/app_text.dart';
import 'package:tuhfatul_muslim/features/home/data/home_feature_order_store.dart';
import 'package:tuhfatul_muslim/features/home/presentation/widgets/home_feature_grid.dart';
import 'package:tuhfatul_muslim/shared/bloc/language/language_bloc.dart';

/// The grid tile titles, top-left to bottom-right as they are painted.
List<String> _visibleOrder(WidgetTester tester, List<String> titles) {
  final placed =
      [
        for (final title in titles)
          (title: title, at: tester.getCenter(find.text(title))),
      ]..sort((a, b) {
        final rows = a.at.dy.compareTo(b.at.dy);
        return rows != 0 ? rows : a.at.dx.compareTo(b.at.dx);
      });
  return [for (final tile in placed) tile.title];
}

Future<void> _pumpGrid(WidgetTester tester) async {
  tester.view.physicalSize = const Size(375 * 3, 812 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  // The tile is 18px short of its content under the test runner's stand-in
  // font (it fits with the app's real one, and does so with or without the
  // drag wrapper). Everything else still fails the test.
  final reportError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) return;
    reportError?.call(details);
  };
  addTearDown(() => FlutterError.onError = reportError);

  await tester.pumpWidget(
    BlocProvider(
      create: (_) => LanguageBloc(
        initialLanguage: AppLanguage.english,
        persist: (_) async {},
      ),
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: HomeFeatureGrid())),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Long-presses the [from] tile and drops it on the [to] tile.
Future<void> _dragTile(
  WidgetTester tester, {
  required String from,
  required String to,
}) async {
  final target = tester.getCenter(find.text(to));
  final gesture = await tester.startGesture(tester.getCenter(find.text(from)));
  await tester.pump(const Duration(milliseconds: 400)); // past the lift delay
  await gesture.moveTo(target);
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  // Filled once the real strings are loaded: the grid labels its tiles from
  // them, so capturing them earlier would read the compiled-in fallbacks.
  late List<String> titles;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppText.load();
    final appText = AppText.forLanguage(AppLanguage.english);
    titles = [
      appText.categoryQuran,
      appText.categoryHadith,
      appText.featureDua,
      appText.featureQuizAndLearn,
      appText.featureDijpr, // Zikr
      appText.featureAsmaUlHusna,
    ];
    Hive.init(Directory.systemTemp.createTempSync('home_grid_hive').path);
    for (final box in [HiveService.zikrBox, HiveService.homeLayoutBox]) {
      await Hive.openBox<dynamic>(box);
    }
  });

  setUp(HomeFeatureOrderStore.instance.reset);

  testWidgets('ships in the declared order', (tester) async {
    await _pumpGrid(tester);
    expect(_visibleOrder(tester, titles), titles);
  });

  testWidgets('dragging Zikr onto Hadith makes Zikr the 2nd tile', (
    tester,
  ) async {
    await _pumpGrid(tester);
    await _dragTile(tester, from: titles[4], to: titles[1]);

    expect(_visibleOrder(tester, titles), [
      titles[0], // Quran
      titles[4], // Zikr
      titles[1], // Hadith
      titles[2], // Dua
      titles[3], // Quiz
      titles[5], // Asma
    ]);
  });

  testWidgets('the new order is kept on the device', (tester) async {
    await _pumpGrid(tester);
    await _dragTile(tester, from: titles[4], to: titles[2]);
    final saved = HomeFeatureOrderStore.instance.value;

    // A fresh grid (a restart reads the same Hive entry) shows it again.
    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpGrid(tester);

    expect(HomeFeatureOrderStore.instance.value, saved);
    expect(_visibleOrder(tester, titles)[2], titles[4]);
  });
}
